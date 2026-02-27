-- TEST 1: Duplicate component in same BOM
BEGIN;

INSERT INTO bom_items (bom_id, component_material_id, quantity)
VALUES (1, 3, 2);  -- Wheel already exists in BOM 1

ROLLBACK;

-- TEST 2: Second routing for same material
BEGIN;

INSERT INTO routings (material_id)
VALUES (1);

ROLLBACK;

-- TEST 3: Duplicate BOM header validity (data-driven)
BEGIN;

INSERT INTO bom_header (parent_material_id, valid_from)
SELECT parent_material_id, valid_from
FROM bom_header
WHERE parent_material_id = 1
LIMIT 1;

ROLLBACK;

-- TEST 4: Zero quantity in BOM
/** BEGIN;

INSERT INTO bom_items (bom_id, component_material_id, quantity)
VALUES (1, 2, 0);

ROLLBACK;/ 
**/