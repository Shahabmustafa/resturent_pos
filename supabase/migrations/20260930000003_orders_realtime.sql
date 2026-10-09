-- Live order updates.
--   * POS: website orders appear on the Orders screen without a refresh.
--   * Website: "My Orders" status changes as soon as staff update an order.
-- Row level security still applies: staff receive their branch's orders,
-- customers receive only their own.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'orders'
  ) then
    alter publication supabase_realtime add table public.orders;
  end if;
end $$;
