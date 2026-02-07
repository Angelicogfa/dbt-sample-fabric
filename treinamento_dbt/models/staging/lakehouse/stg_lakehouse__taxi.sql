with source as (
    select *
    from {{ source('lakehouse_treinamento', 'taxi') }}
),
filtered_source as (
    select *
    from source
    where year(lpepPickupDatetime) <= 2019 or year(lpepPickupDatetime) <= 2019
),
unique_row as (
    select *,
        ROW_NUMBER() OVER (
            PARTITION BY vendorID, lpepPickupDatetime 
            ORDER BY totalAmount DESC
        ) AS row_num
    from filtered_source
),
filtered as (
    select *
    from unique_row
    where row_num = 1
),
with_sk_id as (
    select
        *,
        HASHBYTES(
            'SHA2_256', 
            CONCAT_WS(
                '|',
                vendorID,
                CAST(lpepPickupDatetime AS VARCHAR(50))
            )
        ) AS sk_id
    from filtered
)
select *
from with_sk_id