
-- LOAN PORTFOLIO COMPREHENSIVE EDA SUITE


-- 1. Total row count vs Unique loan IDs
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT loan_id) AS unique_loans,
    COUNT(*) - COUNT(DISTINCT loan_id) AS duplicate_id_count
FROM loan_portfolio;

-- 2. Identify specific duplicate loan_ids
SELECT
    loan_id,
    COUNT(*) AS occurrence_count
FROM public.loan_portfolio
GROUP BY loan_id
HAVING COUNT(*) > 1
ORDER BY occurrence_count DESC;

-- 3. Check explicit NULL values and placeholder values
SELECT 
    COUNT(*) - COUNT(loan_id) AS explicit_null_loan_id,
    COUNT(*) - COUNT(sector) AS explicit_null_sector,
    COUNT(*) - COUNT(pd_annual) AS explicit_null_pd,
    COUNT(*) - COUNT(lgd) AS explicit_null_lgd,
    COUNT(*) - COUNT(ead) AS explicit_null_ead,
    COUNT(*) - COUNT(rwa) AS explicit_null_rwa,
    COUNT(*) - COUNT(loan_amount) AS explicit_null_loan_amount,
    SUM(CASE WHEN LOWER(TRIM(pd_annual)) IN ('', '-', '--', 'na', 'n/a', 'missing', 'unknown', 'n.a.', 'not available') THEN 1 ELSE 0 END) AS placeholder_pd,
    SUM(CASE WHEN LOWER(TRIM(lgd)) IN ('', '-', '--', 'na', 'n/a', 'missing', 'unknown', 'n.a.', 'not available') THEN 1 ELSE 0 END) AS placeholder_lgd,
    SUM(CASE WHEN LOWER(TRIM(ead)) IN ('', '-', '--', 'na', 'n/a', 'missing', 'unknown', 'n.a.', 'not available') THEN 1 ELSE 0 END) AS placeholder_ead
FROM loan_portfolio;

-- 4. Check blank values in text columns
SELECT
    COUNT(*) FILTER (WHERE TRIM(loan_id) = '') AS blank_loan_id,
    COUNT(*) FILTER (WHERE TRIM(sector) = '') AS blank_sector,
    COUNT(*) FILTER (WHERE TRIM(pd_annual) = '') AS blank_pd,
    COUNT(*) FILTER (WHERE TRIM(lgd) = '') AS blank_lgd,
    COUNT(*) FILTER (WHERE TRIM(ead) = '') AS blank_ead
FROM loan_portfolio;

-- 5. Categorical consistency audit for sector
SELECT 
    sector AS raw_sector_value,
    COUNT(*) AS record_count
FROM loan_portfolio
GROUP BY sector
ORDER BY record_count DESC;

-- 6. Sector percentage of total portfolio
SELECT
    sector,
    COUNT(*) AS loan_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS portfolio_percentage
FROM loan_portfolio
GROUP BY sector
ORDER BY loan_count DESC;

-- 7. Count distinct sector labels
SELECT COUNT(DISTINCT sector) AS distinct_sector_labels FROM loan_portfolio;

-- 8. Distinct raw PD values and frequency
SELECT pd_annual AS raw_pd_value, COUNT(*) AS frequency FROM loan_portfolio GROUP BY pd_annual ORDER BY frequency DESC;

-- 9. Distinct raw LGD values and frequency
SELECT lgd AS raw_lgd_value, COUNT(*) AS frequency FROM loan_portfolio GROUP BY lgd ORDER BY frequency DESC;

-- 10. Distinct raw EAD values and frequency
SELECT ead AS raw_ead_value, COUNT(*) AS frequency FROM loan_portfolio GROUP BY ead ORDER BY frequency DESC;

-- 11. Count PD values formatted as percentage
SELECT SUM(CASE WHEN pd_annual LIKE '%\%' ESCAPE '\' THEN 1 ELSE 0 END) AS pd_formatted_as_percentage FROM loan_portfolio;

-- 12. Count EAD values containing commas
SELECT SUM(CASE WHEN ead LIKE '%,%' THEN 1 ELSE 0 END) AS ead_formatted_with_commas FROM loan_portfolio;

-- 13. Non-numeric PD values
SELECT pd_annual, COUNT(*) AS frequency
FROM loan_portfolio
WHERE pd_annual IS NOT NULL AND TRIM(pd_annual) <> '' AND TRIM(pd_annual) !~ '^[0-9]+(\.[0-9]+)?%?$'
GROUP BY pd_annual ORDER BY frequency DESC;

-- 14. Non-numeric LGD values
SELECT lgd, COUNT(*) AS frequency
FROM loan_portfolio
WHERE lgd IS NOT NULL AND TRIM(lgd) <> '' AND TRIM(lgd) !~ '^[0-9]+(\.[0-9]+)?$'
GROUP BY lgd ORDER BY frequency DESC;

-- 15. Non-numeric EAD values (handling commas)
SELECT ead, COUNT(*) AS frequency
FROM loan_portfolio
WHERE ead IS NOT NULL AND TRIM(ead) <> '' AND REPLACE(TRIM(ead), ',', '') !~ '^[0-9]+(\.[0-9]+)?$'
GROUP BY ead ORDER BY frequency DESC;

-- 16. Descriptive statistics for PD
SELECT
    COUNT(*) AS valid_pd_count,
    ROUND(AVG(pd_value), 4) AS mean_pd,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY pd_value)::numeric, 4) AS median_pd,
    ROUND(MIN(pd_value), 4) AS min_pd,
    ROUND(MAX(pd_value), 4) AS max_pd,
    ROUND(STDDEV(pd_value)::numeric, 4) AS stddev_pd,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY pd_value)::numeric, 4) AS q1_pd,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY pd_value)::numeric, 4) AS q3_pd
