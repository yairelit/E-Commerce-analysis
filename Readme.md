# 📊 Olist E-Commerce Data Analysis

**In-depth analysis of Brazilian e-commerce data using advanced SQL.**

This project contains a collection of analytical SQL queries based on the Olist dataset. The goal is to extract meaningful business insights regarding sales trends, logistics performance, customer behavior, and product metrics.

![SQL](https://img.shields.io/badge/SQL-PostgreSQL-blue?style=for-the-badge&logo=postgresql)
![Data Analysis](https://img.shields.io/badge/Data-Analysis-orange?style=for-the-badge)

## 📂 The Dataset
The analysis is based on the public dataset provided by Olist, the largest department store in Brazilian marketplaces. It contains information on 100k orders made between 2016 and 2018.

The database schema consists of multiple related tables: Customers, Orders, Order Items, Payments, Reviews, Products, Sellers, and Geolocation.

🔗 **Link to Dataset:** [Olist Brazilian E-Commerce Dataset on Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

### 🗂️ Data Schema & Table Descriptions

The dataset consists of 9 distinct tables, related as follows:

| Table Name | Description | Key Columns |
| :--- | :--- | :--- |
| **`olist_orders_dataset`** | The core table. Contains high-level information about each order, including status and timestamps. | `order_id`, `customer_id`, `order_status`, `order_purchase_timestamp` |
| **`olist_customers_dataset`** | Contains customer information and their location. Links orders to unique customers. | `customer_id` (key to orders), `customer_unique_id`, `customer_zip_code_prefix` |
| **`olist_order_items_dataset`** | Details of items purchased within each order. Links orders to products and sellers. | `order_id`, `product_id`, `seller_id`, `price`, `freight_value` |
| **`olist_products_dataset`** | Product catalog including category names and dimensions. | `product_id`, `product_category_name`, `product_weight_g` |
| **`olist_order_payments_dataset`** | Payment options chosen by customers (credit card, voucher, etc.) and installment details. | `order_id`, `payment_type`, `payment_installments`, `payment_value` |
| **`olist_order_reviews_dataset`** | Customer reviews regarding the transaction. | `review_id`, `order_id`, `review_score`, `review_comment_message` |
| **`olist_sellers_dataset`** | Information about the sellers who fulfilled the orders. | `seller_id`, `seller_zip_code_prefix`, `seller_city`, `seller_state` |
| **`olist_geolocation_dataset`** | Geospatial data (latitude/longitude) for Brazilian zip codes. | `geolocation_zip_code_prefix`, `geolocation_lat`, `geolocation_lng` |
| **`product_category_name_translation`** | Translations of product category names from Portuguese to English. | `product_category_name`, `product_category_name_english` |


---

## 🎯 Project Objectives
In this project, I focus on answering complex business questions using **Advanced SQL techniques**, demonstrating proficiency in:
* **CTEs (Common Table Expressions)** for readable and modular code.
* **Window Functions** (`LAG`, `RANK`, `DENSE_RANK`, `SUM OVER`) for trend analysis.
* **Complex Joins** handling data across multiple normalized tables.
* **Date/Time Manipulation** for cohort analysis and delivery metrics.

## 🔍 Key Analyses

The queries are categorized into the following business domains:

### 1. Financial Performance & Growth
* Monthly Revenue Trends.
* Month-over-Month (MoM) Growth Rate calculation.
* Average Order Value (AOV) by category and time period.

### 2. Customer Behavior
* Customer Retention Analysis (New vs. Returning Customers).
* Geographical distribution of orders (State/City level).
* Preferred payment methods and installment analysis.

### 3. Logistics & Delivery Efficiency
* Delivery Time Analysis: Estimated vs. Actual delivery dates.
* Identifying shipping delay patterns by region.
* Freight cost analysis relative to order value.

### 4. Product & Category Insights
* Pareto Analysis: Identifying the top categories driving the majority of revenue.
* Best-selling products and seller performance.

---

## 🛠️ Repository Structure
```text
├── sql_queries/           # SQL scripts categorized by topic
│   ├── 01_revenue_growth.sql
│   ├── 02_customer_retention.sql
│   ├── 03_logistics_performance.sql
│   └── ...
├── schema/                # (Optional) ER Diagram or Table setup scripts
└── README.md              # Project documentation
