# Superstore SQL Business Analysis

SQL analysis of 9,993 Superstore order lines (2014-2017): revenue, profit, discounts, customers and regions.
Built for the **UneeQ Interns** Data Analysis program (SQL Business Case task).

## Business problem
Management wants to know where the business makes and loses money, and which customers, products and regions need attention.

## Dataset
[Superstore Sales (Kaggle)](https://www.kaggle.com/datasets/vivek468/superstore-dataset-final): 21 columns, US orders, 2014-2017.
The flat file was split into 4 related tables:

```
customers (customer_id PK, customer_name, segment)
     |1
     |N
orders (order_id PK, order_date, ship_date, ship_mode, customer_id FK, region, state, city, postal_code)
     |1
     |N
order_items (row_id PK, order_id FK, product_id FK, sales, quantity, discount, profit)
     |N
     |1
products (product_id PK, category, sub_category, product_name)
```

## Files
| File | Description |
|---|---|
| `superstore.db` | SQLite database (ready to open) |
| `build_database.py` | Rebuilds the database from the CSV |
| `queries.sql` | 14 commented business queries |
| `results/` | Output of each query (CSV) |
| `SQL_Report.md` | Findings and recommendations |

## How to run
1. Install [DB Browser for SQLite](https://sqlitebrowser.org).
2. `Open Database` > `superstore.db` > tab **Execute SQL**.
3. Paste a query from `queries.sql` and press `Ctrl+Enter`.

To rebuild from scratch: `python build_database.py "Sample - Superstore.csv"`

## SQL techniques used
JOINs (3 tables), GROUP BY / HAVING, CTEs, scalar subqueries, CASE, and window functions: `LAG`, `RANK() OVER (PARTITION BY)`, `NTILE`.

## Key findings
- Sales **$2.30M**, profit **$286K**, margin **12.5%**.
- **Discounts above 20% lose money**: 21-40% has a -15.3% margin and above 40% has -77.4% (-$135K combined).
- **Furniture earns only 2.5%**; Tables lose $17.7K.
- **Central** has the weakest region margin (7.9%); **Texas, Ohio, Pennsylvania, Illinois** are the biggest loss states.
- The **top 25% of customers generate 55%** of sales.
- Sep, Nov and Dec bring in **42.9%** of annual sales.

Full details and recommendations: [SQL_Report.md](SQL_Report.md)

## Assumptions and limitations
No payments table exists, so delivery time by Ship Mode was analysed instead. 1 duplicate line was removed. No cost data; correlation is not causation.

## Video walkthrough
[Watch here](https://youtu.be/WX0Wtdgj44o)

## Author
Shahd Aboetab | [LinkedIn](https://linkedin.com/in/shahdaboetab)
