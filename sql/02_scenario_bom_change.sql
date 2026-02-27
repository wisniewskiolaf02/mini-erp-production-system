-- Scenario: Engineering change in BOM for BIKE_001
-- Effective from: 2026-03-01
-- Change: Add PAINT_RED (material_id = 5), qty 0.20 KG per bike
-- Safe to run on a fresh reset (schema + seed). Not intended to be run twice without reset.

BEGIN;

WITH inputs AS (
  SELECT
    1::int          AS parent_material_id,
    DATE '2026-03-01' AS change_date,
    5::int          AS paint_material_id,
    0.20::numeric   AS paint_qty
),
old_bom AS (
  -- BOM active BEFORE the change date
  SELECT bh.bom_id
  FROM bom_header bh
  JOIN inputs i ON i.parent_material_id = bh.parent_material_id
  WHERE bh.valid_from < i.change_date
  ORDER BY bh.valid_from DESC
  LIMIT 1
),
new_bom AS (
  INSERT INTO bom_header (parent_material_id, valid_from)
  SELECT i.parent_material_id, i.change_date
  FROM inputs i
  RETURNING bom_id
),
copy_items AS (
  INSERT INTO bom_items (bom_id, component_material_id, quantity)
  SELECT nb.bom_id, bi.component_material_id, bi.quantity
  FROM new_bom nb
  JOIN old_bom ob ON TRUE
  JOIN bom_items bi ON bi.bom_id = ob.bom_id
  RETURNING 1
),
add_paint AS (
  INSERT INTO bom_items (bom_id, component_material_id, quantity)
  SELECT nb.bom_id, i.paint_material_id, i.paint_qty
  FROM new_bom nb
  JOIN inputs i ON TRUE
  RETURNING 1
)
SELECT
  (SELECT bom_id FROM old_bom) AS old_bom_id,
  (SELECT bom_id FROM new_bom) AS new_bom_id;

COMMIT;