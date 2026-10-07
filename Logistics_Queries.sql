SELECT COUNT(*) FROM dbo.DataCoSupplyChainDataset;

CREATE OR ALTER VIEW dbo.logistics AS
SELECT Order_Id, Order_Item_Id,
       CAST(order_date_DateOrders AS DATE)    AS order_date,
       CAST(shipping_date_DateOrders AS DATE) AS ship_date,
       Shipping_Mode, Delivery_Status,
       CAST(Days_for_shipping_real AS INT)      AS days_actual,
       CAST(Days_for_shipment_scheduled AS INT) AS days_scheduled,
       CAST(Days_for_shipping_real AS INT) - CAST(Days_for_shipment_scheduled AS INT) AS delay_days,
       CASE WHEN Delivery_Status = 'Late delivery'     THEN 1 ELSE 0 END AS is_late,
       CASE WHEN Delivery_Status = 'Shipping canceled' THEN 1 ELSE 0 END AS is_canceled,
       Market, REPLACE(Order_Region, '  ', ' ') AS Order_Region, Order_Country, Order_City,
       Customer_Segment, Department_Name, Category_Name,
       Order_Status, [Type] AS payment_type,
       Sales, Order_Item_Total, Order_Profit_Per_Order AS profit,
       Order_Item_Quantity AS qty
FROM dbo.DataCoSupplyChainDataset;

-- L02: Data quality
SELECT COUNT(*) AS order_lines,
       COUNT(DISTINCT Order_Id) AS orders,
       MIN(order_date) AS first_order, MAX(order_date) AS last_order
FROM dbo.logistics;

SELECT Delivery_Status, COUNT(*) AS lines FROM dbo.logistics GROUP BY Delivery_Status ORDER BY lines DESC;

-- Does the "late" flag agree with the day counts? (cancelled excluded)
SELECT is_late,
       SUM(CASE WHEN delay_days > 0  THEN 1 ELSE 0 END) AS actual_slower_than_scheduled,
       SUM(CASE WHEN delay_days = 0  THEN 1 ELSE 0 END) AS actual_equals_scheduled,
       SUM(CASE WHEN delay_days < 0  THEN 1 ELSE 0 END) AS actual_faster_than_scheduled
FROM dbo.logistics
WHERE is_canceled = 0
GROUP BY is_late;

-- Contradictory statuses (e.g. PENDING but delivered late)
SELECT Order_Status, Delivery_Status, COUNT(*) AS lines
FROM dbo.logistics
GROUP BY Order_Status, Delivery_Status
ORDER BY lines DESC;

-- L03: Late rate by shipping mode (cancelled excluded)
SELECT Shipping_Mode,
       COUNT(*) AS lines,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_lines,
       ROUND(100.0 * AVG(CAST(is_late AS FLOAT)), 1) AS late_pct,
       AVG(CAST(days_scheduled AS FLOAT)) AS avg_scheduled_days,
       AVG(CAST(days_actual AS FLOAT))    AS avg_actual_days,
       AVG(CAST(delay_days AS FLOAT))     AS avg_delay_days
FROM dbo.logistics
WHERE is_canceled = 0
GROUP BY Shipping_Mode
ORDER BY late_pct DESC;

-- L04: Late rate by region, ranked
SELECT Market, Order_Region,
       COUNT(*) AS lines,
       ROUND(100.0 * AVG(CAST(is_late AS FLOAT)), 1) AS late_pct,
       RANK() OVER (ORDER BY AVG(CAST(is_late AS FLOAT)) DESC) AS late_rank
FROM dbo.logistics
WHERE is_canceled = 0
GROUP BY Market, Order_Region
ORDER BY late_rank;

-- L05: Monthly trend with LAG and a 3-month moving average
WITH m AS (
    SELECT DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1) AS month_start,
           COUNT(DISTINCT Order_Id) AS orders,
           COUNT(*) AS lines,
           100.0 * AVG(CAST(is_late AS FLOAT)) AS late_pct
    FROM dbo.logistics
    WHERE is_canceled = 0
    GROUP BY DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1)
)
SELECT month_start, orders, lines,
       ROUND(late_pct, 1) AS late_pct,
       ROUND(late_pct - LAG(late_pct) OVER (ORDER BY month_start), 1) AS change_vs_prev_month,
       ROUND(AVG(late_pct) OVER (ORDER BY month_start
             ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 1) AS late_pct_3mo_avg
FROM m
ORDER BY month_start;

-- L06: Do late orders look different? Value and profit
SELECT is_late,
       COUNT(*) AS lines,
       AVG(Order_Item_Total) AS avg_order_item_total,
       AVG(profit) AS avg_profit,
       ROUND(100.0 * AVG(CASE WHEN profit < 0 THEN 1.0 ELSE 0 END), 1) AS pct_loss_making
FROM dbo.logistics
WHERE is_canceled = 0
GROUP BY is_late;