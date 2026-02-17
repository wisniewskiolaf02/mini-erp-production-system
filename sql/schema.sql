-- =========================================================
-- Mini ERP Production System (Week 1)
-- schema.sql  |  PostgreSQL
-- Scope: Master Data + BOM + Routing + Inventory
-- =========================================================

-- Drop in dependency-safe order
DROP TABLE IF EXISTS routing_operations CASCADE;
DROP TABLE IF EXISTS routings CASCADE;
DROP TABLE IF EXISTS bom_items CASCADE;
DROP TABLE IF EXISTS bom_header CASCADE;
DROP TABLE IF EXISTS inventory CASCADE;
DROP TABLE IF EXISTS materials CASCADE;
DROP TABLE IF EXISTS material_types CASCADE;
DROP TABLE IF EXISTS units CASCADE;
DROP TABLE IF EXISTS work_centers CASCADE;

-- -----------------------------
-- Reference / Master Data tables
-- -----------------------------

-- Units (e.g., pcs, kg, m)
CREATE TABLE units (
    unit_id SERIAL PRIMARY KEY,
    unit_code VARCHAR(10) UNIQUE NOT NULL
);

-- Material types (e.g., FG, SFG, RM)
CREATE TABLE material_types (
    type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(50) UNIQUE NOT NULL
);

-- Materials (Material Master)
CREATE TABLE materials (
    material_id SERIAL PRIMARY KEY,
    material_code VARCHAR(50) UNIQUE NOT NULL,
    material_name VARCHAR(100) NOT NULL,
    type_id INT NOT NULL REFERENCES material_types(type_id),
    base_unit INT NOT NULL REFERENCES units(unit_id),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Work centers (production resources)
CREATE TABLE work_centers (
    work_center_id SERIAL PRIMARY KEY,
    work_center_name VARCHAR(100) UNIQUE NOT NULL
);

-- -----------------------------
-- BOM (Bill of Materials)
-- -----------------------------

-- BOM header (parent material + validity)
CREATE TABLE bom_header (
    bom_id SERIAL PRIMARY KEY,
    parent_material_id INT NOT NULL REFERENCES materials(material_id),
    valid_from DATE NOT NULL
);

-- BOM items (components)
CREATE TABLE bom_items (
    bom_item_id SERIAL PRIMARY KEY,
    bom_id INT NOT NULL REFERENCES bom_header(bom_id) ON DELETE CASCADE,
    component_material_id INT NOT NULL REFERENCES materials(material_id),
    quantity NUMERIC(10,2) NOT NULL CHECK (quantity > 0)
);

-- -----------------------------
-- Routing (Operations / Technology)
-- -----------------------------

-- Routing header (routing for a given material)
CREATE TABLE routings (
    routing_id SERIAL PRIMARY KEY,
    material_id INT NOT NULL REFERENCES materials(material_id)
);

-- Routing operations (steps)
CREATE TABLE routing_operations (
    operation_id SERIAL PRIMARY KEY,
    routing_id INT NOT NULL REFERENCES routings(routing_id) ON DELETE CASCADE,
    operation_number INT NOT NULL,
    work_center_id INT NOT NULL REFERENCES work_centers(work_center_id),
    operation_time_minutes INT NOT NULL CHECK (operation_time_minutes > 0),
    UNIQUE (routing_id, operation_number)
);

-- -----------------------------
-- Inventory
-- -----------------------------

CREATE TABLE inventory (
    material_id INT PRIMARY KEY REFERENCES materials(material_id),
    current_stock NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (current_stock >= 0),
    safety_stock  NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (safety_stock >= 0),
    reorder_point NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (reorder_point >= 0)
);