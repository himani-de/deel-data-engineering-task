/****************************************************************************************
-- Model: dim_products
-- Grain: 1 row per product_id
-- Purpose:
--   - Centralizes product metadata (name, barcode, price, status)
--   - Provides consistent descriptive info for reporting and future metrics
--   - Avoids storing descriptive info repeatedly in fact tables
--   - Keeps staging metadata for debugging:
--       - created_at, created_by
--       - updated_at, updated_by
*****************************************************************************************/

{{
    config(
        materialized='table',
        tags=['dim','product']
    )
}}

/*********************************** source query **********************************************************************/
select distinct
    product_id,
    product_name,
    product_barcode,
    product_unit_price,
    product_status,
    created_at,
    created_by,
    updated_at,
    updated_by
from {{ ref('stg_products') }}