/* ============================================================
   BANK LOAN PORTFOLIO & CUSTOMER RISK ANALYTICS
   01_bank_schema_and_data.sql
   Oracle SQL — Schema yaratma + sintetik data generasiyası
   Müəllif: Kenan Qurayishov (portfolio layihəsi)
   ============================================================ */

-- Əvvəlki cədvəllər varsa təmizlə (ilk dəfə işlədəndə xəta versə, normaldır)
-- DROP TABLE transactions PURGE;
-- DROP TABLE loans PURGE;
-- DROP TABLE customers PURGE;
-- DROP TABLE branches PURGE;

/* ---------- 1. CƏDVƏLLƏR ---------- */

CREATE TABLE branches (
    branch_id     NUMBER(3)      PRIMARY KEY,
    branch_name   VARCHAR2(50)   NOT NULL,
    city          VARCHAR2(50)   NOT NULL
);

CREATE TABLE customers (
    customer_id   NUMBER(6)      PRIMARY KEY,
    full_name     VARCHAR2(100)  NOT NULL,
    gender        VARCHAR2(1)    CHECK (gender IN ('M','F')),
    birth_date    DATE,
    city          VARCHAR2(50),
    branch_id     NUMBER(3)      REFERENCES branches(branch_id),
    segment       VARCHAR2(20)   CHECK (segment IN ('Retail','SME','Premium')),
    join_date     DATE
);

CREATE TABLE loans (
    loan_id        NUMBER(6)      PRIMARY KEY,
    customer_id    NUMBER(6)      REFERENCES customers(customer_id),
    branch_id      NUMBER(3)      REFERENCES branches(branch_id),
    loan_type      VARCHAR2(30)   CHECK (loan_type IN ('Mortgage','Auto Loan','Personal Loan','Business Loan','Credit Card')),
    loan_amount    NUMBER(12,2),
    interest_rate  NUMBER(5,2),
    term_months    NUMBER(4),
    start_date     DATE,
    status         VARCHAR2(20)   CHECK (status IN ('Active','Closed','Default')),
    days_past_due  NUMBER(4)
);

CREATE TABLE transactions (
    transaction_id     NUMBER(7)      PRIMARY KEY,
    loan_id            NUMBER(6)      REFERENCES loans(loan_id),
    transaction_date   DATE,
    amount             NUMBER(12,2),
    transaction_type   VARCHAR2(20)   CHECK (transaction_type IN ('Payment','Late Fee'))
);

/* ---------- 2. FİLİALLAR (7 ədəd) ---------- */

INSERT INTO branches VALUES (1, 'Baku Central',      'Bakı');
INSERT INTO branches VALUES (2, 'Baku Yasamal',       'Bakı');
INSERT INTO branches VALUES (3, 'Ganja Branch',       'Gəncə');
INSERT INTO branches VALUES (4, 'Sumgait Branch',     'Sumqayıt');
INSERT INTO branches VALUES (5, 'Mingachevir Branch', 'Mingəçevir');
INSERT INTO branches VALUES (6, 'Sheki Branch',       'Şəki');
INSERT INTO branches VALUES (7, 'Lankaran Branch',    'Lənkəran');
COMMIT;

/* ---------- 3. MÜŞTƏRİLƏR (1000 ədəd) ---------- */

