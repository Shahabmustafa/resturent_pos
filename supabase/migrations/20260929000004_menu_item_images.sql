-- Step 4: multiple photos per menu item.
-- image_urls holds every photo (cover first). image_url stays as the cover so the
-- POS and the website keep working unchanged.

alter table public.menu_items
  add column if not exists image_urls text[] not null default '{}';

-- Existing items: their single photo becomes the first entry.
update public.menu_items
set image_urls = array[image_url]
where image_url is not null and image_url <> '' and cardinality(image_urls) = 0;
