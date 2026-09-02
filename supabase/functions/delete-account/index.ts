/**
 * delete-account — permanently erases the caller's account and all their data.
 *
 * Required by Google Play's user-data deletion policy: an app that lets people
 * create an account must let them delete it. Removing the auth record needs the
 * service-role key, which can never ship inside the app, so the work happens
 * here and the caller is authorised from their own JWT.
 *
 * Deploy:
 *   supabase functions deploy delete-account
 *
 * SUPABASE_URL, SUPABASE_ANON_KEY and SUPABASE_SERVICE_ROLE_KEY are injected by
 * the platform — do not add them to your own secrets.
 */
import { createClient } from "jsr:@supabase/supabase-js@2";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return json({ error: "Missing authorization header" }, 401);

  const url = Deno.env.get("SUPABASE_URL")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  // Identify the caller from their own JWT. Never accept a user id from the
  // request body — that would let anyone delete anyone.
  const caller = createClient(url, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: { user }, error: authError } = await caller.auth.getUser();
  if (authError || !user) return json({ error: "Invalid or expired session" }, 401);

  const admin = createClient(url, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const uid = user.id;

  try {
    // Leaf tables first — remittances and savings reference obligations.
    for (const table of ["remittances", "savings_log"]) {
      const { error } = await admin.from(table).delete().eq("user_id", uid);
      if (error) throw new Error(`${table}: ${error.message}`);
    }
    for (const table of ["obligations", "responsibility_centers"]) {
      const { error } = await admin.from(table).delete().eq("user_id", uid);
      if (error) throw new Error(`${table}: ${error.message}`);
    }

    const { error: profileError } = await admin
      .from("profiles")
      .delete()
      .eq("id", uid);
    if (profileError) throw new Error(`profiles: ${profileError.message}`);

    // The auth record goes last: once it is gone the caller's token is dead,
    // so anything that failed before this point can still be retried.
    const { error: userError } = await admin.auth.admin.deleteUser(uid);
    if (userError) throw new Error(`auth: ${userError.message}`);

    return json({ success: true });
  } catch (e) {
    // Log the id, not the payload — this runs on rows we are about to destroy.
    console.error(`delete-account failed for ${uid}:`, e);
    return json(
      { error: e instanceof Error ? e.message : "Account deletion failed" },
      500,
    );
  }
});
