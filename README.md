# E-commerce Operations & Customer Analytics Dashboard

## Overview
End-to-end analytics project analyzing 99K+ orders from Olist, 
a Brazilian e-commerce marketplace. Built using PostgreSQL and Power BI 
to analyze order funnel, delivery SLA, customer cohorts, and RFM segmentation.

## Tools & Technologies
- PostgreSQL (pgAdmin)
- Power BI Desktop
- Microsoft Excel (EDA)

## Key Findings

### Funnel Analysis
- 99,441 total orders with 96.37% end-to-end completion rate
- Dispatch stage is the biggest drop-off — 1,537 orders approved but never shipped
- Payment approval is near perfect at 99.99%

### Delivery SLA Analysis
- 91.88% on-time delivery rate overall
- Late orders take 31.5 days on average vs 10.9 days for on-time orders
- Northeast Brazil has highest late delivery rates — AL state at 23.93%
- Food category late delivery rate at 9.82% — critical for perishable goods

### Cohort Retention Analysis
- Monthly retention is <1% across all customer cohorts
- Indicates one-time purchase behavior — not a repeat buying platform
- 2017-11 was the largest cohort with 7,304 new customers

### RFM Segmentation
- At Risk is the largest segment at 23.45% (21,876 customers)
- Champions have highest avg spend at $309 vs Lost at $56
- 15.4% New Customers need nurturing to convert to Loyal segment

## Dashboard Pages
- **Page 1 — Operations Overview:** Funnel conversion, 
  SLA summary, Late delivery by state, Monthly order trends
- **Page 2 — Customer Intelligence:** RFM segments, 
  Cohort retention heatmap, Avg spend by segment

## Dataset
[Olist Brazilian E-commerce Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
