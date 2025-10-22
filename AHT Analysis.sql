CREATE DATABASE AHT_Analysis;

USE AHT_Analysis;

CREATE TABLE Fact_AHT (
	MonthName NVARCHAR(50),
	WeekName NVARCHAR(50),
	Date DATE NOT NULL,
	DateFrom DATE NOT NULL,
	DateTo DATE NOT NULL,
	Employee NVARCHAR(100) NOT NULL,
	SkillID INT NOT NULL,
	Calls INT NOT NULL,
	TotalHandlingTime DECIMAL(18,2) NOT NULL,
	AHT DECIMAL(18,2) NOT NULL,
	TotalHandlingTime_Goal DECIMAL(18,2) NOT NULL,
	AHTGOAL DECIMAL(18,2) NOT NULL
)

BULK INSERT Fact_AHT
FROM 'C:\Users\nikostzam\Desktop\SQL\SQL AHT\AHT_data.csv'
WITH (
	FIRSTROW =2,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n',
	TABLOCK,
	CODEPAGE = '65001',
	KEEPIDENTITY
);

ALTER TABLE Fact_AHT
ADD ID_Key INT IDENTITY (1,1)

ALTER TABLE Fact_AHT
ADD CONSTRAINT PK_Fact_AHT PRIMARY KEY (ID_Key);

SELECT * FROM Fact_AHT

--CALCULATE DYNAMIC AHT GOAL BASED ON MEDIAN VALUE OF EACH SKILL ID
SELECT SkillID,
	   Employee,
	   SUM(TotalHandlingTime)/SUM(Calls) as AHT,
	   PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY SUM(TotalHandlingTime)/SUM(Calls)) OVER (PARTITION BY SkillID) AS Median_AHT_Goal
FROM Fact_AHT
GROUP BY Employee, SkillID, Calls
ORDER BY SkillID, AHT, Employee;

--CHECK EACH AGENTS PERFORMANCE BASED ON DYNAMIC GOAL
WITH aht_target AS (
	SELECT SkillID,
	   Employee,
	   SUM(TotalHandlingTime)/SUM(Calls) as AHT,
	   PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY SUM(TotalHandlingTime)/SUM(Calls)) OVER (PARTITION BY SkillID) AS Median_AHT_Goal
FROM Fact_AHT
GROUP BY Employee, SkillID, Calls
)
SELECT DISTINCT SkillID, Median_AHT_Goal FROM aht_target;


--Creating Attainment KPI for AHT Performance Over Dynamic AHT Goal

