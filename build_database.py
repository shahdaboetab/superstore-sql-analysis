"""
Builds superstore.db (SQLite) from the Superstore CSV.

Usage:  python build_database.py "Sample - Superstore.csv"

The flat CSV is split into 4 related tables so the SQL queries need real JOINs:
    customers   (customer_id PK)
    products    (product_id  PK)
    orders      (order_id    PK, FK customer_id)
    order_items (row_id      PK, FK order_id, FK product_id)
"""
import sqlite3, sys
import pandas as pd

csv_path = sys.argv[1] if len(sys.argv) > 1 else "Sample - Superstore.csv"
df = pd.read_csv(csv_path, encoding="latin-1")          # file is Windows-1252 encoded

# ---- cleaning (same rules as the Excel and Python tasks) ----
for c in df.select_dtypes(include=["object","string"]).columns:
    df[c] = df[c].str.strip()
non_id = [c for c in df.columns if c != "Row ID"]
df = df.drop_duplicates(subset=non_id, keep="first")      # removes 1 duplicate line -> 9,993 rows
df["Order Date"] = pd.to_datetime(df["Order Date"], format="%m/%d/%Y").dt.strftime("%Y-%m-%d")
df["Ship Date"]  = pd.to_datetime(df["Ship Date"],  format="%m/%d/%Y").dt.strftime("%Y-%m-%d")
df["Postal Code"] = df["Postal Code"].astype(str).str.zfill(5)
# one standard name per Product ID (32 IDs carry more than one name in the raw data)
std_name = df.groupby("Product ID")["Product Name"].agg(lambda s: s.value_counts().index[0])
df["Product Name"] = df["Product ID"].map(std_name)
df.columns = df.columns.str.lower().str.replace(" ", "_").str.replace("-", "_")

con = sqlite3.connect("superstore.db")
con.executescript("""
DROP TABLE IF EXISTS order_items; DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;    DROP TABLE IF EXISTS customers;
CREATE TABLE customers (customer_id TEXT PRIMARY KEY, customer_name TEXT, segment TEXT);
CREATE TABLE products  (product_id TEXT PRIMARY KEY, category TEXT, sub_category TEXT, product_name TEXT);
CREATE TABLE orders (
    order_id TEXT PRIMARY KEY, order_date TEXT, ship_date TEXT, ship_mode TEXT,
    customer_id TEXT REFERENCES customers(customer_id),
    region TEXT, state TEXT, city TEXT, postal_code TEXT);
CREATE TABLE order_items (
    row_id INTEGER PRIMARY KEY,
    order_id   TEXT REFERENCES orders(order_id),
    product_id TEXT REFERENCES products(product_id),
    sales REAL, quantity INTEGER, discount REAL, profit REAL);
""")
def load(table, cols, dedupe_on=None):
    part = df[cols].drop_duplicates(dedupe_on) if dedupe_on else df[cols]
    part.to_sql(table, con, if_exists="append", index=False)
    print(f"{table:12s} {len(part):6,d} rows")
load("customers",   ["customer_id","customer_name","segment"], "customer_id")
load("products",    ["product_id","category","sub_category","product_name"], "product_id")
load("orders",      ["order_id","order_date","ship_date","ship_mode","customer_id","region","state","city","postal_code"], "order_id")
load("order_items", ["row_id","order_id","product_id","sales","quantity","discount","profit"])
con.execute("CREATE INDEX idx_items_order ON order_items(order_id)")
con.execute("CREATE INDEX idx_items_product ON order_items(product_id)")
con.commit(); con.close()
print("superstore.db created")
