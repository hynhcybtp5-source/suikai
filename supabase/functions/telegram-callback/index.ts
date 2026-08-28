import "@supabase/functions-js/edge-runtime.d.ts";
import { telegramAppRedirect } from "./redirect.ts";

Deno.serve((req) => {
  return telegramAppRedirect(
    new URL(req.url),
    Deno.env.get("TELEGRAM_APP_REDIRECT_URL"),
  );
});