FROM (
    SELECT
        CASE
            WHEN TRIM(pd_annual) ~ '^[0-9]+(\.[0-9]+)?%$' THEN REPLACE(TRIM(pd_annual), '%', '')::numeric / 100
            WHEN TRIM(pd_annual) ~ '^[0-9]+(\.[0-9]+)?$' THEN TRIM(pd_annual)::numeric
        END AS pd_value
    FROM loan_portfolio
) x WHERE pd_value IS NOT NULL;

-- 17. Descriptive statistics for LGD
SELECT
    COUNT(*) AS valid_lgd_count,
    ROUND(AVG(lgd_value), 4) AS mean_lgd,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY lgd_value)::numeric, 4) AS median_lgd,
    ROUND(MIN(lgd_value), 4) AS min_lgd,
    ROUND(MAX(lgd_value), 4) AS max_lgd,
    ROUND(STDDEV(lgd_value)::numeric, 4) AS stddev_lgd,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY lgd_value)::numeric, 4) AS q1_lgd,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY lgd_value)::numeric, 4) AS q3_lgd
FROM (
    SELECT CASE WHEN TRIM(lgd) ~ '^[0-9]+(\.[0-9]+)?$' THEN TRIM(lgd)::numeric END AS lgd_value
    FROM loan_portfolio
) x WHERE lgd_value IS NOT NULL;

-- 18. Descriptive statistics for EAD (Handles commas)
SELECT
    COUNT(*) AS valid_ead_count,
    ROUND(AVG(ead_value), 2) AS mean_ead,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY ead_value)::numeric, 2) AS median_ead,
    ROUND(MIN(ead_value), 2) AS min_ead,
    ROUND(MAX(ead_value), 2) AS max_ead,
    ROUND(STDDEV(ead_value)::numeric, 2) AS stddev_ead,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY ead_value)::numeric, 2) AS q1_ead,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY ead_value)::numeric, 2) AS q3_ead
FROM (
    SELECT CASE WHEN REPLACE(TRIM(ead), ',', '') ~ '^[0-9]+(\.[0-9]+)?$' THEN REPLACE(TRIM(ead), ',', '')::numeric END AS ead_value
    FROM loan_portfolio
) x WHERE ead_value IS NOT NULL;

-- 19. Descriptive statistics for RWA
SELECT
    COUNT(rwa) AS valid_rwa_count,
    ROUND(AVG(rwa)::numeric, 2) AS avg_rwa,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY rwa)::numeric, 2) AS median_rwa,
    ROUND(MIN(rwa)::numeric, 2) AS min_rwa,
    ROUND(MAX(rwa)::numeric, 2) AS max_rwa,
    ROUND(STDDEV(rwa)::numeric, 2) AS stddev_rwa,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY rwa)::numeric, 2) AS q1_rwa,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY rwa)::numeric, 2) AS q3_rwa
FROM loan_portfolio;

-- 20. Descriptive statistics for loan amount
SELECT
    COUNT(loan_amount) AS valid_loan_amount_count,
    ROUND(AVG(loan_amount)::numeric, 2) AS avg_loan_amount,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY loan_amount)::numeric, 2) AS median_loan_amount,
    ROUND(MIN(loan_amount)::numeric, 2) AS min_loan_amount,
    ROUND(MAX(loan_amount)::numeric, 2) AS max_loan_amount,
    ROUND(STDDEV(loan_amount)::numeric, 2) AS stddev_loan_amount,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY loan_amount)::numeric, 2) AS q1_loan_amount,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY loan_amount)::numeric, 2) AS q3_loan_amount
FROM loan_portfolio;

-- 21. Check negative values
SELECT
    SUM(CASE WHEN loan_amount < 0 THEN 1 ELSE 0 END) AS negative_loan_amount_count,
    SUM(CASE WHEN rwa < 0 THEN 1 ELSE 0 END) AS negative_rwa_count
