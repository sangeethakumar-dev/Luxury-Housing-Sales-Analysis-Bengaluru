SELECT COUNT(*) FROM luxury_housing;

SELECT * FROM luxury_housing
LIMIT 10;

--Recreating table with optimized SQL schema and corrected data types.

DROP TABLE IF EXISTS luxury_housing;

CREATE TABLE luxury_housing (
    property_id VARCHAR(20) PRIMARY KEY,
    micro_market VARCHAR(100),
    project_name VARCHAR(100),
    developer_name VARCHAR(100),

    unit_size_sqft NUMERIC(8,2),
    configuration VARCHAR(20),
    ticket_price_cr NUMERIC(10,2),

    transaction_type VARCHAR(20),
    buyer_type VARCHAR(20),
    purchase_quarter DATE,

    connectivity_score NUMERIC(4,2),
    amenity_score NUMERIC(4,2),

    possession_status VARCHAR(30),
    sales_channel VARCHAR(30),
    nri_buyer BOOLEAN,

    locality_infra_score NUMERIC(4,2),
    avg_traffic_time_min INTEGER,

    buyer_comments TEXT
);


--Initial Health Check of my data

--head()

SELECT *FROM luxury_housing
LIMIT 5;

--sample()

SELECT *FROM luxury_housing
ORDER BY RANDOM()
LIMIT 5;

--tail()

SELECT *FROM luxury_housing
ORDER BY "Ticket_Price_Cr" DESC, "Purchase_Quarter" DESC
LIMIT 5;

--get uniques Micro_Market

SELECT DISTINCT "Micro_Market"
FROM luxury_housing;

--get the total number of unique states

SELECT COUNT(DISTINCT "Micro_Market") AS unique_Market_Count
FROM luxury_housing;

--yes there are 16 Micro_Markets  in total

--To check no. of rows(df.shape())

SELECT COUNT(*) FROM luxury_housing;

--get number of each unique Micro_Market

SELECT "Micro_Market", COUNT(*)
FROM luxury_housing
GROUP BY "Micro_Market";

--get number of each "Developer_Name"

SELECT "Developer_Name", COUNT(*)
FROM luxury_housing
GROUP BY "Developer_Name";

--Checking null values

SELECT COUNT(*) FROM luxury_housing
WHERE "Property_ID" is NULL;

--OVERALL inspection

SELECT COUNT(*) AS total_rows,
COUNT(DISTINCT "Micro_Market") AS Developer_Names,
MIN("Ticket_Price_Cr") AS min_price,
MAX("Ticket_Price_Cr") AS max_price
FROM luxury_housing;

--column_names

SELECT column_name,data_type
FROM information_schema.columns
WHERE table_name = 'luxury_housing';

--Power BI Visualization Questions

--1.Market Trends:-
--How have luxury housing bookings changed quarter by quarter across micro-markets?

SELECT "Quarter_Number","Micro_Market",
COUNT(*) AS booking_count
FROM luxury_housing
GROUP BY "Micro_Market","Quarter_Number"
ORDER BY "booking_count" DESC;

--Bookings appear relatively stable across quarters, with only minor fluctuations, suggesting no strong seasonal trend in luxury housing demand.

--lets compare average of booking count also to prove it statistically

SELECT "Quarter_Number",
ROUND(AVG("booking_count"),2) AS avg_booking_count
FROM (
SELECT "Quarter_Number","Micro_Market", COUNT(*) AS booking_count
FROM luxury_housing
GROUP BY "Micro_Market","Quarter_Number"
)
GROUP BY "Quarter_Number"
ORDER BY "Quarter_Number";

--Average bookings across quarters remain nearly constant (~1560), with less than 1% variation, indicating that luxury housing demand does not exhibit strong seasonal trends.

--2.Builder Performance
--Which builders have the highest total ticket sales and how do they rank in terms of average ticket size?

--Builers having highest total ticket sales

SELECT "Developer_Name",ROUND(SUM("Ticket_Price_Cr")::numeric,2) as total_sales
FROM luxury_housing
GROUP BY "Developer_Name"
ORDER BY total_sales DESC
LIMIT 5;

--Ranking Builders based on average ticket size

SELECT "Developer_Name",ROUND(AVG("Ticket_Price_Cr")::numeric,2) AS avg_sales,
DENSE_RANK() OVER (ORDER BY AVG("Ticket_Price_Cr") DESC) AS rank
FROM luxury_housing
GROUP BY "Developer_Name"
ORDER BY rank;

--Prestige, Total Environment, and L&T Realty lead in total sales value, indicating strong overall market capture and transaction volume.
--However, Sobha and Total Environment rank highest in average ticket size, suggesting a stronger premium positioning with higher-priced luxury offerings per unit.

--Query for having both sum(Ticket_Price_Cr) and avg("Ticket_Price_Cr") in one table for Power BI

SELECT "Developer_Name",
ROUND(SUM("Ticket_Price_Cr")::numeric,2) as sum_total_sales,
ROUND(AVG("Ticket_Price_Cr")::numeric,2) AS avg_total_sales
FROM luxury_housing
GROUP BY "Developer_Name";

--3.Amenity Impact
--Is there a correlation between amenity score and booking success rate?

