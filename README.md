# Olist E-Commerce Analytics: Track J (Customer Reviews & Feedback)

This repository contains the complete Business Intelligence (BI) project deliverables for **Track J: Customer Reviews**, utilizing the comprehensive Olist E-Commerce dataset. The project focuses on evaluating customer satisfaction, analyzing rating distributions, and identifying service delivery issues impacting overall user experience.

---

## 📊 Project Overview & Objectives
* **Business Scenario:** Analyzing customer feedback trends, low-rating friction points, and regional delivery performance to provide actionable recommendations for marketplace optimization.
* **Date Range:** January 2017 to August 2018.
* **Key Deliverables:**
  1. Relational Data Model & Power Query ETL.
  2. SQL Queries covering common and track-specific business questions.
  3. Interactive Excel Dashboard featuring KPIs, visual charts, and dynamic slicers.
  4. Executive BI Report (`BI Report.pdf`).

---

## 📈 Key Performance Indicators (KPIs) & Dashboard Metrics
The interactive Excel dashboard (`Book1.xlsx`) highlights the following core metrics:
* **Mean Rating Score:** **4.09 / 5.0** (Reflecting solid overall platform satisfaction).
* **Low-Rating Rate (1-2 Stars):** **14.7%** (Isolating critical areas of customer friction).
* **Reviewed Orders:** **99,224** total evaluated orders.
* **Review Coverage:** **99.8%** post-purchase feedback engagement rate.

---

## 🛠️ Repository File Structure
* 📁 **`Task1-BI.xlsx`**: The master Excel workbook containing Power Pivot data models, calculated PivotTables, and the interactive **Dashboard** sheet.
* 📄 **`BI Report.pdf`**: Comprehensive executive summary report.
* 📁 **`J1.sql` to `J7.sql` & `Q1.sql` to `Q3.sql`**: SQL scripts containing queries utilized for data extraction, aggregation, and track-specific review analysis.

---

## 💡 Key Insights
* **High Overall Satisfaction:** Strong overall customer sentiment with a mean rating of 4.09, heavily driven by a dominant share of 5-star reviews (over 57,000 orders).
* **Operational Friction:** Low ratings (1 and 2 stars) account for 14.7% of total feedback, signaling core issues tied to logistics, late shipments, or product quality.
* **Regional Disparities:** Customer ratings vary noticeably across Brazilian states (`customer_state`), with top regions exceeding 4.15 and underperforming areas dropping below 3.80.

---

## 🚀 Actionable Recommendations
1. **Root-Cause Analysis:** Conduct deep-dive audits on the 14.7% low-rating segment to resolve recurring delivery delays and damaged items.
2. **State-Level Logistics Optimization:** Prioritize carrier and fulfillment performance enhancements in lower-rated states.
3. **Automated Recovery Workflows:** Deploy rapid-response support interventions for customers submitting 1-star reviews to prevent churn.
