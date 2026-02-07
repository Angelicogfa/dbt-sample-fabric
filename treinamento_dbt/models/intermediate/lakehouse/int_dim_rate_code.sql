WITH unique_codes AS (
    SELECT DISTINCT rateCodeID as rate_code_id    
    from {{ ref('stg_lakehouse__taxi') }}
    WHERE rateCodeID IS NOT NULL
)
SELECT
    rate_code_id,
    CASE rate_code_id
        WHEN 1 THEN 'Standard rate'
        WHEN 2 THEN 'JFK'
        WHEN 3 THEN 'Newark'
        WHEN 4 THEN 'Nassau or Westchester'
        WHEN 5 THEN 'Negotiated fare'
        WHEN 6 THEN 'Group ride'
        WHEN 99 THEN 'Special/Unknown'
        ELSE 'Not Specified'
    END AS rate_code_name,
    CASE 
        WHEN rate_code_id IN (2, 3) THEN 1 
        ELSE 0 
    END AS is_airport_trip
FROM unique_codes