DECLARE
    TYPE t_names IS VARRAY(20) OF VARCHAR2(30);
    v_first_m t_names := t_names('Elvin','Tural','Kamran','Orxan','Rəşad','Vüqar','Anar','Fuad','Elşən','Nicat',
                                  'Murad','Rüfət','Samir','Toğrul','Ceyhun','Ramin','Kənan','Emin','Zaur','Fərid');
    v_first_f t_names := t_names('Aysel','Günel','Leyla','Nərgiz','Səbinə','Aynur','Türkan','Nigar','Röya','Ülviyyə',
                                  'Xəyalə','Sevinc','Vəfa','Lalə','Zeynəb','Fidan','Nərmin','Şəbnəm','Könül','Mehriban');
    v_last    t_names := t_names('Məmmədov','Əliyev','Hüseynov','Quliyev','İsmayılov','Həsənov','Rəhimov','Nəbiyev',
                                  'Cəfərov','Abbasov','Vəliyev','Kərimov','Musayev','Bağırov','Orucov','Sadıqov',
                                  'Əzizov','Rzayev','Tağıyev','Novruzov');
    v_city    t_names := t_names('Bakı','Bakı','Gəncə','Sumqayıt','Mingəçevir','Şəki','Lənkəran');

    v_segment VARCHAR2(20);
    v_gender  VARCHAR2(1);
    v_branch  NUMBER;
    v_rand    NUMBER;
BEGIN
    FOR i IN 1..1000 LOOP
        v_gender := CASE WHEN DBMS_RANDOM.VALUE < 0.5 THEN 'M' ELSE 'F' END;
        v_branch := TRUNC(DBMS_RANDOM.VALUE(1,8)); -- 1..7

        v_rand := DBMS_RANDOM.VALUE;
        v_segment := CASE WHEN v_rand < 0.60 THEN 'Retail'
                          WHEN v_rand < 0.85 THEN 'SME'
                          ELSE 'Premium' END;

        INSERT INTO customers (customer_id, full_name, gender, birth_date, city, branch_id, segment, join_date)
        VALUES (
            i,
            (CASE WHEN v_gender = 'M' THEN v_first_m(TRUNC(DBMS_RANDOM.VALUE(1,21)))
                  ELSE v_first_f(TRUNC(DBMS_RANDOM.VALUE(1,21))) END)
              || ' ' || v_last(TRUNC(DBMS_RANDOM.VALUE(1,21))),
            v_gender,
            DATE '1965-01-01' + TRUNC(DBMS_RANDOM.VALUE(0, 365*40)),
            v_city(v_branch),
            v_branch,
            v_segment,
            DATE '2019-01-01' + TRUNC(DBMS_RANDOM.VALUE(0, 365*6))
        );
    END LOOP;
    COMMIT;
END;
/

/* ---------- 4. KREDİTLƏR (1300 ədəd) ---------- */

DECLARE
    TYPE t_types IS VARRAY(5) OF VARCHAR2(30);
    v_loan_types t_types := t_types('Mortgage','Auto Loan','Personal Loan','Business Loan','Credit Card');

    v_cust_id     NUMBER;
    v_branch_id   NUMBER;
    v_type        VARCHAR2(30);
    v_amount      NUMBER;
    v_rate        NUMBER;
    v_term        NUMBER;
    v_start       DATE;
    v_status      VARCHAR2(20);
    v_dpd         NUMBER;
    v_rand        NUMBER;
    v_status_rand NUMBER;
