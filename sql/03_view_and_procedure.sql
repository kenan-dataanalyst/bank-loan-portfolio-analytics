/* ============================================================
   BANK KREDİT PORTFELİ VƏ MÜŞTƏRİ RİSK ANALİTİKASI
   03_view_and_procedure.sql
   Oracle SQL — Təkrar istifadə olunan VIEW + PL/SQL stored procedure
   ============================================================ */

-- ------------------------------------------------------------
-- VIEW: vw_branch_risk_summary
-- Saxlanılan, təkrar istifadə olunan filial-səviyyəli risk icmalı.
-- Excel və Power BI hər ikisi birbaşa bu obyektə qoşulur, beləliklə
-- eyni biznes məntiqi (default faizi hesablanması) hər alətdə
-- ayrıca təkrarlanmaq əvəzinə bir yerdə saxlanılır.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_branch_risk_summary AS
SELECT b.branch_name,
       b.city,
       COUNT(l.loan_id)                                          AS total_loan,
       SUM(l.loan_amount)                                        AS total_portfolio,
       COUNT(CASE WHEN l.status = 'Default' THEN 1 END)          AS default_count,
       ROUND(COUNT(CASE WHEN l.status = 'Default' THEN 1 END) * 100.0
             / NULLIF(COUNT(l.loan_id), 0), 2)                   AS default_rate_pct
  FROM branches b
  JOIN customers c ON b.branch_id = c.branch_id
  JOIN loans l ON c.customer_id = l.customer_id
 GROUP BY b.branch_name, b.city;

-- Yoxlama:
-- SELECT * FROM vw_branch_risk_summary ORDER BY default_rate_pct DESC;


-- ------------------------------------------------------------
-- PROCEDURE: get_customer_risk_profile
-- Verilən customer_id üçün qısa risk profili çap edir: kredit
-- sayı, ümumi borc, ən pis gecikmə (days past due) və sadə risk
-- işarəsi (90 gündən çox gecikməsi olan kreditli müştərilər
-- YÜKSƏK RİSK kimi işarələnir).
-- ------------------------------------------------------------
CREATE OR REPLACE PROCEDURE get_customer_risk_profile (
    p_customer_id IN NUMBER
) AS
    v_name        VARCHAR2(100);
    v_loan_count  NUMBER;
    v_total_debt  NUMBER;
    v_max_dpd     NUMBER;
BEGIN
    SELECT full_name INTO v_name
      FROM customers
     WHERE customer_id = p_customer_id;

    SELECT COUNT(loan_id), SUM(loan_amount), MAX(days_past_due)
      INTO v_loan_count, v_total_debt, v_max_dpd
      FROM loans
     WHERE customer_id = p_customer_id;

    DBMS_OUTPUT.PUT_LINE('Müştəri: ' || v_name);
    DBMS_OUTPUT.PUT_LINE('Kredit sayı: ' || v_loan_count);
    DBMS_OUTPUT.PUT_LINE('Ümumi borc: ' || NVL(v_total_debt, 0) || ' AZN');
    DBMS_OUTPUT.PUT_LINE('Ən yüksək gecikmə: ' || NVL(v_max_dpd, 0) || ' gün');

    IF v_max_dpd > 90 THEN
        DBMS_OUTPUT.PUT_LINE('Risk səviyyəsi: YÜKSƏK RİSK');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Risk səviyyəsi: NORMAL');
    END IF;
END;
/

-- Nümunə çağırış:
-- BEGIN
--     get_customer_risk_profile(15);
-- END;
