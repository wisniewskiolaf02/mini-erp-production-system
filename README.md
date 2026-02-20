# Mini ERP Production System

A simplified ERP simulation built in PostgreSQL.

The goal of this project is to model core ERP production planning logic 
using pure SQL, without relying on any ERP interface.

The system simulates:

- Master Data (materials, material types, units)
- Inventory management (current stock, safety stock)
- BOM (Bill of Materials) structure
- Basic MRP (Material Requirements Planning)
- Sales Order driven production planning

## MRP Simulation – Sales Order Driven Planning (v2)

This version simulates a simplified MRP engine based on:

1. Sales Order demand (SO quantity)
2. Finished Good safety stock
3. Current inventory levels

### Logic Overview

Step 1 – Calculate planned production quantity for Finished Good:

planned_qty = max(0, SO + safety_stock - current_stock)

Step 2 – Explode BOM to calculate component gross requirements.

Step 3 – Simulate projected stock after production.

Step 4 – Detect shortages:
- Minimum requirement (to avoid stockout)
- Target requirement (to maintain safety stock)

The query returns only components that:
- Will experience stockout
- Will fall below safety stock
- Require replenishment

## Technologies

- PostgreSQL
- SQL (CTE, JOIN, CASE, inventory simulation)
- Git (version-controlled project structure)
- Terminal (psql)

## Project Goal

To deeply understand ERP production planning logic 
by implementing core MRP concepts manually in SQL.

This project focuses on:
- Process understanding
- Business logic modeling
- Data relationships (PK/FK)
- Planning simulation