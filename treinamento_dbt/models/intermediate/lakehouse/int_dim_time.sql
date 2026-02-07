WITH ten_rows AS (
    SELECT 1 AS n UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL
    SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1
),
-- Gerar 1440 números (0 a 1439 minutos em um dia)
minute_series AS (
    SELECT TOP (1440) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS minute_offset
    FROM ten_rows a CROSS JOIN ten_rows b CROSS JOIN ten_rows c CROSS JOIN ten_rows d
),
raw_time AS (
    SELECT 
        DATEADD(MINUTE, minute_offset, CAST('00:00:00' AS TIME)) AS time_value
    FROM minute_series
)
SELECT 
    CAST(time_value AS TIME(0)) AS time, -- Chave Primária (precisão 0 = sem frações de segundo)
    DATEPART(HOUR, time_value) AS hour,
    DATEPART(MINUTE, time_value) AS minute,
    
    -- Formatação amigável
    CAST(FORMAT(CAST(time_value AS DATETIME), 'HH:mm') AS VARCHAR(5)) AS time_24h,
    
    -- Períodos do Dia (Essencial para análise de mobilidade)
    CASE 
        WHEN DATEPART(HOUR, time_value) BETWEEN 0 AND 5 THEN 'Madrugada'
        WHEN DATEPART(HOUR, time_value) BETWEEN 6 AND 11 THEN 'Manhã'
        WHEN DATEPART(HOUR, time_value) BETWEEN 12 AND 17 THEN 'Tarde'
        ELSE 'Noite'
    END AS period_of_day,

    -- Flags de Horário de Pico (Rush Hour - Adaptar conforme regra de NY)
    CASE 
        WHEN (DATEPART(HOUR, time_value) BETWEEN 7 AND 9) OR (DATEPART(HOUR, time_value) BETWEEN 16 AND 19) 
        THEN 1 ELSE 0 
    END AS is_rush_hour

FROM raw_time