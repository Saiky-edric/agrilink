-- Adds per-2kg step fee setting for J&T to platform_settings
begin;

alter table if exists public.platform_settings
  add column if not exists jt_per2kg_fee numeric default 25.0;

update public.platform_settings
set jt_per2kg_fee = coalesce(jt_per2kg_fee, 25.0);

commit;
