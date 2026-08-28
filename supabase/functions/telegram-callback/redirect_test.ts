import { assertEquals, assertStringIncludes } from "jsr:@std/assert@1";
import { telegramAppRedirect } from "./redirect.ts";

const appRedirect = "suikai://auth/telegram";

Deno.test("success redirects with code and state preserved", () => {
  const response = telegramAppRedirect(
    new URL(
      "https://api.suikai.shop/functions/v1/telegram-callback?code=abc&state=state-value",
    ),
    appRedirect,
  );
  assertEquals(response.status, 302);
  const target = new URL(response.headers.get("location")!);
  assertEquals(target.protocol, "suikai:");
  assertEquals(target.host, "auth");
  assertEquals(target.pathname, "/telegram");
  assertEquals(target.searchParams.get("code"), "abc");
  assertEquals(target.searchParams.get("state"), "state-value");
});

Deno.test("error parameters are encoded and arbitrary tokens are excluded", () => {
  const response = telegramAppRedirect(
    new URL(
      "https://api.suikai.shop/functions/v1/telegram-callback?error=access_denied&error_description=User%20cancelled%20%26%20closed&access_token=must-not-forward",
    ),
    appRedirect,
  );
  const location = response.headers.get("location")!;
  const target = new URL(location);
  assertEquals(target.searchParams.get("error"), "access_denied");
  assertEquals(
    target.searchParams.get("error_description"),
    "User cancelled & closed",
  );
  assertEquals(target.searchParams.has("access_token"), false);
  assertStringIncludes(location, "error_description=User+cancelled+%26+closed");
});

Deno.test("missing or invalid redirect fails without leaking callback values", async () => {
  const callback = new URL(
    "https://api.suikai.shop/functions/v1/telegram-callback?code=private-code",
  );
  for (const value of [undefined, "not a url"]) {
    const response = telegramAppRedirect(callback, value);
    assertEquals(response.status, 500);
    assertEquals((await response.text()).includes("private-code"), false);
  }
});
