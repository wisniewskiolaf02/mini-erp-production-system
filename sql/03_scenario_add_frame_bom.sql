WITH ids AS(
SELECT 
(SELECT material_id FROM materials WHERE material_code = 'FRAME_001') AS frame_id,
(SELECT material_id FROM materials WHERE material_code = 'WELD_WIRE_001') AS wedling_wire_id,
(SELECT unit_id FROM units WHERE unit_code = 'PCS') AS pcs_id
)
INSERT INTO materials (material_code, material_name, type_id, base_unit)
SELECT
    'TUBE_001',
    'Steel Tube',
    3,
    pcs_id
FROM ids
ON CONFLICT (material_code) DO NOTHING;

WITH ids AS(
SELECT 
(SELECT material_id FROM materials WHERE material_code = 'FRAME_001') AS frame_id,
(SELECT material_id FROM materials WHERE material_code = 'WELD_WIRE_001') AS wedling_wire_id,
(SELECT unit_id FROM units WHERE unit_code = 'PCS') AS pcs_id
)
    INSERT INTO materials (material_code, material_name, type_id, base_unit)
SELECT
    'WELD_WIRE_001',
    'Welding Wire',
    3,
    pcs_id
    FROM ids

    ON CONFLICT (material_code) DO NOTHING;

SELECT material_code, material_name 
FROM materials 
WHERE material_code IN ('TUBE_001','WELD_WIRE_001')
ORDER BY material_code;

WITH com_ids AS(
SELECT
(SELECT material_id FROM materials WHERE material_code = 'TUBE_001') AS tube_id,
(SELECT material_id FROM materials WHERE material_code = 'WELD_WIRE_001') AS weld_wire_id
)
    INSERT INTO inventory (material_id, current_stock, safety_stock, reorder_point)
SELECT
    tube_id,
    100,
    20,
    30
    FROM com_ids

    ON CONFLICT (material_id) DO NOTHING;

WITH com_ids AS(
SELECT
(SELECT material_id FROM materials WHERE material_code = 'TUBE_001') AS tube_id,
(SELECT material_id FROM materials WHERE material_code = 'WELD_WIRE_001') AS weld_wire_id
)
    INSERT INTO inventory (material_id, current_stock, safety_stock, reorder_point)
SELECT
    weld_wire_id,
    50,
    10,
    15
    FROM com_ids

    ON CONFLICT (material_id) DO NOTHING;
    
SELECT m.material_name, m.material_code, m.material_id, i.current_stock, i.safety_stock, i.reorder_point
FROM inventory i
JOIN materials m ON m.material_id = i.material_id
WHERE material_code IN ('TUBE_001','WELD_WIRE_001')
ORDER BY material_code;

WITH ids AS(
SELECT
(SELECT material_id FROM materials WHERE material_code = 'FRAME_001') AS frame_id
)
    INSERT INTO bom_header (parent_material_id, valid_from)
SELECT
    frame_id,
    DATE '2026-03-31'
    FROM ids

    ON CONFLICT (parent_material_id, valid_from) DO NOTHING

    RETURNING bom_id, parent_material_id, valid_from;

WITH ids AS (
  SELECT
    (SELECT material_id FROM materials WHERE material_code = 'FRAME_001') AS frame_id
)
SELECT bh.bom_id, bh.parent_material_id, bh.valid_from
FROM bom_header bh
JOIN ids i ON bh.parent_material_id = i.frame_id
WHERE bh.valid_from = DATE '2026-03-31';