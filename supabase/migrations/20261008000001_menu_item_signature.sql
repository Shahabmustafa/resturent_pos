-- Signature dishes are highlighted inside their category (like the printed menu)
-- and listed on the website's home page "Signature Menu" section.

alter table public.menu_items
  add column if not exists is_signature boolean not null default false;