FROM loan_portfolio;

-- 22. Check zero values
SELECT
    SUM(CASE WHEN loan_amount = 0 THEN 1 ELSE 0 END) AS zero_loan_amount_count,
    SUM(CASE WHEN rwa = 0 THEN 1 ELSE 0 END) AS zero_rwa_count
FROM loan_portfolio;

-- 23. Display records containing negative values
SELECT * FROM loan_portfolio WHERE loan_amount < 0 OR rwa < 0;

-- 24. Check suspicious PD and LGD values above 1
SELECT
    COUNT(*) FILTER (WHERE TRIM(pd_annual) ~ '^[0-9]+(\.[0-9]+)?$' AND TRIM(pd_annual)::numeric > 1) AS pd_above_1,
    COUNT(*) FILTER (WHERE TRIM(lgd) ~ '^[0-9]+(\.[0-9]+)?$' AND TRIM(lgd)::numeric > 1) AS lgd_above_1
FROM loan_portfolio;

-- 25. IQR Outliers for Loan Amount
WITH stats AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY loan_amount) AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY loan_amount) AS q3
    FROM loan_portfolio 
    WHERE loan_amount IS NOT NULL
),
bounds AS (
    SELECT 
        q1, 
        q3, 
        (q3 - q1) AS iqr,
        q1 - 1.5 * (q3 - q1) AS lower_bound,
        q3 + 1.5 * (q3 - q1) AS upper_bound
    FROM stats
)
SELECT 
    b.q1, b.q3, b.iqr, b.lower_bound, b.upper_bound,
    (SELECT COUNT(*) FROM loan_portfolio lp WHERE lp.loan_amount < b.lower_bound OR lp.loan_amount > b.upper_bound) AS outlier_count
FROM bounds b;

-- 26. IQR Outliers for RWA
WITH stats AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY rwa) AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY rwa) AS q3
    FROM loan_portfolio 
    WHERE rwa IS NOT NULL
),
bounds AS (
    SELECT 
        q1, 
        q3, 
        (q3 - q1) AS iqr,
        q1 - 1.5 * (q3 - q1) AS lower_bound,
        q3 + 1.5 * (q3 - q1) AS upper_bound
    FROM stats
)
SELECT 
    b.q1, b.q3, b.iqr, b.lower_bound, b.upper_bound,
    (SELECT COUNT(*) FROM loan_portfolio lp WHERE lp.rwa < b.lower_bound OR lp.rwa > b.upper_bound) AS outlier_count
FROM bounds b;

-- 27–33. Correlation Matrix Calculations
SELECT ROUND(CORR(loan_amount, rwa)::numeric, 4) AS correlation_loan_rwa FROM loan_portfolio WHERE loan_amount IS NOT NULL AND rwa IS NOT NULL;

SELECT ROUND(CORR(loan_amount, ead_val)::numeric, 4) AS correlation_loan_ead
FROM (SELECT loan_amount, CASE WHEN REPLACE(TRIM(ead), ',', '') ~ '^[0-9]+(\.[0-9]+)?$' THEN REPLACE(TRIM(ead), ',', '')::numeric END AS ead_val FROM loan_portfolio) x
WHERE loan_amount IS NOT NULL AND ead_val IS NOT NULL;

SELECT ROUND(CORR(pd_val, lgd_val)::numeric, 4) AS correlation_pd_lgd
FROM (SELECT 
        CASE WHEN TRIM(pd_annual) ~ '^[0-9]+(\.[0-9]+)?%$' THEN REPLACE(TRIM(pd_annual), '%', '')::numeric / 100 WHEN TRIM(pd_annual) ~ '^[0-9]+(\.[0-9]+)?$' THEN TRIM(pd_annual)::numeric END AS pd_val,
        CASE WHEN TRIM(lgd) ~ '^[0-9]+(\.[0-9]+)?$' THEN TRIM(lgd)::numeric END AS lgd_val
      FROM loan_portfolio) x WHERE pd_val IS NOT NULL AND lgd_val IS NOT NULL;

SELECT ROUND(CORR(pd_val, ead_val)::numeric, 4) AS correlation_pd_ead
FROM (SELECT 
        CASE WHEN TRIM(pd_annual) ~ '^[0-9]+(\.[0-9]+)?%$' THEN REPLACE(TRIM(pd_annual), '%', '')::numeric / 100 WHEN TRIM(pd_annual) ~ '^[0-9]+(\.[0-9]+)?$' THEN TRIM(pd_annual)::numeric END AS pd_val,
        CASE WHEN REPLACE(TRIM(ead), ',', '') ~ '^[0-9]+(\.[0-9]+)?$' THEN REPLACE(TRIM(ead), ',', '')::numeric END AS ead_val
      FROM loan_portfolio) x WHERE pd_val IS NOT NULL AND ead_val IS NOT NULL;

