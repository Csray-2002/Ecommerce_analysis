# Olist E-Commerce Data Analysis

## 📊 Project Overview

This project analyzes the Brazilian Olist e-commerce dataset to understand
sales performance, customer behavior, product performance, payments,
delivery performance, and customer satisfaction.

The project was developed using SQL Server and focuses on answering business-oriented questions rather than only performing basic SQL queries.

The analysis is being developed in multiple stages, starting with an
initial exploratory analysis and gradually moving toward structured
business analysis.

---

## 🎯 Business Objective

The main objective of this project is to analyze Olist's e-commerce
operations and identify meaningful business insights related to:

- Sales and order performance
- Product and category performance
- Customer behavior and retention
- Geographic performance
- Payment behavior
- Delivery performance
- Customer satisfaction
- Revenue growth and business drivers

---

## 🗂️ Dataset

The project uses the Brazilian Olist E-Commerce dataset originally
available through Kaggle.

The dataset contains information related to:

- Customers
- Orders
- Order items
- Products
- Sellers
- Payments
- Reviews
- Product categories
- Geographic information

The data has been cleaned and transformed before being loaded into
SQL Server for analysis.

---

## 🛠️ Tools & Technologies

- SQL Server
- Kaggle Olist E-Commerce Dataset
- GitHub

---

## 🗄️ Database

The cleaned data is stored in a SQL Server database named:

`OlistAnalytics`

Main tables include:

- `orders_master`
- `customers`
- `orders_items`
- `products`
- `payments`
- `reviews`
- `product_category_name_translation`

---

## 📌 Revenue Definition

For this project, **Product Revenue** is defined as:

`SUM(orders_items.price)`

This represents the value of products sold.

Freight and other payment-related charges are excluded from the
Product Revenue metric.

The `payments.payment_value` field is analyzed separately as
customer payment value and is not mixed with Product Revenue.

---

## 🔍 Initial Analysis

The first stage of the project contains 22 exploratory SQL queries
covering several areas of the business.

### Initial Analysis Areas

1. Total orders
2. Product revenue
3. Average Order Value (AOV)
4. Orders by status
5. Monthly sales performance
6. Top product categories
7. Monthly AOV
8. Revenue by customer state
9. Payment type distribution
10. Average installments
11. Top customers by spending
12. Customer spending segmentation
13. Repeat customer analysis
14. Late delivery analysis
15. Review score distribution
16. Late vs. on-time delivery and reviews
17. Category revenue ranking by year
18. Month-over-month revenue growth
19. Cumulative revenue
20. RFM analysis
21. Cohort analysis
22. One-time vs. repeat customer revenue

---