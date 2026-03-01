-- =====================================================
-- Mini ERP Production System - Portfolio Queries (PostgreSQL)
-- =====================================================
-- How to run:
--   psql -U olaf -d mini_erp -f sql/queries.sql
--
-- Goals shown in this file:
-- - Master data sanity checks (units/types)
-- - Active BOM selection by as_of_date (validity)
-- - BOM explosion (1-level) with level + path
-- - MRP-style net requirements with safety stock
--
-- Convention:
-- - Change only CTE "inputs" in MRP/BOM queries
-- =====================================================


-- =====================================================
-- 01. WARMUP JOIN QUERIES (sanity checks)
-- =====================================================

-- Q01: Material master overview (type + base unit)

SELECT
  m.material_id,
  m.material_code,
  m.material_name,
  mt.type_name,
  u.unit_code
FROM materials m
JOIN material_types mt ON mt.type_id = m.type_id
JOIN units u ON u.unit_id = m.base_unit
ORDER BY m.material_id;

-- Q02: Routing overview (operations by work center)

SELECT
  m.material_code AS product_code,
  ro.operation_number,
  wc.work_center_name,
  ro.operation_time_minutes
FROM routings r
JOIN materials m ON m.material_id = r.material_id
JOIN routing_operations ro ON ro.routing_id = r.routing_id
JOIN work_centers wc ON wc.work_center_id = ro.work_center_id
ORDER BY m.material_code, ro.operation_number;

-- Q03: Inventory snapshot (current vs safety)

SELECT
  m.material_code,
  m.material_name,
  i.current_stock,
  i.safety_stock,
  (i.current_stock - i.safety_stock) AS above_safety
FROM inventory i
JOIN materials m ON m.material_id = i.material_id
ORDER BY m.material_code;

-- =====================================================
-- 02. BOM EXPLOSION (1-level, active by as_of_date)
-- =====================================================

WITH inputs AS (
  SELECT
    1::int AS parent_material_id,
    DATE '2026-03-10' AS as_of_date
),
active_bom AS (
  SELECT bh.parent_material_id, bh.bom_id, bh.valid_from
  FROM bom_header bh
  JOIN inputs i ON i.parent_material_id = bh.parent_material_id
  WHERE bh.valid_from <= i.as_of_date
  ORDER BY bh.valid_from DESC
  LIMIT 1
),
bom_level1 AS (
  SELECT
    1 AS level,
    ab.parent_material_id AS root_material_id,
    bi.component_material_id,
    bi.quantity AS qty_per_parent,
    (root.material_code || ' > ' || comp.material_code) AS path
  FROM active_bom ab
  JOIN materials root ON root.material_id = ab.parent_material_id
  JOIN bom_items bi ON bi.bom_id = ab.bom_id
  JOIN materials comp ON comp.material_id = bi.component_material_id
)
SELECT
  bl1.level,
  bl1.path,
  comp.material_code AS component_code,
  comp.material_name AS component_name,
  bl1.qty_per_parent
FROM bom_level1 bl1
JOIN materials comp ON comp.material_id = bl1.component_material_id
ORDER BY component_code;

-- =====================================================
-- 03. MRP v2 (SO-driven + safety, active BOM)
-- =====================================================
-- Edit only CTE "inputs":
-- - parent_material_id
-- - so_qty
-- - as_of_date

WITH inputs AS (
  SELECT
    1::int AS parent_material_id,
    20::numeric AS so_qty,
    DATE '2026-03-10' AS as_of_date
),
params AS (
  SELECT
    inp.parent_material_id,
    inp.so_qty,
    inp.as_of_date,

    GREATEST(0, inp.so_qty - inv_fg.current_stock) AS shortage_to_meet_so,
    (inv_fg.current_stock - inp.so_qty) AS stock_after_so_if_no_prod,
    GREATEST(0, inp.so_qty + inv_fg.safety_stock - inv_fg.current_stock) AS planned_qty,
    (inv_fg.current_stock + GREATEST(0, inp.so_qty + inv_fg.safety_stock - inv_fg.current_stock)) AS stock_after_prod_before_so,
    (inv_fg.current_stock + GREATEST(0, inp.so_qty + inv_fg.safety_stock - inv_fg.current_stock) - inp.so_qty) AS stock_after_so

  FROM inputs inp
  JOIN inventory inv_fg ON inv_fg.material_id = inp.parent_material_id
),

active_bom AS (
  SELECT bh.parent_material_id, bh.bom_id, bh.valid_from
  FROM bom_header bh
  JOIN params p ON p.parent_material_id = bh.parent_material_id
  WHERE bh.valid_from <= p.as_of_date
  ORDER BY bh.valid_from DESC
  LIMIT 1
),

bom_level1 AS (
  SELECT
  1 AS level,
  ab.parent_material_id AS root_material_id,
  bi.component_material_id,
  bi.quantity AS quantity_per_parent,
  -- path do debugowania (kodami materialow)
  (root.material_code || ' > ' || comp.material_code) AS path 
  FROM active_bom ab
  JOIN materials root ON root.material_id = ab.parent_material_id
  JOIN bom_items bi ON bi.bom_id = ab.bom_id
  JOIN materials comp ON comp.material_id = bi.component_material_id
),

mrp AS (
  SELECT
    prod.material_name AS product,
    comp.material_name AS component,
    be.quantity_per_parent AS req_per_bike,
    be.quantity_per_parent * p.planned_qty AS req_for_plan,
    cu.unit_code AS component_unit,
    be.level,
    be.path,

    COALESCE(inv_comp.safety_stock, 0) AS safety_stock,
    COALESCE(inv_comp.current_stock, 0) AS current_stock,
    COALESCE(inv_comp.current_stock, 0) - (be.quantity_per_parent * p.planned_qty) AS projected_stock,

    (COALESCE(inv_comp.current_stock, 0) - (be.quantity_per_parent  * p.planned_qty)) <= COALESCE(inv_comp.safety_stock, 0) AS below_or_at_safety,
    (COALESCE(inv_comp.current_stock, 0) - (be.quantity_per_parent * p.planned_qty)) < 0 AS stockout,

    p.so_qty,
    p.planned_qty,
    p.shortage_to_meet_so,
    p.stock_after_so_if_no_prod,
    p.stock_after_prod_before_so,
    p.stock_after_so,

    GREATEST(0, (be.quantity_per_parent  * p.planned_qty) - COALESCE(inv_comp.current_stock, 0)) AS shortage_to_0,
    GREATEST(0, (be.quantity_per_parent  * p.planned_qty) + COALESCE(inv_comp.safety_stock, 0) - COALESCE(inv_comp.current_stock, 0)) AS shortage_to_safety

  FROM params p
  JOIN materials prod ON prod.material_id = p.parent_material_id
  JOIN active_bom ab ON TRUE
  JOIN bom_level1 be ON TRUE
  JOIN materials comp ON comp.material_id = be.component_material_id
  JOIN units cu ON cu.unit_id = comp.base_unit
  LEFT JOIN inventory inv_comp ON inv_comp.material_id = comp.material_id
)
SELECT *
FROM mrp
ORDER BY component;

-- =====================================================
-- 04. NEXT: Recursive BOM (TODO)
-- =====================================================
-- [ ] Add BOM for FRAME_001 (SFG) and/or WHEEL_001
-- [ ] Implement WITH RECURSIVE bom_explosion:
--     - anchor: level 1 components of active BOM for FG
--     - recursive: if component has its own active BOM, expand it
--     - output: level, path, component_material_id, qty_rollup
-- [ ] Plug bom_explosion into MRP (replace bom_level1)