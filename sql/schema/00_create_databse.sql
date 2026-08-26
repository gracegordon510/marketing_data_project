/*==============================================================================
    File: 00_create_database.sql
    Purpose: Create the Marketing Analytics database.
==============================================================================*/
USE master;
GO

IF DB_ID('marketing_analytics') IS NULL
BEGIN
    CREATE DATABASE marketing_analytics;
END;
GO

USE marketing_analytics;
GO