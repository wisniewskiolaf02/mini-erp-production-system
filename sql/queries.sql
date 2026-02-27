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
mrp AS (
  SELECT
    prod.material_name AS product,
    comp.material_name AS component,
    bi.quantity AS req_per_bike,
    bi.quantity * p.planned_qty AS req_for_plan,
    cu.unit_code AS component_unit,

    COALESCE(inv_comp.safety_stock, 0) AS safety_stock,
    COALESCE(inv_comp.current_stock, 0) AS current_stock,
    COALESCE(inv_comp.current_stock, 0) - (bi.quantity * p.planned_qty) AS projected_stock,

    (COALESCE(inv_comp.current_stock, 0) - (bi.quantity * p.planned_qty)) <= COALESCE(inv_comp.safety_stock, 0) AS below_or_at_safety,
    (COALESCE(inv_comp.current_stock, 0) - (bi.quantity * p.planned_qty)) < 0 AS stockout,

    p.so_qty,
    p.planned_qty,
    p.shortage_to_meet_so,
    p.stock_after_so_if_no_prod,
    p.stock_after_prod_before_so,
    p.stock_after_so,

    GREATEST(0, (bi.quantity * p.planned_qty) - COALESCE(inv_comp.current_stock, 0)) AS shortage_to_0,
    GREATEST(0, (bi.quantity * p.planned_qty) + COALESCE(inv_comp.safety_stock, 0) - COALESCE(inv_comp.current_stock, 0)) AS shortage_to_safety

  FROM params p
  JOIN materials prod ON prod.material_id = p.parent_material_id
  JOIN active_bom ab ON TRUE
  JOIN bom_items bi ON ab.bom_id = bi.bom_id
  JOIN materials comp ON bi.component_material_id = comp.material_id
  JOIN units cu ON cu.unit_id = comp.base_unit
  LEFT JOIN inventory inv_comp ON inv_comp.material_id = comp.material_id
)
SELECT *
FROM mrp
ORDER BY component;