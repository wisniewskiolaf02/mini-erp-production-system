

WITH params AS (
    SELECT
    1::int AS parent_material_id,
    20::NUMERIC AS so_qty,
    GREATEST(0, 20 - i.current_stock) AS shortage_to_meet_SO,
    (i.current_stock - 20) AS stock_after_so_if_no_prod,
    GREATEST(0, 20 + i.safety_stock - i.current_stock) AS planned_qty,
    (i.current_stock + GREATEST(0, 20 + i.safety_stock - i.current_stock)) AS stock_after_prod_before_so,
    (i.current_stock + GREATEST(0, 20 + i.safety_stock - i.current_stock)-20) AS stock_after_so
    FROM inventory i
    WHERE i.material_id = 1
),
mrp AS (
SELECT
  p.material_name AS product,
  c.material_name AS component,
  bi.quantity AS req_per_bike,
  bi.quantity * params.planned_qty AS req_for_plan,
  cu.unit_code AS component_unit,
  i.safety_stock,
  i.current_stock,
  i.current_stock - (bi.quantity * params.planned_qty) AS projected_stock,

  (i.current_stock - (bi.quantity * params.planned_qty)) <  i.safety_stock AS below_safety,
  (i.current_stock - (bi.quantity * params.planned_qty)) <= i.safety_stock AS below_or_at_safety,
  (i.current_stock - (bi.quantity * params.planned_qty)) <  0              AS stockout,
   
   params.so_qty,
   params.planned_qty,
   params.shortage_to_meet_SO,
   params.stock_after_so_if_no_prod,
   params.stock_after_prod_before_so,
   params.stock_after_so,
   
  CASE
    WHEN (i.current_stock - (bi.quantity * params.planned_qty)) < 0
      THEN -(i.current_stock - (bi.quantity * params.planned_qty))
    ELSE 0
  END AS shortage_to_0,

  CASE
    WHEN (i.current_stock - (bi.quantity * params.planned_qty)) < i.safety_stock
      THEN i.safety_stock - (i.current_stock - (bi.quantity * params.planned_qty))
    ELSE 0
  END AS shortage_to_safety

  
FROM params
JOIN materials p ON p.material_id = params.parent_material_id
JOIN bom_header bh ON p.material_id = bh.parent_material_id
JOIN bom_items bi ON bh.bom_id = bi.bom_id
JOIN materials c ON bi.component_material_id = c.material_id
JOIN units cu ON cu.unit_id = c.base_unit
LEFT JOIN inventory i ON c.material_id = i.material_id
)
SELECT *
FROM mrp

WHERE stockout = true
    OR below_or_at_safety = true   
    OR shortage_to_safety > 0

ORDER BY component;