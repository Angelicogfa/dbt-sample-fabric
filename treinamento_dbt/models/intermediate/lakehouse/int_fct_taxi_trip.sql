WITH stg_taxi AS (
    SELECT *
    FROM {{ ref('stg_lakehouse__taxi') }}
    WHERE lpepPickupDatetime IS NOT NULL
      AND lpepDropoffDatetime IS NOT NULL
      AND lpepDropoffDatetime > lpepPickupDatetime
),

-- Dimensões intermediate para JOINs
int_location AS (
    SELECT *
    FROM {{ ref('int_dim_location') }}
),

int_vendor AS (
    SELECT *
    FROM {{ ref('int_dim_vendor') }}
),

int_payment_type AS (
    SELECT *
    FROM {{ ref('int_dim_payment_type') }}
),

int_rate_code AS (
    SELECT *
    FROM {{ ref('int_dim_rate_code') }}
),

-- JOINs com as dimensões aplicando surrogate keys
fact_base AS (
    SELECT
        -- Chave Primária da Fato (Surrogate Key da Staging)
        taxi.sk_id AS trip_id,
        
        -- Foreign Keys para Dimensões
        
        -- Dimensão de Data (Pickup e Dropoff) - usa DATE diretamente
        CAST(taxi.lpepPickupDatetime AS DATE) AS pickup_date_fk,
        CAST(taxi.lpepDropoffDatetime AS DATE) AS dropoff_date_fk,
        
        -- Dimensão de Tempo (Pickup e Dropoff) - TRUNCA para minutos inteiros
        CAST(
            DATEADD(
                MINUTE,
                DATEDIFF(MINUTE, 0, taxi.lpepPickupDatetime),
                0
            ) AS TIME(0)
        ) AS pickup_time_fk,
        CAST(
            DATEADD(
                MINUTE,
                DATEDIFF(MINUTE, 0, taxi.lpepDropoffDatetime),
                0
            ) AS TIME(0)
        ) AS dropoff_time_fk,
        
        -- Dimensão de Localização (Pickup e Dropoff) - USA SURROGATE KEY
        loc_pickup.sk_location_id AS pickup_location_fk,
        loc_dropoff.sk_location_id AS dropoff_location_fk,
        
        -- Dimensão de Fornecedor - usa natural key
        vendor.vendor_id AS vendor_fk,
        
        -- Dimensão de Tipo de Pagamento - usa natural key
        payment.payment_type AS payment_type_fk,
        
        -- Dimensão de Rate Code - usa natural key
        rate.rate_code_id AS rate_code_fk,
        
        -- Métricas da Viagem (Fatos/Medidas)
        taxi.fareAmount,
        taxi.extra,
        taxi.mtaTax,
        taxi.improvementSurcharge,
        taxi.tipAmount,
        taxi.tollsAmount,
        taxi.totalAmount,
        taxi.tripDistance,
        
        -- Atributos Descritivos (Degenerates)
        taxi.passengerCount,
        taxi.tripType,
        taxi.storeAndFwdFlag,
        
        -- Timestamps originais (para auditoria/análise temporal)
        taxi.lpepPickupDatetime,
        taxi.lpepDropoffDatetime,
        
        -- Cálculo de duração da viagem em minutos
        DATEDIFF(MINUTE, taxi.lpepPickupDatetime, taxi.lpepDropoffDatetime) AS trip_duration_minutes
        
    FROM stg_taxi taxi
    
    -- JOIN com Localização Pickup (usando surrogate key)
    LEFT JOIN int_location loc_pickup
        ON taxi.puLocationId = loc_pickup.location_id
    
    -- JOIN com Localização Dropoff (usando surrogate key)
    LEFT JOIN int_location loc_dropoff
        ON taxi.doLocationId = loc_dropoff.location_id
    
    -- JOIN com Vendor
    LEFT JOIN int_vendor vendor
        ON CAST(taxi."vendorID" AS INT) = vendor.vendor_id
    
    -- JOIN com Payment Type
    LEFT JOIN int_payment_type payment
        ON taxi.paymentType = payment.payment_type
    
    -- JOIN com Rate Code
    LEFT JOIN int_rate_code rate
        ON taxi.rateCodeID = rate.rate_code_id
)

SELECT
    -- Chave Primária
    trip_id,
    
    -- Foreign Keys
    pickup_date_fk,
    dropoff_date_fk,
    pickup_time_fk,
    dropoff_time_fk,
    pickup_location_fk,
    dropoff_location_fk,
    vendor_fk,
    payment_type_fk,
    rate_code_fk,
    
    -- Métricas
    fareAmount,
    extra,
    mtaTax,
    improvementSurcharge,
    tipAmount,
    tollsAmount,
    totalAmount,
    tripDistance,
    trip_duration_minutes,
    
    -- Atributos Descritivos
    passengerCount,
    tripType,
    storeAndFwdFlag,
    
    -- Timestamps originais
    lpepPickupDatetime,
    lpepDropoffDatetime
    
FROM fact_base
WHERE 
    -- Garantir que conseguimos fazer JOIN com as dimensões principais
    pickup_location_fk IS NOT NULL 
    AND dropoff_location_fk IS NOT NULL
    AND vendor_fk IS NOT NULL
