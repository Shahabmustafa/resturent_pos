-- Website ordering switches and prep times, set on the POS Manage screen.
--   * online_orders_enabled: master switch for every website order
--   * delivery_enabled / collection_enabled: switch each order type
--   * delivery_minutes / collection_minutes: the time the website quotes
-- The order functions enforce the switches on the server, so a closed website
-- cannot be bypassed from the browser.

alter table public.branches
  add column if not exists online_orders_enabled boolean not null default true,
  add column if not exists delivery_enabled      boolean not null default true,
  add column if not exists collection_enabled    boolean not null default true,
  add column if not exists delivery_minutes      int not null default 45,
  add column if not exists collection_minutes    int not null default 15;

alter table public.branches drop constraint if exists branches_prep_minutes_check;
alter table public.branches add constraint branches_prep_minutes_check
  check (delivery_minutes between 0 and 300 and collection_minutes between 0 and 300);

-- What the website may read (public); the rest of the branches row stays private.
create or replace function public.website_order_settings()
returns table (
  online_orders_enabled boolean,
  delivery_enabled boolean,
  collection_enabled boolean,
  delivery_minutes int,
  collection_minutes int
)
language sql stable security definer set search_path = '' as $$
  select b.online_orders_enabled, b.delivery_enabled, b.collection_enabled, b.delivery_minutes, b.collection_minutes
  from public.branches b where b.id = public.website_branch_id()
$$;
revoke all on function public.website_order_settings() from public;
grant execute on function public.website_order_settings() to anon, authenticated;

-- Both cash and card checkout call this before anything is saved.
create or replace function public.check_website_order_details(
  p_delivery boolean,
  p_customer_name text,
  p_customer_phone text,
  p_address text
) returns void
language plpgsql stable security definer set search_path = '' as $$
declare
  s record;
begin
  select b.online_orders_enabled, b.delivery_enabled, b.collection_enabled into s
  from public.branches b where b.id = public.website_branch_id();
  if found then
    if not s.online_orders_enabled then
      raise exception 'Online ordering is currently switched off';
    end if;
    if p_delivery and not s.delivery_enabled then
      raise exception 'Delivery is currently not available';
    end if;
    if not p_delivery and not s.collection_enabled then
      raise exception 'Collection is currently not available';
    end if;
  end if;
  if coalesce(trim(p_customer_name), '') = '' or coalesce(trim(p_customer_phone), '') = '' then
    raise exception 'Name and phone are required';
  end if;
  if p_delivery and coalesce(trim(p_address), '') = '' then
    raise exception 'Delivery address is required';
  end if;
end;
$$;
revoke all on function public.check_website_order_details(boolean, text, text, text) from public, anon, authenticated;
