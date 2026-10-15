// stripe-webhook
// Stripe calls this when a website card checkout finishes. A paid checkout
// becomes a real order (Online / Paid) through complete_card_checkout(); an
// expired one is marked expired. Every request is verified with the webhook
// signing secret, so only Stripe can mark an order as paid.
//
// Deploy with --no-verify-jwt (Stripe doesn't send a Supabase token).
// Stripe events: checkout.session.completed,
//                checkout.session.async_payment_succeeded,
//                checkout.session.expired
//
// Secrets: STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import Stripe from "npm:stripe@17.7.0";

const cryptoProvider = Stripe.createSubtleCryptoProvider();

function text(body: string, status = 200) {
  return new Response(body, { status, headers: { "Content-Type": "text/plain" } });
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return text("Method not allowed", 405);

  const stripeKey = Deno.env.get("STRIPE_SECRET_KEY");
  const webhookSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET");
  if (!stripeKey || !webhookSecret) return text("Stripe secrets are not set", 500);

  const stripe = new Stripe(stripeKey, { httpClient: Stripe.createFetchHttpClient() });
  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
    auth: { persistSession: false },
  });

  // The signature is over the raw body, so read it as text before parsing.
  const signature = req.headers.get("Stripe-Signature");
  if (!signature) return text("Missing Stripe-Signature", 400);
  let event: Stripe.Event;
  try {
    event = await stripe.webhooks.constructEventAsync(
      await req.text(),
      signature,
      webhookSecret,
      undefined,
      cryptoProvider,
    );
  } catch (e) {
    return text(`Invalid signature: ${e instanceof Error ? e.message : e}`, 400);
  }

  const session = event.data.object as Stripe.Checkout.Session;
  const paymentId = session.metadata?.payment_id;
  // Not one of ours (e.g. a payment made some other way on this Stripe account).
  if (!paymentId) return text("ignored");

  switch (event.type) {
    case "checkout.session.completed":
    case "checkout.session.async_payment_succeeded": {
      // Delayed payment methods complete as "unpaid" and succeed later.
      if (session.payment_status !== "paid") return text("waiting for payment");
      const { data: orderNumber, error } = await admin.rpc("complete_card_checkout", {
        p_payment_id: paymentId,
        p_session_id: session.id,
        p_amount_pence: session.amount_total,
      });
      // A non-2xx makes Stripe retry, and complete_card_checkout() is safe to repeat.
      if (error) {
        console.error(`complete_card_checkout failed for ${paymentId}: ${error.message}`);
        return text(error.message, 500);
      }
      return text(`order ${orderNumber}`);
    }

    case "checkout.session.expired": {
      const { error } = await admin
        .from("website_payments")
        .update({ status: "expired" })
        .eq("id", paymentId)
        .eq("status", "open");
      if (error) return text(error.message, 500);
      return text("expired");
    }

    default:
      return text("ignored");
  }
});