SELECT ROUND(CORR(lgd_val, ead_val)::numeric, 4) AS correlation_lgd_ead
FROM (SELECT 
        CASE WHEN TRIM(lgd) ~ '^[0-9]+(\.[0-9]+)?$' THEN TRIM(lgd)::numeric END AS lgd_val,
        CASE WHEN REPLACE(TRIM(ead), ',', '') ~ '^[0-9]+(\.[0-9]+)?$' THEN REPLACE(TRIM(ead), ',', '')::numeric END AS ead_val
      FROM loan_portfolio) x WHERE lgd_val IS NOT NULL AND ead_val IS NOT NULL;

SELECT ROUND(CORR(ead_val, rwa)::numeric, 4) AS correlation_ead_rwa
FROM (SELECT CASE WHEN REPLACE(TRIM(ead), ',', '') ~ '^[0-9]+(\.[0-9]+)?$' THEN REPLACE(TRIM(ead), ',', '')::numeric END AS ead_val, rwa FROM loan_portfolio) x
WHERE ead_val IS NOT NULL AND rwa IS NOT NULL;

SELECT ROUND(CORR(pd_val, loan_amount)::numeric, 4) AS correlation_pd_loan_amount
FROM (SELECT CASE WHEN TRIM(pd_annual) ~ '^[0-9]+(\.[0-9]+)?%$' THEN REPLACE(TRIM(pd_annual), '%', '')::numeric / 100 WHEN TRIM(pd_annual) ~ '^[0-9]+(\.[0-9]+)?$' THEN TRIM(pd_annual)::numeric END AS pd_val, loan_amount FROM loan_portfolio) x
WHERE pd_val IS NOT NULL AND loan_amount IS NOT NULL;

-- 34. Sector-level exposure metrics
SELECT sector, COUNT(*) AS loan_count, ROUND(SUM(loan_amount)::numeric, 2) AS total_loan_exposure, ROUND(AVG(loan_amount)::numeric, 2) AS avg_loan_size, ROUND(MIN(loan_amount)::numeric, 2) AS min_loan, ROUND(MAX(loan_amount)::numeric, 2) AS max_loan
FROM loan_portfolio WHERE loan_amount IS NOT NULL GROUP BY sector ORDER BY total_loan_exposure DESC;

-- 35. Average PD and LGD by sector
SELECT sector, COUNT(*) AS loan_count, ROUND(AVG(pd_val)::numeric, 4) AS avg_pd, ROUND(AVG(lgd_val)::numeric, 4) AS avg_lgd
FROM (SELECT sector,
        CASE WHEN TRIM(pd_annual) ~ '^[0-9]+(\.[0-9]+)?%$' THEN REPLACE(TRIM(pd_annual), '%', '')::numeric / 100 WHEN TRIM(pd_annual) ~ '^[0-9]+(\.[0-9]+)?$' THEN TRIM(pd_annual)::numeric END AS pd_val,
        CASE WHEN TRIM(lgd) ~ '^[0-9]+(\.[0-9]+)?$' THEN TRIM(lgd)::numeric END AS lgd_val
      FROM loan_portfolio) x GROUP BY sector ORDER BY avg_pd DESC;

-- 36. Average RWA-to-loan ratio by sector
SELECT sector, COUNT(*) AS loan_count, ROUND(AVG(rwa / NULLIF(loan_amount, 0))::numeric, 4) AS avg_risk_weight_ratio
FROM loan_portfolio WHERE loan_amount > 0 AND rwa IS NOT NULL GROUP BY sector ORDER BY avg_risk_weight_ratio DESC;

-- 37. Distribution of loans by loan amount range (Fixed ORDER BY)
SELECT
    CASE
        WHEN loan_amount < 100000 THEN '< 100K'
        WHEN loan_amount < 500000 THEN '100K - 500K'
        WHEN loan_amount < 1000000 THEN '500K - 1M'
        WHEN loan_amount < 5000000 THEN '1M - 5M'
        ELSE '5M+'
    END AS loan_amount_range,
    COUNT(*) AS loan_count
FROM loan_portfolio
WHERE loan_amount >= 0
GROUP BY 1
ORDER BY MIN(loan_amount) ASC;

-- 38. Distribution of records by RWA range (Fixed ORDER BY)
SELECT
    CASE
        WHEN rwa < 100000 THEN '< 100K'
        WHEN rwa < 500000 THEN '100K - 500K'
        WHEN rwa < 1000000 THEN '500K - 1M'
        WHEN rwa < 5000000 THEN '1M - 5M'
        ELSE '5M+'
    END AS rwa_range,
    COUNT(*) AS record_count
FROM loan_portfolio
WHERE rwa IS NOT NULL AND rwa >= 0
GROUP BY 1
ORDER BY MIN(rwa) ASC;