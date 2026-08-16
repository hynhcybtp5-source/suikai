import "@supabase/functions-js/edge-runtime.d.ts";

Deno.serve((req) => {
  const url = new URL(req.url);

  const code = url.searchParams.get("code");
  const state = url.searchParams.get("state");
  const error = url.searchParams.get("error");
  const errorDescription = url.searchParams.get("error_description");

  const redirectUrl = state?.startsWith("mobile.")
    ? "suikai://login-callback"
    : Deno.env.get("TELEGRAM_APP_REDIRECT_URL") || "http://localhost:3000/";
  let target: URL;

  try {
    target = new URL(redirectUrl);
  } catch {
    return new Response("Invalid TELEGRAM_APP_REDIRECT_URL", { status: 500 });
  }

  if (code) target.searchParams.set("code", code);
  if (state) target.searchParams.set("state", state);
  if (error) target.searchParams.set("error", error);

  if (errorDescription) {
    target.searchParams.set(
      "error_description",
      errorDescription,
    );
  }

  return Response.redirect(target.toString(), 302);
});
