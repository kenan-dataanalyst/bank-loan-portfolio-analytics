/* ============================================================
   BANK KREDİT PORTFELİ VƏ MÜŞTƏRİ RİSK ANALİTİKASI
   02_analysis_queries.sql
   Oracle SQL — Analitik sorğular (JOIN, GROUP BY, CTE, window functions)
   ============================================================ */

-- ------------------------------------------------------------
-- Sorğu 1: Filial üzrə portfel icmalı
-- Hər filial üçün müştəri sayı, kredit sayı, ümumi portfel,
-- orta faiz dərəcəsi və default faizini göstərir.
-- ------------------------------------------------------------
SELECT b.branch_name,
       b.city,
       COUNT(DISTINCT c.customer_id)                         AS total_customers,
       COUNT(l.loan_id)                                      AS total_loans,
       SUM(l.loan_amount)                                    AS total_portfolio_azn,
       ROUND(AVG(l.interest_rate), 2)                        AS avg_interest_rate,
       ROUND(COUNT(CASE WHEN l.status = 'Default' THEN 1 END) * 100.0
             / COUNT(l.loan_id), 2)                           AS default_rate_pct
  FROM branches b
  JOIN customers c ON b.branch_id = c.branch_id
  JOIN loans l ON c.customer_id = l.customer_id
 GROUP BY b.branch_name, b.city
 ORDER BY total_portfolio_azn DESC;


-- ------------------------------------------------------------
-- Sorğu 2: Hər filialın TOP 3 borclu müştərisi
-- Müştəriləri hər filial daxilində ümumi borc məbləğinə görə
-- sıralamaq üçün CTE və DENSE_RANK() window function-dan istifadə edir.
-- ------------------------------------------------------------
WITH customer_summary AS (
    SELECT c.customer_id,
           c.full_name,
           b.branch_name,
           SUM(l.loan_amount) AS total_borrowed,
           DENSE_RANK() OVER (PARTITION BY b.branch_name
                               ORDER BY SUM(l.loan_amount) DESC) AS rank_in_branch
      FROM customers c
      JOIN branches b ON c.branch_id = b.branch_id
      JOIN loans l ON c.customer_id = l.customer_id
     GROUP BY c.customer_id, c.full_name, b.branch_name
)
SELECT *
  FROM customer_summary
 WHERE rank_in_branch <= 3
 ORDER BY branch_name, rank_in_branch;


-- ------------------------------------------------------------
-- Sorğu 3: Aylıq kredit verilişi trendi
-- Ay üzrə verilmiş kredit sayı, ümumi məbləğ və default sayı —
-- Excel/Power BI trend qrafikinin mənbəyi kimi istifadə olunur.
-- ------------------------------------------------------------
SELECT TO_CHAR(l.start_date, 'YYYY-MM')                        AS loan_month,
       COUNT(l.loan_id)                                        AS loans_issued,
       SUM(l.loan_amount)                                      AS total_amount_issued,
       COUNT(CASE WHEN l.status = 'Default' THEN 1 END)        AS default_count
  FROM loans l
 GROUP BY TO_CHAR(l.start_date, 'YYYY-MM')
 ORDER BY loan_month ASC;
