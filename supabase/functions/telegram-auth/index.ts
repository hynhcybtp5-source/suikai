import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";

type TelegramTokenResponse = {
  access_token?: string;
  token_type?: string;
  expires_in?: number;
  id_token?: string;
  error?: string;
  error_description?: string;
};

type JwtHeader = {
  alg?: string;
  kid?: string;
  typ?: string;
};

type TelegramClaims = {
  iss?: string;
  aud?: string | number | string[];
  sub?: string;
  exp?: number;
  iat?: number;
  id?: number | string;
  name?: string;
  preferred_username?: string;
  picture?: string;
  phone_number?: string;
};

type Jwk = {
  kty?: string;
  kid?: string;
  alg?: string;
  n?: string;
  e?: string;
};

type Jwks = {
  keys?: Jwk[];
};

function corsHeaders() {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
  };
}

function jsonResponse(body: unknown, status = 200) {
  return Response.json(body, {
    status,
    headers: corsHeaders(),
  });
}

function base64UrlToBytes(value: string): Uint8Array {
  const padded = value
    .replace(/-/g, "+")
    .replace(/_/g, "/")
    .padEnd(Math.ceil(value.length / 4) * 4, "=");

  const binary = atob(padded);
  const bytes = new Uint8Array(binary.length);

  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }

  return bytes;
}

function decodeJwtPart<T>(value: string): T {
  const bytes = base64UrlToBytes(value);
  return JSON.parse(new TextDecoder().decode(bytes)) as T;
}

async function verifyRs256(
  jwk: Jwk,
  signingInput: Uint8Array,
  signature: Uint8Array,
): Promise<boolean> {
  if (jwk.kty !== "RSA" || !jwk.n || !jwk.e) {
    return false;
  }

  try {
    const cryptoKey = await crypto.subtle.importKey(
      "jwk",
      jwk as JsonWebKey,
      {
        name: "RSASSA-PKCS1-v1_5",
        hash: "SHA-256",
      },
      false,
      ["verify"],
    );

    return await crypto.subtle.verify(
      "RSASSA-PKCS1-v1_5",
      cryptoKey,
      signature,
      signingInput,
    );
  } catch {
    return false;
  }
}

async function verifyTelegramIdToken(
  idToken: string,
  expectedClientId: string,
): Promise<TelegramClaims> {
  const parts = idToken.split(".");

  if (parts.length !== 3) {
    throw new Error("Invalid Telegram ID token");
  }

  const header = decodeJwtPart<JwtHeader>(parts[0]);
  const claims = decodeJwtPart<TelegramClaims>(parts[1]);

  if (header.alg !== "RS256" || !header.kid) {
    throw new Error("Telegram ID token must use RS256 and include a kid");
  }

  const jwksResponse = await fetch(
    "https://oauth.telegram.org/.well-known/jwks.json",
    {
      headers: { Accept: "application/json" },
    },
  );

  if (!jwksResponse.ok) {
    throw new Error(`Unable to fetch Telegram JWKS: ${jwksResponse.status}`);
  }

  const jwks = (await jwksResponse.json()) as Jwks;
  const key = jwks.keys?.find((candidate) =>
    candidate.kid === header.kid &&
    candidate.kty === "RSA" &&
    candidate.alg === "RS256"
  );

  if (!key) {
    throw new Error(`Telegram RS256 signing key not found for kid=${header.kid}`);
  }

  const signingInput = new TextEncoder().encode(`${parts[0]}.${parts[1]}`);
  const signature = base64UrlToBytes(parts[2]);

  const verified = await verifyRs256(key, signingInput, signature);

  if (!verified) {
    throw new Error("Telegram ID token signature is invalid");
  }

  if (claims.iss !== "https://oauth.telegram.org") {
    throw new Error("Invalid Telegram issuer");
  }

  const audiences = Array.isArray(claims.aud)
    ? claims.aud.map(String)
    : [String(claims.aud ?? "")];

  if (!audiences.includes(expectedClientId)) {
    throw new Error("Invalid Telegram audience");
  }

  const now = Math.floor(Date.now() / 1000);

  if (!claims.exp || claims.exp <= now) {
    throw new Error("Telegram ID token expired");
  }

  // Reject tokens issued unreasonably far in the future.
  if (claims.iat && claims.iat > now + 120) {
    throw new Error("Telegram ID token issued in the future");
  }

  if (!claims.sub) {
    throw new Error("Telegram ID token has no sub");
  }

  return claims;
}

