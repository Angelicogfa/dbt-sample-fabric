{{
    config(
        materialized='incremental',
        unique_key='date',
        on_schema_change='fail'
    )
}}

WITH data AS (
    SELECT *
    FROM {{ ref ('int_dim_date') }}
    {% if is_incremental() %}
    -- Processa apenas datas que ainda não existem na tabela
    WHERE date > (SELECT MAX(date) FROM {{ this }})
    {% endif %}
)
SELECT 
    date,
    year,
    month,
    day_of_month,
    month_name,
    month_name_abbrev,
    day_of_week_name,
    day_of_week_abbrev,
    day_of_week_num,
    is_weekend,
    quarter,
    year_quarter,
    bimester,
    semester,
    year_semester,
    fortnight,
    day_of_year,
    week_of_year
FROM data
ORDER BY date