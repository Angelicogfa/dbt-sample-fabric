WITH vendor_data AS (
    -- Buscamos os IDs únicos da camada de staging
    SELECT DISTINCT 
        CAST("vendorID" AS INT) AS vendor_id
    from {{ ref('stg_lakehouse__taxi') }}
    WHERE "vendorID" IS NOT NULL
)
SELECT
    vendor_id,
    CASE vendor_id
        WHEN 1 THEN 'Creative Mobile Technologies'
        WHEN 2 THEN 'VeriFone Inc.'
        ELSE 'Unknown/Other'
    END AS vendor_name,
    CASE vendor_id
        WHEN 1 THEN 'CMT'
        WHEN 2 THEN 'VTS'
        ELSE 'UNK'
    END AS vendor_abbreviation
FROM vendor_data