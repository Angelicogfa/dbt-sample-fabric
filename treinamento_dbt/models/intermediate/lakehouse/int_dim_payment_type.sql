WITH data AS (
    SELECT DISTINCT paymentType as payment_type
    FROM {{ ref('stg_lakehouse__taxi') }}
    WHERE paymentType IS NOT NULL
)
SELECT
    payment_type,
    CASE payment_type
        WHEN 1 THEN 'Credit card'
        WHEN 2 THEN 'Cash'
        WHEN 3 THEN 'No charge'
        WHEN 4 THEN 'Dispute'
        WHEN 5 THEN 'Unknown'
        ELSE 'Not Specified'
    END AS payment_type_name
FROM data