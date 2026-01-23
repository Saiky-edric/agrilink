-- NORMALIZE_PRODUCT_WEIGHTS.sql
-- Purpose: Normalize products.weight_per_unit (kg) from the textual unit field.
-- NOTE: Review patterns and adjust to match your catalog. Run in Supabase SQL editor.

begin;

-- 0) Safety: ensure the column exists and is nonnegative (you already enforce these elsewhere)
-- alter table if exists public.products alter column weight_per_unit set default 0;
-- update public.products set weight_per_unit = 0 where weight_per_unit is null;
-- alter table if exists public.products alter column weight_per_unit set not null;
-- alter table if exists public.products drop constraint if exists products_weight_per_unit_nonnegative;
-- alter table if exists public.products add constraint products_weight_per_unit_nonnegative check (weight_per_unit >= 0);

-- 1) Direct KG patterns: "1 kg", "2kg", "2.5 kg"
update public.products p
set weight_per_unit = (
  regexp_replace(p.unit, '[^0-9.]', '', 'g')::numeric
)
where (p.weight_per_unit is null or p.weight_per_unit = 0)
  and p.unit ~* '^[0-9.]+\s*(kg|kilo|kilogram)s?$';

-- 2) Pure KG unit (exact label): "kg", "kilo", "kilogram"
-- If unit is exactly kg-like and weight is 0, assume 1 kg per unit
update public.products p
set weight_per_unit = 1.0
where (p.weight_per_unit is null or p.weight_per_unit = 0)
  and p.unit ~* '^(kg|kilo|kilogram)s?$';

-- 3) Gram patterns: "500 g", "250grams"
update public.products p
set weight_per_unit = (
  regexp_replace(p.unit, '[^0-9.]', '', 'g')::numeric / 1000.0
)
where (p.weight_per_unit is null or p.weight_per_unit = 0)
  and p.unit ~* '^[0-9.]+\s*(g|gram|grams)$';

-- 4) Sacks/Bags with explicit KG: "sack 25kg", "bag 50 kg"
update public.products p
set weight_per_unit = (
  regexp_replace(p.unit, '[^0-9.]', '', 'g')::numeric
)
where (p.weight_per_unit is null or p.weight_per_unit = 0)
  and p.unit ~* '(sack|bag)[^0-9]*[0-9.]+\s*kg';

-- 5) Sacks/Bags without explicit number (fallback): default to 25 kg
-- Adjust if your branch uses a different default
update public.products p
set weight_per_unit = 25.0
where (p.weight_per_unit is null or p.weight_per_unit = 0)
  and p.unit ~* '(sack|bag)';

-- 6) Liters (heuristic): assume 1 kg per liter unless category-specific overrides exist
-- You may want to skip this if densities vary widely.
update public.products p
set weight_per_unit = 1.0
where (p.weight_per_unit is null or p.weight_per_unit = 0)
  and p.unit ~* '^(l|liter|litre)s?$';

-- 7) Pieces/Bundles: leave as 0 (manual review), or set a default if desired
-- Example default 0.25 kg per piece:
-- update public.products p
-- set weight_per_unit = 0.25
-- where (p.weight_per_unit is null or p.weight_per_unit = 0)
--   and p.unit ~* '^(pc|piece|pcs|bundle|bunch)';

commit;

-- Post-run audit queries
-- select id, name, unit, weight_per_unit from public.products order by updated_at desc limit 100;
-- select count(*) filter (where weight_per_unit = 0) as zero_left,
--        count(*) filter (where weight_per_unit > 0) as positive
-- from public.products;