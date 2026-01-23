-- Backfill users.store_name from farmer_verifications.farm_name when missing
-- Safe to run multiple times; only fills blanks

begin;

update public.users u
set store_name = v.farm_name
from public.farmer_verifications v
where u.id = v.farmer_id
  and (u.store_name is null or trim(u.store_name) = '')
  and v.farm_name is not null and trim(v.farm_name) <> '';

commit;
