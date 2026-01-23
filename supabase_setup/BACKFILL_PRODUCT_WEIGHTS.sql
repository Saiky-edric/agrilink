-- BACKFILL_PRODUCT_WEIGHTS.sql
-- Purpose: Fix existing products that have weight_per_unit = 0
-- This will update products based on their unit field to set proper weights

BEGIN;

-- Show current state before fix
DO $$ 
BEGIN
    RAISE NOTICE 'Products with zero weight: %', (SELECT COUNT(*) FROM public.products WHERE weight_per_unit = 0);
    RAISE NOTICE 'Products with weight > 0: %', (SELECT COUNT(*) FROM public.products WHERE weight_per_unit > 0);
END $$;

-- 1) Exact kg amounts: "50 kg", "25 kg", "2.5 kg", etc.
UPDATE public.products
SET weight_per_unit = (
    regexp_replace(unit, '[^0-9.]', '', 'g')::numeric
)
WHERE weight_per_unit = 0
  AND unit ~* '^[0-9.]+\s*(kg|kilo|kilogram)s?$'
  AND regexp_replace(unit, '[^0-9.]', '', 'g') ~ '^[0-9.]+$';

-- 2) Exact "kg" unit without number (assume 1 kg per unit)
UPDATE public.products
SET weight_per_unit = 1.0
WHERE weight_per_unit = 0
  AND unit ~* '^(kg|kilo|kilogram)s?$';

-- 3) Sack 50 kg
UPDATE public.products
SET weight_per_unit = 50.0
WHERE weight_per_unit = 0
  AND unit ~* 'sack.*50.*kg';

-- 4) Sack 25 kg or Bag 25 kg
UPDATE public.products
SET weight_per_unit = 25.0
WHERE weight_per_unit = 0
  AND (unit ~* 'sack.*25.*kg' OR unit ~* 'bag.*25.*kg');

-- 5) Generic sack/bag without explicit weight (default to 25 kg)
UPDATE public.products
SET weight_per_unit = 25.0
WHERE weight_per_unit = 0
  AND unit ~* '(sack|bag)';

-- 6) Gram patterns: "500 g", "250 grams"
UPDATE public.products
SET weight_per_unit = (
    regexp_replace(unit, '[^0-9.]', '', 'g')::numeric / 1000.0
)
WHERE weight_per_unit = 0
  AND unit ~* '^[0-9.]+\s*(g|gram|grams)$'
  AND regexp_replace(unit, '[^0-9.]', '', 'g') ~ '^[0-9.]+$';

-- 7) Liters (assume 1 kg per liter as approximation)
UPDATE public.products
SET weight_per_unit = 1.0
WHERE weight_per_unit = 0
  AND unit ~* '^(l|liter|litre)s?$';

-- 8) Pieces/bundles (use small default weight for safety)
-- Uncomment if you want to set a default for pieces
-- UPDATE public.products
-- SET weight_per_unit = 0.25
-- WHERE weight_per_unit = 0
--   AND unit ~* '^(pc|piece|pcs|bundle|bunch)';

-- Show results after fix
DO $$ 
BEGIN
    RAISE NOTICE '=== RESULTS ===';
    RAISE NOTICE 'Products STILL with zero weight: %', (SELECT COUNT(*) FROM public.products WHERE weight_per_unit = 0);
    RAISE NOTICE 'Products NOW with weight > 0: %', (SELECT COUNT(*) FROM public.products WHERE weight_per_unit > 0);
END $$;

COMMIT;

-- Verification queries - Run these separately to check results
-- SELECT id, name, unit, weight_per_unit FROM public.products ORDER BY weight_per_unit DESC LIMIT 20;
-- SELECT id, name, unit, weight_per_unit FROM public.products WHERE weight_per_unit = 0;
-- SELECT unit, COUNT(*) as count FROM public.products WHERE weight_per_unit = 0 GROUP BY unit;
