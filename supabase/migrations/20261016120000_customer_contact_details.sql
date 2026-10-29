-- Collection/delivery lookup: the POS keeps extra phone numbers, email,
-- address and notes for each customer.
alter table public.customers
  add column if not exists phone2   text not null default '',
  add column if not exists phone3   text not null default '',
  add column if not exists email    text not null default '',
  add column if not exists address  text not null default '',
  add column if not exists city     text not null default '',
  add column if not exists postcode text not null default '',
  add column if not exists comments text not null default '';
