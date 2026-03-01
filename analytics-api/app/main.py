# main.py
from fastapi import FastAPI, HTTPException, Header
from db import get_conn
import queries
import os
from dotenv import load_dotenv
from psycopg2.extras import RealDictCursor

# Load environment variables
load_dotenv()
API_KEY = os.getenv("API_KEY")

# Initialize FastAPI
app = FastAPI(title="Analytics API")

# -------------------------
# Authentication dependency
# -------------------------


def check_api_key(x_api_key: str = Header(...)):
    if x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Unauthorized")

# -------------------------
# Helper to run queries
# -------------------------


def run_query(sql, params=None):
    try:
        conn = get_conn()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute(sql, params)
        result = cur.fetchall()
        cur.close()
        conn.close()
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"DB Error: {e}")

# -------------------------
# Endpoints
# -------------------------

# 1 Open orders by delivery_date and status
@app.get("/analytics/orders")
def get_open_orders(x_api_key: str = Header(...)):
    check_api_key(x_api_key)
    return run_query(queries.open_orders)

# 2 Top 3 delivery dates with more open orders
@app.get("/analytics/orders/top")
def get_top_3_delivery_dates(limit: int = 3, x_api_key: str = Header(...)):
    check_api_key(x_api_key)
    sql = queries.get_top_3_delivery_dates(limit)
    return run_query(sql)

# 3 Open pending items by PRODUCT_ID
@app.get("/analytics/orders/product")
def get_open_pending_items(x_api_key: str = Header(...)):
    check_api_key(x_api_key)
    return run_query(queries.open_pending_items_by_product)

# 4 Top 3 customers with more pending orders
@app.get("/analytics/orders/customers")
def get_top_3_customers(limit: int = 3, x_api_key: str = Header(...)):
    check_api_key(x_api_key)
    sql = queries.top_3_customers(limit)
    return run_query(sql)