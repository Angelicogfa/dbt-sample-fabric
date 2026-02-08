-- =====================================================
-- Fato: Viagens de Táxi (Taxi Trip) - MART FINAL
-- =====================================================
-- Tabela fato final materializada que referencia a camada
-- intermediate com todos os relacionamentos já aplicados
-- =====================================================

{{
    config(
        materialized='table',
        tags=['fact', 'mart']
    )
}}

WITH int_fact AS (
    SELECT *
    FROM {{ ref('int_fct_taxi_trip') }}
)

SELECT
    -- Chave Primária
    trip_id,
    
    -- Foreign Keys para Dimensões
    pickup_date_fk,
    dropoff_date_fk,
    pickup_time_fk,
    dropoff_time_fk,
    pickup_location_fk,      -- sk_location_id (surrogate key)
    dropoff_location_fk,     -- sk_location_id (surrogate key)
    vendor_fk,
    payment_type_fk,
    rate_code_fk,
    
    -- Métricas/Medidas
    fareAmount,
    extra,
    mtaTax,
    improvementSurcharge,
    tipAmount,
    tollsAmount,
    totalAmount,
    tripDistance,
    trip_duration_minutes,
    
    -- Atributos Descritivos (Degenerates)
    passengerCount,
    tripType,
    storeAndFwdFlag
    
FROM int_fact
ORDER BY lpepPickupDatetime
