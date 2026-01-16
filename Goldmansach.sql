-- 1. Company Table (Metadata)
CREATE TABLE Company (
    CompanyID INT PRIMARY KEY,
    Symbol VARCHAR(10),
    CompanyName VARCHAR(100)
);
INSERT INTO Company VALUES (1, 'GS', 'Goldman Sachs Group Inc.');

-- 2. Market Calendar (Time Dimension)
CREATE TABLE Market_Calendar (
    DateKey DATE PRIMARY KEY,
    Year INT,
    Month INT,
    Day INT,
    Quarter INT,
    DayOfWeek VARCHAR(15)
);
INSERT INTO Market_Calendar VALUES ('1999-05-04', 1999, 5, 4, 2, 'Tuesday');
INSERT INTO Market_Calendar VALUES ('1999-05-05', 1999, 5, 5, 2, 'Wednesday');
INSERT INTO Market_Calendar VALUES ('1999-05-06', 1999, 5, 6, 2, 'Thursday');
INSERT INTO Market_Calendar VALUES ('1999-05-07', 1999, 5, 7, 2, 'Friday');
INSERT INTO Market_Calendar VALUES ('1999-05-10', 1999, 5, 10, 2, 'Monday');

-- 3. Daily Trading (Core Fact Table)
CREATE TABLE Daily_Trading (
    TradeID INT PRIMARY KEY,
    DateKey DATE,
    OpenPrice FLOAT,
    ClosePrice FLOAT,
    FOREIGN KEY (DateKey) REFERENCES Market_Calendar(DateKey)
);
INSERT INTO Daily_Trading VALUES (1, '1999-05-04', 48.696, 70.000);
INSERT INTO Daily_Trading VALUES (2, '1999-05-05', 47.831, 66.250);
INSERT INTO Daily_Trading VALUES (3, '1999-05-06', 47.009, 67.062);
INSERT INTO Daily_Trading VALUES (4, '1999-05-07', 51.291, 66.750);
INSERT INTO Daily_Trading VALUES (5, '1999-05-10', 48.912, 70.250);

-- 4. Price High Low (Specific metrics)
CREATE TABLE Price_High_Low (
    TradeID INT PRIMARY KEY,
    HighPrice FLOAT,
    LowPrice FLOAT,
    FOREIGN KEY (TradeID) REFERENCES Daily_Trading(TradeID)
);
INSERT INTO Price_High_Low VALUES (1, 70.375, 77.250);
INSERT INTO Price_High_Low VALUES (2, 69.125, 69.875);
INSERT INTO Price_High_Low VALUES (3, 67.937, 69.375);
INSERT INTO Price_High_Low VALUES (4, 74.125, 74.875);
INSERT INTO Price_High_Low VALUES (5, 70.687, 73.500);

-- 5. Trading Volume
CREATE TABLE Trading_Volume (
    TradeID INT PRIMARY KEY,
    Volume BIGINT,
    FOREIGN KEY (TradeID) REFERENCES Daily_Trading(TradeID)
);
INSERT INTO Trading_Volume VALUES (1, 22320900);
INSERT INTO Trading_Volume VALUES (2, 7565700);
INSERT INTO Trading_Volume VALUES (3, 2905700);
INSERT INTO Trading_Volume VALUES (4, 4862300);
INSERT INTO Trading_Volume VALUES (5, 2589400);

-- 6. Adjusted Valuation
CREATE TABLE Adjusted_Valuation (
    TradeID INT PRIMARY KEY,
    Adj_Close FLOAT,
    FOREIGN KEY (TradeID) REFERENCES Daily_Trading(TradeID)
);
INSERT INTO Adjusted_Valuation VALUES (1, 76.000);
INSERT INTO Adjusted_Valuation VALUES (2, 69.875);
INSERT INTO Adjusted_Valuation VALUES (3, 68.000);
INSERT INTO Adjusted_Valuation VALUES (4, 67.937);
INSERT INTO Adjusted_Valuation VALUES (5, 73.375);

-- 7. Performance Insights (Derived Metrics)
CREATE TABLE Performance_Insights (
    TradeID INT PRIMARY KEY,
    Daily_Change FLOAT,
    Direction VARCHAR(10),
    FOREIGN KEY (TradeID) REFERENCES Daily_Trading(TradeID)
);
INSERT INTO Performance_Insights VALUES (1, 21.304, 'Up');
INSERT INTO Performance_Insights VALUES (2, 18.419, 'Up');
INSERT INTO Performance_Insights VALUES (3, 20.053, 'Up');
INSERT INTO Performance_Insights VALUES (4, 15.459, 'Up');
INSERT INTO Performance_Insights VALUES (5, 21.338, 'Up');

