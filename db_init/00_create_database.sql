-- =====================================================
-- Script: 00_create_database.sql
-- Descrição: Criação do database DataWarehouseTreinamento
-- =====================================================

IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'DataWarehouseTreinamento')
BEGIN
    PRINT 'Creating database DataWarehouseTreinamento...';
    CREATE DATABASE DataWarehouseTreinamento;
END
ELSE
BEGIN
    PRINT 'Database DataWarehouseTreinamento already exists.';
END
GO
