with sg_taxi as (
    select *
    from {{ ref('stg_lakehouse__taxi') }}
),
location as (
    select
        distinct puLocationId as location_id
    from sg_taxi
    union
    select
        distinct doLocationId as location_id
    from sg_taxi
),
dim_location as (
    select
        distinct location_id,
        HASHBYTES(
            'SHA2_256',
            CAST(location_id AS VARCHAR(50))
        ) AS sk_location_id
    from location
)
select *
from dim_location