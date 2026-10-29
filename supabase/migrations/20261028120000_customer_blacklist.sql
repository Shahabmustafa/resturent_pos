-- POS can blacklist a customer (shown on the customer's details screen).
alter table public.customers
  add column if not exists blacklisted boolean not null default false;
