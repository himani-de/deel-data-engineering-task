# Architecture Decision Record: Analytics Pipeline Design

## Status
Proposed / Implemented

## Context

The analytics system ingests transactional data from a **frequently-changing source system** (orders, order items, customers, products)
Key requirements:

- Historical tracking of changes (SCD2) for order-level and item-level metrics  
- Business-friendly, easy-to-query dimensions (e.g., `customer_status` = 'active'/'inactive')  
- Incremental and efficient processing for large tables  
- KPI calculations for reporting and API consumption  
- Clear separation of layers for maintainability and scalability

## Decision

Designed the pipeline in **three main layers**:

### 1. **Staging (STG) Layer**
- **Purpose:** Raw ingestion of source tables with minimal transformation  
- **Design:**  
  - frequent refresh every 2 hours  
  - Null filtering, deduplication,data type normalization, and renaming for consistency  
- **Reasoning:**  
  - Reduces repeated scans on raw sources  
  - Keeps raw data close to source for auditing  

### 2. **Intermediate (INT) Layer**
- **Purpose:** Business-context transformations  
- **Design:**  
  - Joins fact and dimension sources (e.g., order items + orders)  
  - Deduplicates high-cardinality entities (order_item_id, order_id)  
  - Applies business rules like `order_status_category`, `is_open`, `is_pending`  
  - Incremental merges to keep processing efficient for frequent changes  
- **Reasoning:**  
  - High-cardinality and frequently changing columns are transformed once  
  - Ensures downstream mart is smaller and optimized  

### 3. **Mart (DIM / FACT) Layer**
- **Purpose:** Analytical layer ready for BI consumption  
- **Design:**  
  - Fact tables: `fact_orders`, `fact_order_items`  
  - Dimension tables: `dim_customer`, `dim_product`, `dim_date`  
  - Columns are business-friendly and include audit metadata (created_at/by, updated_at/by)  
  - Derived flags (`active`/`inactive`) for clarity  
- **Reasoning:**  
  - Serves consistent, clean, and business-friendly KPIs  
  - Users don’t need to join multiple intermediate tables

## Considerations

- **High cardinality:**  
  - Deduplication at INT layer avoids repeated scans at mart  
  - Dimension tables are keyed by unique IDs  
- **Frequent source changes:**  
  - Incremental STG refresh + INT merge ensures near-real-time updates without full refreshes  
- **Historical tracking:**  
  - Snapshots (`orders_history`) for SCD2 tracking  
  - Enables querying both historical and current states  
- **Performance:**  
  - STG incremental load reduces I/O on source tables  
  - Mart queries optimized for reporting and API  
  
## Consequences

- Pros:  
  - Clear separation of raw, intermediate, and analytical layers  
  - Easier maintenance and auditing  
  - Scalable for large datasets  
  - Ready for BI dashboards or API queries  

- Cons:  
  - Slightly more complex ETL pipeline  
  - Requires careful management of incremental merges  

## Future Scope
  - diagram to be updated
  - There are potential pii data like customer_name, address and can be hashed to store in warehouse tables.
  - The access management will be designed accordingly to the pii data to stakeholders.