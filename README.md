# Global Logistics: Delivery Performance Analysis 🚚

## Project Overview

This repository hosts the Power BI Desktop file (`GlobalLogistics.pbix`) and SQL Server queries (`Logistics_Queries.sql`) for an analysis of delivery performance in the DataCo supply-chain dataset: which shipping modes deliver late, whether region or time matters, and whether late orders look different from on-time ones.

"Global Logistics" is a fictional brand used to present a sample dataset.

---

## 🔑 Headline Finding

**Premium shipping is the least reliable. First Class is late 100% of the time and Second Class 80%, while Standard is late 40%. Second Class takes as long as Standard but promises half the time.**

- Of 180,519 order lines, 7,754 were cancelled and are excluded, leaving **172,765**. **98,977 (57.3%)** were delivered late.
- Lateness is a **shipping-mode** problem. It is not a regional or time problem (see below).

### Late rate by shipping mode

| Shipping mode | Order lines | Share | Late rate | Promised days | Actual days |
|---|---|---|---|---|---|
| First Class | 26,513 | 15.3% | 100.0% | 1 | 2.0 |
| Second Class | 33,806 | 19.6% | 79.8% | 2 | 4.0 |
| Same Day | 9,293 | 5.4% | 47.9% | 0 | 0.5 |
| Standard Class | 103,153 | 59.7% | 39.8% | 4 | 4.0 |

- Second Class takes about 4 days, the same as Standard Class, but promises 2.
- First Class takes 2 days against a promise of 1, and every single line is late by exactly one day.

### Regions

Late rates range from **51.6% (Canada)** to **60.1% (Central Africa)**, and most regions sit between about 56% and 58.5%. Region differences are small, and the highest and lowest regions have the fewest lines.

### Time trend

Across 37 months (Jan 2015 to Jan 2018) the monthly late rate stays between **55.2% and 59.3%**, with no improving or worsening trend.

### Do late orders look different?

No. Late and on-time lines have similar average order values (about 183 each), and almost the same share of loss-making lines (18.7% vs 18.6%).

---

## 🧩 Key Features

🚚 Late rate by shipping mode

⏱️ Promised vs actual delivery days

🌍 Late rate by region

📈 Monthly late-rate trend

🔍 Slicers for market, shipping mode, category and order date

---

## 🗂️ Data

- **Source:** "DataCo Smart Supply Chain for Big Data Analysis" on Kaggle (by shashwatwork), file `DataCoSupplyChainDataset.csv`.
- **Contents:** 180,519 order lines from 65,752 orders (Jan 2015 to Jan 2018), 53 columns covering shipping, geography, products, sales and profit.

---

### 🛠️ Tools Used

- SQL Server (SSMS): data cleaning and analysis
- Power BI Desktop
- DAX (Measures & Calculations)

### SQL Highlights (`Logistics_Queries.sql`)

| Section | Purpose |
|---|---|
| Create view | Clean view with shorter names, delay in days, late and cancelled flags, personal columns removed |
| Data quality | Row counts, status checks, and a test that the late flag matches the day counts |
| Shipping mode | Late rate, promised vs actual days by mode (window function for share) |
| Region ranking | Late rate by region with `RANK()` |
| Monthly trend | `LAG` for month-on-month change and a 3-month moving average |
| Late vs on-time | Order value and loss-making share for late and on-time lines |

### Data Model Highlights (DAX)

- `Late Rate = DIVIDE(SUM(logistics[is_late]), COUNTROWS(logistics))`
- `First Class Late Rate`: the late rate filtered to First Class.
- `Avg Promised Days` and `Avg Actual Days`: averages of the scheduled and actual shipping days.
- `Month`: calculated column giving the first day of each order month, used for the trend chart.

Page filter: cancelled shipments excluded (`is_canceled` is 0).

---

## ⚠️ Limitations

1. **The data looks synthetic.** First Class is late 100% of the time and always by exactly one day, and Second Class by almost exactly two. Real operations don't behave like this, so this project describes the patterns in the dataset, not the performance of a real company.
2. **Delivery status is derived.** All 98,977 late lines have actual days greater than scheduled days, so "late" is calculated from those two columns. It doesn't follow the order lifecycle: orders still in pending payment or on hold carry "late" labels.
3. **Cancelled shipments are excluded** (7,754 lines), because a cancelled shipment can't be late. Late rates including them are lower (54.8%).
4. **Lines vs orders.** The file has order lines, not orders. Until September 2017 each order has about three lines, and from October 2017 each order has one, so monthly volumes aren't comparable across that break. Compare late rates, not counts.
5. **Coordinates don't match the countries,** so the analysis uses region and country, not latitude and longitude.
6. **Region comparisons** are descriptive. I did not test whether small regional differences are explained by each region's shipping-mode mix.

---

## 🚀 Getting Started

To view and interact with the Power BI file:

1. **Download** the `GlobalLogistics.pbix` file from this repository.
2. **Install** [Power BI Desktop](https://powerbi.microsoft.com/desktop/).
3. **Open** the file in Power BI Desktop.

To rerun the SQL:

1. Download the CSV from the Kaggle dataset linked above.
2. Import it into SQL Server. The file isn't UTF-8 (use code page 1252), set columns to allow nulls, and use `int` for the day-count columns.
3. Run `Logistics_Queries.sql` from top to bottom.

---