BEGIN
    FOR i IN 1..1300 LOOP
        v_cust_id := TRUNC(DBMS_RANDOM.VALUE(1,1001));
        SELECT branch_id INTO v_branch_id FROM customers WHERE customer_id = v_cust_id;

        v_rand := DBMS_RANDOM.VALUE;
        v_type := CASE WHEN v_rand < 0.20 THEN 'Mortgage'
                       WHEN v_rand < 0.45 THEN 'Auto Loan'
                       WHEN v_rand < 0.70 THEN 'Personal Loan'
                       WHEN v_rand < 0.85 THEN 'Business Loan'
                       ELSE 'Credit Card' END;

        v_amount := CASE v_type
            WHEN 'Mortgage'       THEN ROUND(DBMS_RANDOM.VALUE(50000,200000),2)
            WHEN 'Auto Loan'      THEN ROUND(DBMS_RANDOM.VALUE(8000,40000),2)
            WHEN 'Personal Loan'  THEN ROUND(DBMS_RANDOM.VALUE(1000,15000),2)
            WHEN 'Business Loan'  THEN ROUND(DBMS_RANDOM.VALUE(20000,150000),2)
            ELSE                        ROUND(DBMS_RANDOM.VALUE(500,10000),2)
        END;

        v_term := CASE v_type
            WHEN 'Mortgage'       THEN TRUNC(DBMS_RANDOM.VALUE(120,360))
            WHEN 'Auto Loan'      THEN TRUNC(DBMS_RANDOM.VALUE(24,84))
            WHEN 'Personal Loan'  THEN TRUNC(DBMS_RANDOM.VALUE(6,60))
            WHEN 'Business Loan'  THEN TRUNC(DBMS_RANDOM.VALUE(12,120))
            ELSE                        TRUNC(DBMS_RANDOM.VALUE(6,36))
        END;

        v_rate  := ROUND(DBMS_RANDOM.VALUE(5,22),2);
        v_start := DATE '2020-01-01' + TRUNC(DBMS_RANDOM.VALUE(0, 365*5.5));

        v_status_rand := DBMS_RANDOM.VALUE;
        IF v_status_rand < 0.70 THEN
            v_status := 'Active';
            v_dpd := CASE WHEN DBMS_RANDOM.VALUE < 0.15 THEN TRUNC(DBMS_RANDOM.VALUE(1,89)) ELSE 0 END;
        ELSIF v_status_rand < 0.90 THEN
            v_status := 'Closed';
            v_dpd := 0;
        ELSE
            v_status := 'Default';
            v_dpd := TRUNC(DBMS_RANDOM.VALUE(90,365));
        END IF;

        INSERT INTO loans (loan_id, customer_id, branch_id, loan_type, loan_amount,
                            interest_rate, term_months, start_date, status, days_past_due)
        VALUES (i, v_cust_id, v_branch_id, v_type, v_amount, v_rate, v_term, v_start, v_status, v_dpd);
    END LOOP;
    COMMIT;
END;
/

/* ---------- 5. ƏMƏLİYYATLAR (~6000 ədəd: Payment + Late Fee) ---------- */

DECLARE
    v_loan_id     NUMBER;
    v_loan_amt    NUMBER;
    v_term        NUMBER;
    v_start       DATE;
    v_tx_date     DATE;
    v_type        VARCHAR2(20);
    v_amount      NUMBER;
    v_max_offset  NUMBER;
BEGIN
    FOR i IN 1..6000 LOOP
        v_loan_id := TRUNC(DBMS_RANDOM.VALUE(1,1301));
        SELECT loan_amount, term_months, start_date
          INTO v_loan_amt, v_term, v_start
          FROM loans WHERE loan_id = v_loan_id;

        -- kreditin bitmə tarixi ilə bugünkü tarix arasından kiçiyini götürürük
        v_max_offset := GREATEST(LEAST(v_term * 30, TRUNC(SYSDATE - v_start)), 16);
        v_tx_date := v_start + TRUNC(DBMS_RANDOM.VALUE(15, v_max_offset));

        IF DBMS_RANDOM.VALUE < 0.88 THEN
            v_type   := 'Payment';
            v_amount := ROUND((v_loan_amt / GREATEST(v_term,1)) * DBMS_RANDOM.VALUE(0.85,1.15), 2);
        ELSE
            v_type   := 'Late Fee';
            v_amount := ROUND(DBMS_RANDOM.VALUE(10,100), 2);
        END IF;

        INSERT INTO transactions (transaction_id, loan_id, transaction_date, amount, transaction_type)
        VALUES (i, v_loan_id, v_tx_date, v_amount, v_type);
    END LOOP;
    COMMIT;
END;
/

/* ---------- YOXLAMA ---------- */
SELECT 'branches' AS tbl, COUNT(*) FROM branches
UNION ALL SELECT 'customers', COUNT(*) FROM customers
UNION ALL SELECT 'loans', COUNT(*) FROM loans
UNION ALL SELECT 'transactions', COUNT(*) FROM transactions;
