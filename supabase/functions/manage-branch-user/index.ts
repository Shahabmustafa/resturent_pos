// manage-branch-user
// Creates, updates and deletes Supabase Auth accounts for branch users.
// Only the branch admin/manager or the company owner may call it.
//
// Body:
//   { action: "create", email, password, name, username, phone?, role, status?, avatar_url? }
//   { action: "update", user_id, email?, password?, name?, username?, phone?, role?, status?, avatar_url? }
//   { action: "delete", user_id }

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const PROFILE_FIELDS = ["name", "username", "phone", "role", "status", "avatar_url"] as const;

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

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const url = Deno.env.get("SUPABASE_URL")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  // Client with the caller's JWT: RLS helper functions run as this user
  const caller = createClient(url, anonKey, {
    global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
    auth: { persistSession: false },
  });
  const admin = createClient(url, serviceKey, { auth: { persistSession: false } });

  try {
    const { data: userData, error: userErr } = await caller.auth.getUser();
    if (userErr || !userData.user) throw new HttpError(401, "Not logged in");
    const callerAuthId = userData.user.id;

    const body = await req.json();

    // There is a single branch; its row only carries the restaurant settings.
    const theBranchId = async (): Promise<string> => {
      const { data, error } = await admin.from("branches").select("id").limit(1).maybeSingle();
      if (error || !data) throw new HttpError(500, "Branch not found");
      return data.id as string;
    };

    const assertCanManage = async (branchId: string, touchesAdmin: boolean) => {
      const { data: canManage, error } = await caller.rpc("can_manage_branch", { p_branch_id: branchId });
      if (error) throw new HttpError(500, error.message);
      if (!canManage) throw new HttpError(403, "You are not allowed to manage users of this branch");

      if (touchesAdmin) {
        const [{ data: role }, { data: companyId }] = await Promise.all([
          caller.rpc("my_branch_role"),
          caller.rpc("my_company_id"),
        ]);
        if (role !== "admin" && !companyId) {
          throw new HttpError(403, "Only an admin can create or change an admin user");
        }
      }
    };

    const pickProfile = (src: Record<string, unknown>) => {
      const out: Record<string, unknown> = {};
      for (const f of PROFILE_FIELDS) if (src[f] !== undefined) out[f] = src[f];
      return out;
    };

    switch (body.action) {
      case "create": {
        const { email, password } = body;
        if (!email || !password || !body.name || !body.username) {
          throw new HttpError(400, "email, password, name and username are required");
        }
        await assertCanManage(await theBranchId(), body.role === "admin");

        const { data: created, error: authErr } = await admin.auth.admin.createUser({
          email: String(email).trim().toLowerCase(),
          password,
          email_confirm: true,
        });
        if (authErr) throw new HttpError(400, authErr.message);

        const { data: row, error: insErr } = await admin
          .from("branch_users")
          .insert({
            ...pickProfile(body),
            email: created.user.email,
            auth_user_id: created.user.id,
          })
          .select()
          .single();

        if (insErr) {
          await admin.auth.admin.deleteUser(created.user.id);
          throw new HttpError(400, insErr.message);
        }
        return json(row);
      }

      case "update": {
        const { data: target, error: findErr } = await admin
          .from("branch_users")
          .select()
          .eq("id", body.user_id)
          .maybeSingle();
        if (findErr) throw new HttpError(500, findErr.message);
        if (!target) throw new HttpError(404, "User not found");

        await assertCanManage(await theBranchId(), target.role === "admin" || body.role === "admin");

        const email = body.email ? String(body.email).trim().toLowerCase() : undefined;
        const authChanges: Record<string, unknown> = {};
        if (email && email !== target.email) {
          authChanges.email = email;
          authChanges.email_confirm = true;
        }
        if (body.password) authChanges.password = body.password;

        if (Object.keys(authChanges).length > 0) {
          if (!target.auth_user_id) throw new HttpError(400, "This user has no auth account");
          const { error } = await admin.auth.admin.updateUserById(target.auth_user_id, authChanges);
          if (error) throw new HttpError(400, error.message);
        }

        const changes = pickProfile(body);
        if (authChanges.email) changes.email = email;

        const { data: row, error: updErr } = await admin
          .from("branch_users")
          .update(changes)
          .eq("id", target.id)
          .select()
          .single();
        if (updErr) throw new HttpError(400, updErr.message);
        return json(row);
      }

      case "delete": {
        const { data: target, error: findErr } = await admin
          .from("branch_users")
          .select()
          .eq("id", body.user_id)
          .maybeSingle();
        if (findErr) throw new HttpError(500, findErr.message);
        if (!target) throw new HttpError(404, "User not found");
        if (target.auth_user_id === callerAuthId) throw new HttpError(400, "You cannot delete your own account");

        await assertCanManage(await theBranchId(), target.role === "admin");

        const { error: delErr } = await admin.from("branch_users").delete().eq("id", target.id);
        if (delErr) throw new HttpError(400, delErr.message);
        if (target.auth_user_id) await admin.auth.admin.deleteUser(target.auth_user_id);
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