--Join & Volatility: Combine Daily_Trading and Price_High_Low to find the top 5 dates 
--with the highest "Intraday Range" (High - Low).
select top 2 ClosePrice,DateKey,AVG(HighPrice) as High_price,AVG(LowPrice)as Low_price
--(AVG(HighPrice)- AVG(LowPrice)) as  price spread
from Daily_Trading as dt
INNER JOIN
Price_High_Low as pl
ON
dt.TradeID=pl.TradeID
GROUP BY DateKey,HighPrice,LowPrice,ClosePrice
HAVING (AVG(Highprice) - AVG (Lowprice) )<0;

SELECT * FROM Price_High_Low

--Date Filtering: Use the Market_Calendar table to find the average ClosePrice specifically
--for all Mondays in the dataset.
SELECT mc.DateKey,[DayOfWeek],AVg(ClosePrice)as Close_price
FROM Market_Calendar as mc
INNER JOIN
Daily_Trading AS dt
ON
mc.DateKey=Dt.DateKey
WHERE [DayOfWeek]= 'Monday'
GROUP BY mc.DateKey,[DayOfWeek],ClosePrice


--Volume vs Performance: Join Trading_Volume with Performance_Insights. List the dates 
--where the Volume was over 10 million and the Direction was 'Down'.
SELECT Volume,MC.DateKey,Direction FROM Trading_Volume AS TV
INNER JOIN
Price_High_Low AS Pl
ON
TV.TradeID =PL.TradeID
INNER JOIN
Daily_Trading AS DT
ON
PL.TradeID=DT.TradeID
INNER JOIN
Market_Calendar AS MC
ON
MC.DateKey=DT.DateKey
INNER JOIN
Performance_Insights AS PS
ON
DT.TradeID=PS.TradeID
WHERE Volume>=10000000 AND Direction='up'

--Quarterly Aggregation: Group by the Quarter column in the Market_Calendar table to find 
--the total volume traded in Q1 vs Q4 across all years.
--SELECT * FROM Company
--SELECT * FROM Market_Calendar
SELECT Volume,[year],[Quarter] FROM Trading_volume as Tv
INNER JOIN
Price_High_Low AS Pl
ON
TV.TradeID=pl.TradeID
INNER JOIN
Daily_Trading AS DT
ON
DT.TradeID=PL.TradeID
INNER JOIN
Market_Calendar AS MC
DT.DateKey=MC.DateKey
--------------------------------------------------------------------------------------------------------x
--Subqueries:Find all trades where the ClosePrice was higher than the 
--overall average ClosePrice of the entire Daily_Trading table.
WITH AVGCTE AS(
SELECT top 1 Avg(ClosePrice)as Daily_Trad ,TradeID from Daily_trading 
GROUP BY TradeID,ClosePrice
)
SELECT a.Daily_Trad,g.ClosePrice FROM Daily_Trading as g,AVGCTE a  
WHERE g.ClosePrice > a.Daily_Trad
--------------------------------------------------------------------------------
--SECOND WAYS:-

SELECT DateKey,ClosePrice FROM Daily_Trading
WHERE ClosePrice > (select avg(ClosePrice) FROM Daily_Trading)

--Case Logic: Write a query that selects DateKey and ClosePrice, and adds a column
--"Price_Category": 'High' if > $300, 'Medium' if between $150-$300, and 'Low' otherwise.
SELECT DateKey,ClosePrice,
CASE
WHEN ClosePrice < 30 THEN 'HIGH'
WHEN ClosePrice BETWEEN 60  AND 68 THEN 'Medium'
ELSE 'Low'
END AS Price_Category
 FROM Daily_Trading;

--Monthly Highs: Find the single highest HighPrice recorded for each Month (1 through 12) across the whole history.
SELECT TOP 1 ClosePrice, [Month] FROM Market_Calendar as Mc
INNER JOIN
Daily_Trading as Dt
ON
Mc.DateKey=Dt.DateKey

--Calculate the average Adj_Close for the year 1999 vs the year 2024.
SELECT Avg(Adj_Close) as AC FROM Adjusted_Valuation
