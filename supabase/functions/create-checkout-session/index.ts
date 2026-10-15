// create-checkout-session
// Starts a card payment for a website order. The cart is checked and priced by
// start_card_checkout() (as the signed-in customer), then a Stripe Checkout
// session is created for that amount. The order itself is only created once
// Stripe confirms the payment (see stripe-webhook).
//
// Body:
//   { delivery, name, phone, address, notes, items, return_url }
//   items:      [{ menu_item_id, size, qty }]  (same as place_website_order)
//   return_url: the website page to come back to; must be on the caller's origin
//
// Returns { url, payment_id }: send the browser to url.
//
// Secrets: STRIPE_SECRET_KEY

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import Stripe from "npm:stripe@17.7.0";

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

type PricedLine = { item_name: string; unit_price: number; qty: number };

/** The page Stripe sends the customer back to, with our query parameters added. */
function backTo(returnUrl: string, params: Record<string, string>): string {
  const url = new URL(returnUrl);
  for (const [k, v] of Object.entries(params)) url.searchParams.set(k, v);
  return url.toString();
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const url = Deno.env.get("SUPABASE_URL")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const stripeKey = Deno.env.get("STRIPE_SECRET_KEY");

  const caller = createClient(url, anonKey, {
    global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
    auth: { persistSession: false },
  });
  const admin = createClient(url, serviceKey, { auth: { persistSession: false } });

  try {
    if (!stripeKey) throw new HttpError(500, "Card payments are not set up yet");
    const stripe = new Stripe(stripeKey, { httpClient: Stripe.createFetchHttpClient() });

    const { data: userData, error: userErr } = await caller.auth.getUser();
    if (userErr || !userData.user) throw new HttpError(401, "Please log in to place an order");

    const body = await req.json();

    // Only send customers back to the site they came from.
    let returnUrl: URL;
    try {
      returnUrl = new URL(String(body.return_url ?? ""));
    } catch {
      throw new HttpError(400, "return_url is required");
    }
    const origin = req.headers.get("Origin");
    if (!/^https?:$/.test(returnUrl.protocol) || (origin && returnUrl.origin !== origin)) {
      throw new HttpError(400, "return_url must be on this website");
    }
    returnUrl.search = "";
    returnUrl.hash = "";

    // Same checks and menu prices as a cash order; nothing priced here.
    const { data: checkout, error: rpcErr } = await caller.rpc("start_card_checkout", {
      p_delivery: !!body.delivery,
      p_customer_name: String(body.name ?? ""),
      p_customer_phone: String(body.phone ?? ""),
      p_address: String(body.address ?? ""),
      p_notes: String(body.notes ?? ""),
      p_items: body.items ?? [],
    });
    if (rpcErr) throw new HttpError(400, rpcErr.message);

    const paymentId = checkout.payment_id as string;
    const lines = checkout.lines as PricedLine[];
    const deliveryFee = Number(checkout.delivery_fee ?? 0);
    // Pence; complete_card_checkout() checks the total with the same rounding.
    const pence = (pounds: number) => Math.round(pounds * 100);

    const session = await stripe.checkout.sessions.create({
      mode: "payment",
      currency: "gbp",
      line_items: [
        ...lines.map((l) => ({
          quantity: l.qty,
          price_data: {
            currency: "gbp",
            unit_amount: pence(Number(l.unit_price)),
            product_data: { name: l.item_name },
          },
        })),
        ...(deliveryFee > 0
          ? [{
            quantity: 1,
            price_data: {
              currency: "gbp",
              unit_amount: pence(deliveryFee),
              product_data: { name: "Delivery charge" },
            },
          }]
          : []),
      ],
      customer_email: userData.user.email,
      client_reference_id: paymentId,
      metadata: { payment_id: paymentId },
      payment_intent_data: { metadata: { payment_id: paymentId } },
      // Stripe's shortest allowed expiry; an unpaid cart doesn't linger.
      expires_at: Math.floor(Date.now() / 1000) + 30 * 60,
      success_url: backTo(returnUrl.toString(), { checkout: "success", payment: paymentId }),
      cancel_url: backTo(returnUrl.toString(), { checkout: "cancelled", payment: paymentId }),
    });

    const { error: saveErr } = await admin
      .from("website_payments")
      .update({ stripe_session_id: session.id })
      .eq("id", paymentId);
    if (saveErr) throw new HttpError(500, saveErr.message);

    return json({ url: session.url, payment_id: paymentId });
  } catch (e) {
    if (e instanceof HttpError) return json({ error: e.message }, e.status);
    return json({ error: e instanceof Error ? e.message : String(e) }, 500);
  }
});
