// manage-rider-login
// Creates, updates or removes the login a rider uses in the Rider mobile app.
// The rider signs in with their phone number; the auth email is <digits>@rider.pos.
// Only a branch admin/manager or the company owner can call this.
//
// Body:
//   { action: "set", rider_id, password? }  create the login (password required) or
//                                           reset the password / sync a changed phone
//   { action: "remove", rider_id }          delete the login; the rider row stays

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

class HttpError extends Error {
  constructor(public status: number, message: string) {
    super(message);
  }
}

/** Same rule as RiderDatasource.emailForPhone in the app: 0300-1234567 / +92 300 1234567 -> 03001234567. */
function riderEmail(phone: string): string | null {
  let digits = phone.replace(/\D/g, "");
  if (digits.startsWith("92") && digits.length === 12) digits = "0" + digits.slice(2);
  if (digits.length === 10 && digits.startsWith("3")) digits = "0" + digits;
  return digits.length >= 7 ? `${digits}@rider.pos` : null;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const url = Deno.env.get("SUPABASE_URL")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  const caller = createClient(url, anonKey, {
    global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
    auth: { persistSession: false },
  });
  const admin = createClient(url, serviceKey, { auth: { persistSession: false } });

  try {
    const { data: userData, error: userErr } = await caller.auth.getUser();
    if (userErr || !userData.user) throw new HttpError(401, "Not logged in");

    const body = await req.json();
    if (!body.rider_id) throw new HttpError(400, "rider_id is required");

    const { data: rider, error: findErr } = await admin
      .from("riders")
      .select("id, branch_id, phone, auth_user_id")
      .eq("id", body.rider_id)
      .maybeSingle();
    if (findErr) throw new HttpError(500, findErr.message);
    if (!rider) throw new HttpError(404, "Rider not found");

    const { data: canManage, error: rpcErr } = await caller.rpc("can_manage_branch", { p_branch_id: rider.branch_id });
    if (rpcErr) throw new HttpError(500, rpcErr.message);
    if (!canManage) throw new HttpError(403, "You can't manage riders for this branch");

    switch (body.action) {
      case "set": {
        const email = riderEmail(rider.phone ?? "");
        if (!email) throw new HttpError(400, "Add a valid phone number for this rider first");
        const password = body.password ? String(body.password) : undefined;
        if (password !== undefined && password.length < 6) {
          throw new HttpError(400, "Password must be at least 6 characters");
        }
        const taken = (msg: string) =>
          /already|registered|exists/i.test(msg)
            ? new HttpError(409, "Another login already uses this phone number")
            : new HttpError(400, msg);

        if (rider.auth_user_id) {
          const changes: Record<string, unknown> = { email, email_confirm: true };
          if (password) changes.password = password;
          const { error } = await admin.auth.admin.updateUserById(rider.auth_user_id, changes);
          if (error) throw taken(error.message);
          return json({ ok: true, login: email.split("@")[0] });
        }

        if (!password) throw new HttpError(400, "Set a password to create the rider's login");
        const { data: created, error: authErr } = await admin.auth.admin.createUser({
          email,
          password,
          email_confirm: true,
        });
        if (authErr) throw taken(authErr.message);

        const { error: linkErr } = await admin
          .from("riders")
          .update({ auth_user_id: created.user.id })
          .eq("id", rider.id);
        if (linkErr) {
          await admin.auth.admin.deleteUser(created.user.id);
          throw new HttpError(400, linkErr.message);
        }
        return json({ ok: true, login: email.split("@")[0] });
      }

      case "remove": {
        if (!rider.auth_user_id) return json({ ok: true });
        await admin.from("riders").update({ auth_user_id: null }).eq("id", rider.id);
        const { error } = await admin.auth.admin.deleteUser(rider.auth_user_id);
        if (error) throw new HttpError(400, error.message);
        return json({ ok: true });
      }

      default:
        throw new HttpError(400, "Unknown action");
    }
  } catch (e) {
    if (e instanceof HttpError) return json({ error: e.message }, e.status);
    return json({ error: e instanceof Error ? e.message : String(e) }, 500);
  }
});
