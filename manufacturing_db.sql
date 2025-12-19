USE mysql;
DROP DATABASE manufacturing_db;
-- 1. CREATE DATABASE

CREATE DATABASE manufacturing_db;
USE manufacturing_db;

-- 2. CREATE TABLE STRUCTURE 

CREATE TABLE manufacturing_kpi (
    ProductionVolume        DOUBLE,
    ProductionCost          DOUBLE,
    SupplierQuality         DOUBLE,
    DeliveryDelay           DOUBLE,
    DefectRate              DOUBLE,
    QualityScore            DOUBLE,
    MaintenanceHours        DOUBLE,
    DowntimePercentage      DOUBLE,
    InventoryTurnover       DOUBLE,
    StockoutRate            DOUBLE,
    WorkerProductivity      DOUBLE,
    SafetyIncidents         DOUBLE,
    EnergyConsumption       DOUBLE,
    EnergyEfficiency        DOUBLE,
    AdditiveProcessTime     DOUBLE,
    AdditiveMaterialCost    DOUBLE,
    DefectStatus            INT,
    PredictedDefect         INT
);

-- 3. LOAD CSV DATA

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/defect_predictions.csv'
INTO TABLE manufacturing_kpi
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 4. DATA UNDERSTANDING

SELECT * FROM manufacturing_kpi LIMIT 10;

SELECT COUNT(*) AS total_rows FROM manufacturing_kpi;

SELECT
    MIN(DefectRate) AS min_defect,
    MAX(DefectRate) AS max_defect,
    AVG(DefectRate) AS avg_defect,
    STD(DefectRate) AS std_defect
FROM manufacturing_kpi;

SELECT 
    SUM(ProductionVolume IS NULL) AS null_volume,
    SUM(ProductionCost IS NULL) AS null_cost,
    SUM(SupplierQuality IS NULL) AS null_supplier
FROM manufacturing_kpi;

-- 5. DATA CLEANING 

SET SQL_SAFE_UPDATES = 0;

-- Replace negative costs
UPDATE manufacturing_kpi
SET ProductionCost = NULL
WHERE ProductionCost < 0;

-- Fill NULL ProductionCost using derived table
UPDATE manufacturing_kpi
SET ProductionCost = (
    SELECT avg_cost FROM (
        SELECT AVG(ProductionCost) AS avg_cost
        FROM manufacturing_kpi
    ) AS temp
)
WHERE ProductionCost IS NULL;

-- Fill NULL SupplierQuality using derived table
UPDATE manufacturing_kpi
SET SupplierQuality = (
    SELECT avg_sup FROM (
        SELECT AVG(SupplierQuality) AS avg_sup
        FROM manufacturing_kpi
    ) AS temp2
)
WHERE SupplierQuality IS NULL;

SET SQL_SAFE_UPDATES = 1;

-- 6. KPI CALCULATIONS

SELECT AVG(DefectStatus) * 100 AS overall_defect_rate
FROM manufacturing_kpi;

SELECT
    AVG(WorkerProductivity) AS avg_worker_productivity,
    AVG(EnergyEfficiency) AS avg_energy_efficiency,
    AVG(QualityScore) AS avg_quality_score
FROM manufacturing_kpi;

SELECT AVG(ProductionCost) AS avg_production_cost FROM manufacturing_kpi;

-- 7. SQL-BASED EDA

-- Supplier impact
SELECT SupplierQuality,
       AVG(DefectStatus) AS defect_probability
FROM manufacturing_kpi
GROUP BY SupplierQuality
ORDER BY defect_probability DESC;

-- Downtime impact
SELECT DowntimePercentage,
       AVG(DefectRate) AS avg_defect_rate
FROM manufacturing_kpi
GROUP BY DowntimePercentage
ORDER BY avg_defect_rate DESC;

-- High-risk predicted batches
SELECT *
FROM manufacturing_kpi
WHERE PredictedDefect = 1
ORDER BY DefectRate DESC
LIMIT 10;

-- Most costly defective batches
SELECT ProductionVolume, ProductionCost, DefectRate
FROM manufacturing_kpi
WHERE DefectStatus = 1
ORDER BY ProductionCost DESC
LIMIT 10;

-- 8. WINDOW FUNCTIONS 

SELECT 
    SupplierQuality,
    AVG(DefectStatus) AS avg_defect,
    RANK() OVER (ORDER BY AVG(DefectStatus) DESC) AS defect_rank
FROM manufacturing_kpi
GROUP BY SupplierQuality;

-- 9. CONFUSION MATRIX (MODEL PERFORMANCE)

SELECT COUNT(*) AS TruePositives
FROM manufacturing_kpi
WHERE DefectStatus = 1 AND PredictedDefect = 1;

SELECT COUNT(*) AS TrueNegatives
FROM manufacturing_kpi
WHERE DefectStatus = 0 AND PredictedDefect = 0;

SELECT COUNT(*) AS FalsePositives
FROM manufacturing_kpi
WHERE DefectStatus = 0 AND PredictedDefect = 1;

SELECT COUNT(*) AS FalseNegatives
FROM manufacturing_kpi
WHERE DefectStatus = 1 AND PredictedDefect = 0;

SELECT 
    (SUM(DefectStatus = PredictedDefect) / COUNT(*)) AS accuracy
FROM manufacturing_kpi;

-- 10. ROOT CAUSE ANALYSIS

SELECT
    SupplierQuality,
    DeliveryDelay,
    DowntimePercentage,
    EnergyEfficiency,
    AVG(DefectStatus) AS defect_probability
FROM manufacturing_kpi
GROUP BY SupplierQuality, DeliveryDelay, DowntimePercentage, EnergyEfficiency
ORDER BY defect_probability DESC
LIMIT 20;

SELECT 
    CASE 
        WHEN DowntimePercentage < 10 THEN '0-10'
        WHEN DowntimePercentage < 20 THEN '10-20'
        WHEN DowntimePercentage < 30 THEN '20-30'
        ELSE '30+'
    END AS downtime_group,
    AVG(DefectRate) AS avg_defect_rate
FROM manufacturing_kpi
GROUP BY downtime_group
ORDER BY avg_defect_rate DESC;

-- 11. FINAL EXECUTIVE SUMMARY

SELECT
    AVG(ProductionVolume) AS avg_volume,
    AVG(ProductionCost) AS avg_cost,
    AVG(SupplierQuality) AS avg_supplier_quality,
    AVG(DowntimePercentage) AS avg_downtime,
    AVG(DefectRate) AS avg_defect_rate,
    SUM(DefectStatus) AS total_defects
FROM manufacturing_kpi;












	






