WITH BaseData AS (
    SELECT
        *,
        AHTGOAL / AHT AS AHT_Attainment,
        SUM(TotalHandlingTime_Goal) OVER (PARTITION BY WeekName) / 
            SUM(TotalHandlingTime) OVER (PARTITION BY WeekName) AS [AHT Attainment_WeeklyPerSkill],
        SUM(TotalHandlingTime_Goal) OVER (PARTITION BY WeekName, Employee) / 
            SUM(TotalHandlingTime) OVER (PARTITION BY WeekName, Employee) AS AHTATT,
        SUM(TotalHandlingTime_Goal) OVER (PARTITION BY MonthName, Employee) / 
            SUM(TotalHandlingTime) OVER (PARTITION BY MonthName, Employee) AS AHT_Attainment_Month
    FROM Fact_AHT
),
IQRCalc AS (
    SELECT 
        *,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY AHTATT) 
            OVER (PARTITION BY MonthName) AS Q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY AHTATT) 
            OVER (PARTITION BY MonthName) AS Q3
    FROM BaseData
),
FilteredData AS(
	SELECT *,
		   (Q3-Q1) AS IQR,
		   (Q3 + 1.5 * (Q3-Q1)) AS UpperBound,
		   (Q1 - 1.5 * (Q3-Q1)) AS LowerBound
	FROM IQRCalc
),
OutlierFilteredData AS(
	SELECT *
	FROM FilteredData
	WHERE AHTATT BETWEEN LowerBound AND UpperBound
), 
StatCalc AS(
SELECT DISTINCT MonthName,
	   DATEADD(MONTH, 1 , DateFrom) AS DateFrom,
	   DATEADD(MONTH, 1 , DateTo) AS DateTo,
	   AVG(AHTATT) OVER (PARTITION BY MonthName) AS MeanATT,
	   STDEV(AHTATT) OVER (PARTITION BY [MonthName]) AS StdDevATT,
	   STDEV(AHTATT) OVER (PARTITION BY [MonthName])*6 as VSF,
	    Case when STDEV(AHTATT) OVER (PARTITION BY [MonthName])*6 >= 1 then
		AVG(AHTATT) OVER (PARTITION BY [MonthName]) - STDEV(AHTATT) OVER (PARTITION BY [MonthName])*2
		else AVG(AHTATT) OVER (PARTITION BY [MonthName]) - STDEV(AHTATT) OVER (PARTITION BY [MonthName])
		end as LSS,
		Case when STDEV(AHTATT) OVER (PARTITION BY [MonthName])*6 >= 1 then
		AVG(AHTATT) OVER (PARTITION BY [MonthName]) + STDEV(AHTATT) OVER (PARTITION BY [MonthName])*2
		else AVG(AHTATT) OVER (PARTITION BY [MonthName]) + STDEV(AHTATT) OVER (PARTITION BY [MonthName])
		end as USS
FROM OutlierFilteredData
),
new_target AS (
    SELECT DISTINCT 
        b.[MonthName] AS [ResultMonth],
        s.DateFrom,
        s.DateTo,
        b.Employee,
        CASE   
            WHEN AHT_Attainment_Month > 0.95 THEN NULL
            WHEN AHT_Attainment_Month <= LSS THEN  
                (1 - (CASE WHEN MeanATT - AHT_Attainment_Month >= 0.3 
                           THEN 0.3 
                           ELSE MeanATT - AHT_Attainment_Month END)) * AHT
            WHEN AHT_Attainment_Month BETWEEN LSS AND MeanATT THEN 
                (1 - (CASE WHEN ((1 - MeanATT)/2) + (MeanATT - AHT_Attainment_Month) >= 0.15 
                           THEN 0.15 
                           ELSE ((1 - MeanATT)/2) + (MeanATT - AHT_Attainment_Month) END)) * AHT
            WHEN [AHT_Attainment] BETWEEN MeanATT AND 0.95 THEN 
                (1 - (CASE WHEN (1 - AHT_Attainment_Month) >= 0.05 
                           THEN 0.05 
                           ELSE (1 - AHT_Attainment_Month) END)) * AHT
            ELSE NULL 
        END AS [NewTarget],
        CASE 
            WHEN AHT_Attainment_Month > 0.95 THEN NULL
            WHEN AHT_Attainment_Month <= LSS THEN  
                (CASE WHEN MeanATT - AHT_Attainment_Month >= 0.3 
                      THEN 0.3 
                      ELSE MeanATT - AHT_Attainment_Month END)
            WHEN AHT_Attainment_Month BETWEEN LSS AND MeanATT THEN 
                (CASE WHEN ((1 - MeanATT)/2) + (MeanATT - AHT_Attainment_Month) >= 0.15 
                      THEN 0.15 
                      ELSE ((1 - MeanATT)/2) + (MeanATT - AHT_Attainment_Month) END)
            WHEN [AHT_Attainment] BETWEEN MeanATT AND 0.95 THEN 
                (CASE WHEN (1 - AHT_Attainment_Month) >= 0.05 
                      THEN 0.05 
                      ELSE (1 - AHT_Attainment_Month) END)
            ELSE NULL 
        END AS [Target Reduction],
        DENSE_RANK() OVER (PARTITION BY b.[MonthName] ORDER BY AHT_Attainment_Month) AS [Reverse_PerformanceRank]
    FROM OutlierFilteredData AS b
    LEFT JOIN StatCalc AS s 
        ON s.[MonthName] = b.[MonthName]
)
Select [Date]
 ,c.[Employee]
 ,SkillID
 ,Calls
 ,TotalHandlingTime
 ,AHT
 ,[TotalHandlingTime_Goal]
 ,AHTGoal
 ,Reverse_PerformanceRank
 ,[NewTarget]
 ,[Target Reduction]
 From Fact_AHT as c
 left join new_target as n on n.Employee = c.Employee and c.[Date] between n.DateFrom and n.DateTo;