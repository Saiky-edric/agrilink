-- Enforce nonnegative NOT NULL weight_per_unit on products
-- Safe idempotent pattern

begin;

-- Ensure default
alter table if exists public.products alter column weight_per_unit set default 0;

-- Backfill nulls to 0
update public.products set weight_per_unit = 0 where weight_per_unit is null;

-- Ensure NOT NULL
alter table if exists public.products alter column weight_per_unit set not null;

-- Ensure nonnegative constraint
alter table if exists public.products drop constraint if exists products_weight_per_unit_nonnegative;
alter table if exists public.products add constraint products_weight_per_unit_nonnegative check (weight_per_unit >= 0);

commit;
