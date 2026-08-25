import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";

type StorageObject = {
  bucket: string;
  object_path: string;
};

function corsHeaders() {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
  };
}

function response(body: Record<string, unknown>, status = 200) {
  return Response.json(body, { status, headers: corsHeaders() });
}

function chunks<T>(values: T[], size = 100): T[][] {
  const result: T[][] = [];
  for (let index = 0; index < values.length; index += size) {
    result.push(values.slice(index, index + size));
  }
  return result;
}

/**
 * Deletes only data owned by the authenticated caller.  The caller's id is
 * always obtained from the verified JWT; this function intentionally accepts
 * no user-id field in its request body.
 */
export default {
  fetch: withSupabase(
    { auth: "user" },
    async (req, ctx) => {
      if (req.method === "OPTIONS") {
        return new Response("ok", { headers: corsHeaders() });
      }
      if (req.method !== "POST") {
        return response({ error: "method_not_allowed" }, 405);
      }

      const { data: authData, error: authError } = await ctx.supabase.auth
        .getUser();
      const user = authData.user;
      if (authError || !user) {
        return response({ error: "authentication_required" }, 401);
      }

      const userId = user.id;
      const admin = ctx.supabaseAdmin;

      try {
        // Admin deletion needs a separate, audited support procedure rather
        // than self-service, even when more than one admin exists.
        const { data: adminRole, error: adminRoleError } = await admin
          .from("admin_roles")
          .select("user_id")
          .eq("user_id", userId)
          .maybeSingle();
        if (adminRoleError) throw adminRoleError;
        if (adminRole) {
          return response({ error: "admin_account_requires_support" }, 409);
        }

        const [{ data: stores, error: storesError }, { data: listings, error: listingsError }] =
          await Promise.all([
            admin.from("stores").select("id").eq("owner_id", userId),
            admin.from("listings").select("id").eq("owner_id", userId),
          ]);
        if (storesError) throw storesError;
        if (listingsError) throw listingsError;

        const storeIds = (stores ?? []).map((row: { id: string }) =>
          String(row.id)
        );
        const listingIds = (listings ?? []).map((row: { id: string }) =>
          String(row.id)
        );

        // Fetch every media object before deleting rows.  Only assets whose
        // owner_id is this account are touched, so another user's object can
        // never be removed through this endpoint.
        const assets: StorageObject[] = [];
        for (let from = 0; ; from += 1000) {
          const { data, error } = await admin
            .from("media_assets")
            .select("bucket,object_path")
            .eq("owner_id", userId)
            .range(from, from + 999);
          if (error) throw error;
          assets.push(...((data ?? []) as StorageObject[]));
          if (!data || data.length < 1000) break;
        }

        // Storage is removed first.  A storage failure leaves database data
        // intact so the user can safely retry instead of ending with a
        // partially deleted account.
        for (const bucket of new Set(assets.map((asset) => asset.bucket))) {
          const paths = assets
            .filter((asset) => asset.bucket === bucket)
            .map((asset) => asset.object_path);
          for (const batch of chunks(paths)) {
            const { error } = await admin.storage.from(bucket).remove(batch);
            if (error) throw error;
          }
        }

        // FK restricts on marketplace requests require these to be removed
        // before owned stores/profiles.  Reports that identify this user or
        // their content are removed with that content; unrelated reports,
        // users, stores and media remain untouched.
        const deleteForOwner = async (table: string, column: string) => {
          const { error } = await admin.from(table).delete().eq(column, userId);
          if (error) throw error;
        };
        const deleteForIds = async (table: string, column: string, ids: string[]) => {
          for (const batch of chunks(ids)) {
            const { error } = await admin.from(table).delete().in(column, batch);
            if (error) throw error;
          }
        };

        await Promise.all([
          deleteForOwner("store_edit_requests", "owner_id"),
          deleteForOwner("promotion_requests", "owner_id"),
          deleteForOwner("listing_likes", "user_id"),
          deleteForOwner("notifications", "recipient_id"),
        ]);
        await deleteForIds("store_edit_requests", "store_id", storeIds);
        await deleteForIds("promotion_requests", "store_id", storeIds);
        await deleteForIds("reports", "listing_id", listingIds);
        await deleteForIds("reports", "store_id", storeIds);
        await deleteForOwner("reports", "reporter_id");
        await deleteForOwner("reports", "reported_user_id");
        await deleteForIds("admin_audit_logs", "target_id", [
          userId,
          ...storeIds,
          ...listingIds,
        ]);
        await deleteForOwner("user_blocks", "blocker_id");
        await deleteForOwner("user_blocks", "blocked_user_id");
        await deleteForOwner("listings", "owner_id");
        await deleteForOwner("stores", "owner_id");
        await deleteForOwner("media_assets", "owner_id");
        await deleteForOwner("profiles", "id");

        const { error: deleteAuthError } = await admin.auth.admin.deleteUser(
          userId,
        );
        if (deleteAuthError) throw deleteAuthError;

        // Deliberately never log tokens, email addresses, phone numbers or
        // media paths.  The opaque id is enough for operational correlation.
        console.info("account_deleted", { userId });
        return response({ ok: true });
      } catch (error) {
        console.error("account_deletion_failed", {
          userId,
          error: error instanceof Error ? error.message : "unknown_error",
        });
        return response({ error: "account_deletion_failed" }, 500);
      }
    },
  ),
};