function basicAuth(clientId: string, clientSecret: string): string {
  const raw = `${clientId}:${clientSecret}`;

  // Client ID / secret are ASCII-safe in normal Telegram BotFather output.
  // btoa is sufficient here and avoids exposing the secret in request body/logs.
  return `Basic ${btoa(raw)}`;
}

export default {
  fetch: withSupabase(
    { auth: "none" },
    async (req, ctx) => {
      if (req.method === "OPTIONS") {
        return new Response("ok", { headers: corsHeaders() });
      }

      if (req.method !== "POST") {
        return jsonResponse({ error: "Method not allowed" }, 405);
      }

      try {
        const clientId = Deno.env.get("TELEGRAM_CLIENT_ID");
        const clientSecret = Deno.env.get("TELEGRAM_CLIENT_SECRET");

        if (!clientId || !clientSecret) {
          throw new Error("Telegram server secrets are not configured");
        }

        const body = await req.json();

        const code = String(body.code ?? "").trim();
        const codeVerifier = String(body.code_verifier ?? "").trim();
        const redirectUri = String(body.redirect_uri ?? "").trim();

        if (!code || !codeVerifier || !redirectUri) {
          return jsonResponse(
            {
              error: "invalid_request",
              message: "code, code_verifier and redirect_uri are required",
            },
            400,
          );
        }

        const tokenBody = new URLSearchParams({
          grant_type: "authorization_code",
          code,
          redirect_uri: redirectUri,
          client_id: clientId,
          code_verifier: codeVerifier,
        });

        const tokenResponse = await fetch(
          "https://oauth.telegram.org/token",
          {
            method: "POST",
            headers: {
              "Content-Type": "application/x-www-form-urlencoded",
              Accept: "application/json",
              Authorization: basicAuth(clientId, clientSecret),
            },
            body: tokenBody,
          },
        );

        let tokenData: TelegramTokenResponse;

        try {
          tokenData =
            (await tokenResponse.json()) as TelegramTokenResponse;
        } catch {
          throw new Error(
            `Telegram token endpoint returned invalid JSON (${tokenResponse.status})`,
          );
        }

        if (!tokenResponse.ok || !tokenData.id_token) {
          console.error("Telegram token exchange failed", {
            status: tokenResponse.status,
            error: tokenData.error,
            description: tokenData.error_description,
          });

          return jsonResponse(
            {
              error: "telegram_token_exchange_failed",
              message:
                tokenData.error_description ??
                tokenData.error ??
                "Telegram did not return an ID token",
            },
            401,
          );
        }

        const claims = await verifyTelegramIdToken(
          tokenData.id_token,
          clientId,
        );

        const telegramId = String(claims.sub);
        const syntheticEmail =
          `telegram_${telegramId}@auth.suikai.invalid`;

        const metadata = {
          provider: "telegram",
          telegram_id: telegramId,
          sub: telegramId,
          name: claims.name ?? null,
          preferred_username: claims.preferred_username ?? null,
          avatar_url: claims.picture ?? null,
          picture: claims.picture ?? null,
          phone_number: claims.phone_number ?? null,
          iss: claims.iss,
        };

        const { data: linkData, error: linkError } =
          await ctx.supabaseAdmin.auth.admin.generateLink({
            type: "magiclink",
            // This deterministic address is internal only. generateLink
            // creates a new Auth user when necessary and reuses it otherwise.
            // Do not query public.profiles here: production intentionally does
            // not require the undeployed telegram_id migration for login.
            email: syntheticEmail,
            options: {
              data: metadata,
            },
          });

        if (linkError) {
          throw linkError;
        }

        const tokenHash = linkData?.properties?.hashed_token;

        if (!tokenHash) {
          throw new Error(
            "Supabase did not return a magic-link token hash",
          );
        }

        const authUserId = linkData?.user?.id ?? null;

        return jsonResponse({
          ok: true,
          token_hash: tokenHash,
          // Client must immediately exchange token_hash with Supabase Auth.
          // Do not persist or log this value.
          auth_email: syntheticEmail,
          auth_user_id: authUserId,
          telegram: {
            id: telegramId,
            name: claims.name ?? null,
            username: claims.preferred_username ?? null,
            picture: claims.picture ?? null,
          },
        });
      } catch (error) {
        console.error(
          "telegram-auth failed",
          error instanceof Error
            ? {
                name: error.name,
                message: error.message,
                stack: error.stack,
              }
            : String(error),
        );

        return jsonResponse(
          {
            error: "telegram_auth_failed",
            message:
              error instanceof Error
                ? error.message
                : String(error),
          },
          500,
        );
      }
    },
  ),
};
