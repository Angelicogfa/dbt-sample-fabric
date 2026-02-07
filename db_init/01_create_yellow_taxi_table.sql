-- =====================================================
-- Script: 01_create_yellow_taxi_table.sql
-- Descrição: Criação da tabela Yellow Taxi Trip Records (2013)
-- Baseado em: NYC TLC Official Parquet Schema
-- Fonte: https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page
-- =====================================================

USE DataWarehouseTreinamento;
GO

-- Drop table if exists
IF OBJECT_ID('dbo.YellowTaxiTrips', 'U') IS NOT NULL 
    DROP TABLE dbo.YellowTaxiTrips;
GO

PRINT 'Creating table: dbo.YellowTaxiTrips';

CREATE TABLE [dbo].[YellowTaxiTrips]
(
    -- Vendor Information
    [VendorID] INT NULL,
    
    -- Trip Times
    [tpep_pickup_datetime] DATETIME2 NOT NULL,
    [tpep_dropoff_datetime] DATETIME2 NOT NULL,
    
    -- Passenger Count
    [passenger_count] INT NULL,
    
    -- Trip Distance
    [trip_distance] FLOAT NULL,
    
    -- Location IDs (TLC Taxi Zones)
    [PULocationID] INT NULL,
    [DOLocationID] INT NULL,
    
    -- Rate Information
    [RatecodeID] INT NULL,
    
    -- Store and Forward Flag
    [store_and_fwd_flag] VARCHAR(1) NULL,
    
    -- Payment Information
    [payment_type] INT NULL,
    
    -- Fare Breakdown
    [fare_amount] DECIMAL(10,2) NULL,
    [extra] DECIMAL(10,2) NULL,
    [mta_tax] DECIMAL(10,2) NULL,
    [tip_amount] DECIMAL(10,2) NULL,
    [tolls_amount] DECIMAL(10,2) NULL,
    [improvement_surcharge] DECIMAL(10,2) NULL,
    [total_amount] DECIMAL(10,2) NULL,
    
    -- Metadata
    [load_date] DATETIME2 DEFAULT GETDATE(),
    [source_file] VARCHAR(100) NULL
)
WITH (
    -- Clustered Columnstore for analytics performance
    CLUSTERED COLUMNSTORE INDEX
);
GO

PRINT 'Table created successfully!';
PRINT '';
PRINT 'Column Summary:';
PRINT '  - VendorID: TPEP provider (1=Creative Mobile, 2=VeriFone)';
PRINT '  - tpep_pickup_datetime: Meter engagement time';
PRINT '  - tpep_dropoff_datetime: Meter disengagement time';
PRINT '  - passenger_count: Number of passengers';
PRINT '  - trip_distance: Distance in miles';
PRINT '  - PULocationID: Pick-up TLC Taxi Zone';
PRINT '  - DOLocationID: Drop-off TLC Taxi Zone';
PRINT '  - RatecodeID: Rate code (1=Standard, 2=JFK, 3=Newark, etc.)';
PRINT '  - store_and_fwd_flag: Y=stored in memory, N=not stored';
PRINT '  - payment_type: 1=Credit, 2=Cash, 3=No charge, 4=Dispute, 5=Unknown';
PRINT '  - fare_amount: Time-and-distance fare';
PRINT '  - extra: Miscellaneous extras';
PRINT '  - mta_tax: MTA tax';
PRINT '  - tip_amount: Tip (credit card only)';
PRINT '  - tolls_amount: Total tolls';
PRINT '  - improvement_surcharge: Improvement surcharge';
PRINT '  - total_amount: Total charged to passenger';
GO
