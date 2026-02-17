-- ============================================
-- Seed data for Mini ERP Production System
-- ============================================

-- -----------------
-- Units
-- -----------------
INSERT INTO units (unit_code) VALUES
('PCS'),
('KG');

-- -----------------
-- Material Types
-- -----------------
INSERT INTO material_types (type_name) VALUES
('FG'),     -- Finished Good
('SFG'),    -- Semi Finished Good
('RM');     -- Raw Material

-- -----------------
-- Work Centers
-- -----------------
INSERT INTO work_centers (work_center_name) VALUES
('Assembly Line 1'),
('Painting Station'),
('Frame Welding');

-- -----------------
-- Materials
-- -----------------

-- Finished Product
INSERT INTO materials (material_code, material_name, type_id, base_unit)
VALUES
('BIKE_001', 'Mountain Bike', 1, 1);

-- Semi-finished
INSERT INTO materials (material_code, material_name, type_id, base_unit)
VALUES
('FRAME_001', 'Bike Frame', 2, 1);

-- Raw Materials
INSERT INTO materials (material_code, material_name, type_id, base_unit)
VALUES
('WHEEL_001', 'Wheel', 3, 1),
('HANDLE_001', 'Handlebar', 3, 1),
('PAINT_RED', 'Red Paint', 3, 2);

-- -----------------
-- BOM
-- Mountain Bike consists of:
-- 1 Frame
-- 2 Wheels
-- 1 Handlebar
-- -----------------

INSERT INTO bom_header (parent_material_id, valid_from)
VALUES (1, CURRENT_DATE);

INSERT INTO bom_items (bom_id, component_material_id, quantity)
VALUES
(1, 2, 1),   -- Frame
(1, 3, 2),   -- Wheels
(1, 4, 1);   -- Handlebar

-- -----------------
-- Routing
-- -----------------

INSERT INTO routings (material_id)
VALUES (1);

INSERT INTO routing_operations (routing_id, operation_number, work_center_id, operation_time_minutes)
VALUES
(1, 10, 3, 60),  -- Welding
(1, 20, 2, 30),  -- Painting
(1, 30, 1, 45);  -- Final Assembly

-- -----------------
-- Inventory
-- -----------------

INSERT INTO inventory (material_id, current_stock, safety_stock, reorder_point)
VALUES
(1, 5, 2, 3),   -- Bikes
(2, 10, 5, 5),  -- Frames
(3, 20, 10, 10), -- Wheels
(4, 15, 5, 5),  -- Handlebar
(5, 100, 20, 30); -- Paint