SELECT ROUND("Amenity_Score"::numeric,1) AS amenity_bucket,
ROUND(AVG("Booking_Flag"):: numeric,3) AS booking_conversion_rate,
COUNT(*) AS project_count
FROM luxury_housing
GROUP BY "amenity_bucket"
ORDER BY "amenity_bucket";


--4.Booking Conversion
--Which micro-markets have the highest and lowest booking conversion rates?

SELECT "Micro_Market",ROUND(AVG("Booking_Flag"):: numeric,3) AS booking_conversion_rate
FROM luxury_housing
GROUP BY "Micro_Market"
ORDER BY booking_conversion_rate DESC;

--INSIGHT --Conversion rates across micro-markets are very close (33–34%), indicating relatively uniform booking performance across locations, with Electronic City slightly leading.

--Query for Visualizing Stacked Column Chart in Power BI

SELECT "Micro_Market",
"Booking_Flag",
COUNT(*) AS count
FROM luxury_housing
GROUP BY "Micro_Market",
"Booking_Flag";


--5.Configuration Demand
--What are the most in-demand housing configurations (e.g., 3BHK, 4BHK)?

SELECT "Configuration",SUM("Booking_Flag") AS booking_count
FROM luxury_housing
GROUP BY "Configuration"
ORDER BY booking_count DESC;

--INSIGHT -- Demand is fairly balanced across 3BHK, 4BHK, and 5BHK+, with 3BHK slightly leading, suggesting strong mid-segment luxury demand.

--6.Sales Channel Efficiency
--Which sales channels contribute most to successful bookings?

SELECT "Sales_Channel", SUM("Booking_Flag") AS total_successful_bookings
FROM luxury_housing
WHERE "Booking_Flag" = 1
GROUP BY "Sales_Channel"
ORDER BY total_successful_bookings DESC;

--INSIGHT --Broker channel slightly leads in successful bookings, but overall contribution across all channels is relatively balanced, indicating no single dominant sales channel.

--Query for Visualizing Stacked Column Chart in Power BI

SELECT "Sales_Channel",
"Booking_Flag",
COUNT(*) AS _count
FROM luxury_housing
GROUP BY "Sales_Channel","Booking_Flag";

--7.Quarterly Builder Contribution
--Which builders dominate the market each quarter?

--(Query apt for Power BI VIsualization)

SELECT "Developer_Name","Quarter_Number",ROUND(SUM("Ticket_Price_Cr"):: numeric,2) AS total_value
FROM luxury_housing
GROUP BY "Developer_Name","Quarter_Number"
ORDER BY total_value DESC;

--Ranking Builders in each Quarter

WITH quarterly_sales AS (
SELECT "Developer_Name","Quarter_Number",ROUND(SUM("Ticket_Price_Cr"):: numeric,2) AS total_value
FROM luxury_housing
GROUP BY "Developer_Name","Quarter_Number"
)

SELECT "Quarter_Number","Developer_Name","total_value"
FROM (
SELECT *,
DENSE_RANK() OVER (PARTITION BY "Quarter_Number" ORDER BY total_value) AS q_rank
FROM quarterly_sales
)
WHERE q_rank = 1
ORDER BY "total_value" DESC ;

--INSIGHT --Market leadership varies across quarters, with Tata Housing dominating multiple quarters, while Embassy and SNN Raj lead specific quarters, indicating competitive seasonal performance among builders.


--8.Possession Status Analysis
--How does possession status affect buyer type and booking decisions?

--Query apt for visualizing in Power BI

SELECT "Possession_Status","Buyer_Type","Booking_Flag",
COUNT(*) AS projects_count
FROM luxury_housing
GROUP BY "Possession_Status","Buyer_Type","Booking_Flag"
ORDER BY projects_count DESC;

--Analysis Query

SELECT "Possession_Status","Buyer_Type",
ROUND(COUNT(*)*100/SUM(COUNT(*)) OVER (PARTITION BY "Possession_Status"),2) AS percentage_share
FROM luxury_housing
GROUP BY "Possession_Status","Buyer_Type";

--INSIGHT --Buyer composition is nearly identical across launch, under-construction, and ready-to-move properties, suggesting no dominant buyer segment preference for any possession stage.


--9.Geographical Insights
--Where are most luxury housing projects concentrated within Bangalore?

SELECT "Micro_Market",COUNT(*) AS total_property_counts
FROM luxury_housing
GROUP BY "Micro_Market"
ORDER BY total_property_counts DESC;

--INSIGHT --Luxury housing projects are fairly evenly distributed across major Bangalore micro-markets, with Jayanagar and Bannerghatta Road showing only marginally higher concentrations. This indicates a balanced geographic supply rather than a single dominant luxury hub

--10.Top Performers
--Who are the top 5 builders in terms of revenue and booking success?

SELECT "Developer_Name",ROUND(SUM("Ticket_Price_Cr")::numeric,2) AS total_revenue, 
SUM("Booking_Flag") AS booking_success_count
FROM luxury_housing
GROUP BY "Developer_Name"
ORDER BY total_revenue DESC,booking_success_count DESC
LIMIT 5;

--INSIGHT --Prestige dominates in revenue generation, whereas SNN Raj leads in booking conversions, highlighting different strengths among top builders.

