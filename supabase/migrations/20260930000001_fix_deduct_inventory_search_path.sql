-- Website orders failed with: relation "stock_items" does not exist.
-- place_website_order() runs with an empty search_path, so the inventory
-- trigger on order_items could not resolve its unqualified table names.
-- Qualify them and pin the trigger function's own search_path.
create or replace function public.deduct_inventory_on_order()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  update public.stock_items s
  set qty = s.qty - (i.quantity * new.qty),
      updated_at = now()
  from public.menu_item_ingredients i
  where i.menu_item_id = new.menu_item_id
    and i.stock_item_id = s.id;
  return new;
end;
$$;
