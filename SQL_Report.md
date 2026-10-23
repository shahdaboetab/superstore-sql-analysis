# Superstore SQL Business Analysis: Report

**Database:** SQLite (`superstore.db`), 4 tables, 9,993 order lines, 5,009 orders, 793 customers, Jan 2014 - Dec 2017.
**Queries:** `queries.sql` (14 queries). **Raw outputs:** `results/*.csv`.

## Summary
Sales are **$2.30M** and profit **$286K** (12.5% margin), and the totals match the Excel dashboard exactly.
The business is growing, but **heavy discounting and a few weak product lines are costing about $135K of profit**.

## Findings by question

| # | Question | Technique | Answer |
|---|---|---|---|
| Q1 | How big is the business? | JOIN, aggregates | $2,296,919 sales, $286,409 profit, 12.5% margin, 5,009 orders, 793 customers, average order value $458.56. |
| Q2 | Which regions perform best? | JOIN, GROUP BY | West leads ($725K sales, 14.9% margin). **Central is weakest at 7.9% margin** on $501K sales. |
| Q3 | Category and sub-category margins? | Multi-column GROUP BY | Technology 17.4% and Office Supplies 17.0% are healthy. **Furniture earns only 2.5%** on $742K. Copiers is the top profit sub-category ($55.6K at a 37.2% margin), but Machines earns just 1.8% on $189K of sales. |
| Q4 | Which sub-categories lose money? | HAVING | **Tables (-$17,725), Bookcases (-$3,473), Supplies (-$1,189).** |
| Q5 | Year-over-year growth? | CTE + LAG | Sales: $484K (2014), $471K (2015, -2.8%), $609K (2016, +29.5%), $733K (2017, +20.4%). Margin rose from 10.2% to 13.1-13.4%, then eased to 12.7% in 2017. |
| Q6 | Monthly pattern? | CTE + LAG | Strong seasonality: **Sep, Nov and Dec generate 42.9% of all sales** (Nov 15.3%, Dec 14.2%, Sep 13.4%). Best month: Nov 2017 ($118K). January and February are the weakest (4.1% and 2.6%). |
| Q7 | Top 3 products per category? | RANK() | Canon imageCLASS 2200 Copier is the most profitable product ($25.2K profit on $61.6K). Office Supplies leader: Fellowes PB500 binding machine ($7.8K). Furniture leader: Hon Deluxe Stacking Chairs ($1.9K). |
| Q8 | Customers above average spend? | CTE + subquery | The average customer spends $2,896. The top customer, **Sean Miller, spends $25,043 but loses $1,981**. |
| Q9 | Revenue concentration? | NTILE | The **top 25% of customers (199) generate 55.1% of sales**; the bottom 25% only 5.5%. |
| Q10 | Repeat vs one-time customers? | CTE, CASE | 781 of 793 customers (98.5%) are repeat buyers, averaging 6.4 orders each. Only 12 bought once. |
| Q11 | Discount impact? | CASE, conditional aggregation | No discount: 29.5% margin. 1-20%: 11.9%. **21-40%: -15.3% margin, 90% of lines lose money. Above 40%: -77.4% margin, 100% of lines lose money.** Together they lose $135K. |
| Q12 | Delivery time by ship mode? | julianday | Same Day 0.0 days, First Class 2.2, Second Class 3.2, Standard Class 5.0 (2,994 orders, 60% of all orders). Max 7 days. |
| Q13 | Big customers that lose money? | CTE, filter on aggregates | Ten large accounts have negative profit, led by Sean Miller (-$1,981), **Grant Thornton (-$4,109 on $9,351 sales)** and Sean Braxton (-$2,083). |
| Q14 | Worst states? | JOIN, ORDER BY + LIMIT | **Texas -$25.7K, Ohio -$17.0K, Pennsylvania -$15.6K, Illinois -$12.6K.** All four have margins worse than -13%. |

## Recommendations
1. **Cap discounts at 20%** and require approval above it. Lines discounted above 20% lose money almost every time (1,392 lines, -$135K).
2. **Fix Furniture pricing**, starting with Tables and Bookcases, and review Machines (1.8% margin).
3. **Review accounts that buy a lot but lose money** (Sean Miller, Grant Thornton, Sean Braxton): worth checking whether deep discounts explain the losses.
4. **Investigate Texas, Ohio, Pennsylvania and Illinois**, and check whether heavy discounting explains the losses there.
5. **Plan inventory and marketing for Sep, Nov and Dec**, which bring in over 40% of sales.
6. **Protect the top 25% of customers**, who generate more than half of sales.

## Assumptions and limitations
- The CSV was split into `customers`, `products`, `orders` and `order_items`. The source has **no payments table**, so Ship Mode and delivery time were analysed instead.
- 1 duplicate line (Row ID 3407, identical to 3406 except for the ID) was removed, leaving 9,993 lines.
- 32 Product IDs carry more than one name in the raw data. Each product uses its most frequent name; product-level queries group by Product ID.
- There is no cost, return or inventory data, so profit is as reported in the source. Correlation does not prove that discounts cause the losses.
- Only 4 years of US data; findings may not apply to other markets.
