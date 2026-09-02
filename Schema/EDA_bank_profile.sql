-- 1. Total rows and unique bank IDs
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT bank_id) AS unique_bank_ids,
    COUNT(*) - COUNT(DISTINCT bank_id) AS duplicate_id_count
FROM bank_profiles;


-- 2. Identify duplicate bank IDs
SELECT
    bank_id,
    COUNT(*) AS occurrence_count
FROM bank_profiles
GROUP BY bank_id
HAVING COUNT(*) > 1
ORDER BY occurrence_count DESC;


-- 3. Display complete duplicate records
SELECT *
FROM bank_profiles
WHERE bank_id IN (
    SELECT bank_id
    FROM bank_profiles
    GROUP BY bank_id
    HAVING COUNT(*) > 1
)
ORDER BY bank_id;


-- 4. Check explicit NULL values
SELECT
    COUNT(*) FILTER (WHERE bank_id IS NULL) AS null_bank_id,
    COUNT(*) FILTER (WHERE size_tier IS NULL) AS null_size_tier,
    COUNT(*) FILTER (WHERE total_assets_usd IS NULL) AS null_total_assets,
    COUNT(*) FILTER (WHERE total_loans_usd IS NULL) AS null_total_loans,
    COUNT(*) FILTER (WHERE deposit_base_usd IS NULL) AS null_deposit_base,
    COUNT(*) FILTER (WHERE baseline_car_pct IS NULL) AS null_car,
    COUNT(*) FILTER (WHERE baseline_liquidity_ratio_pct IS NULL) AS null_liquidity_ratio,
    COUNT(*) FILTER (WHERE baseline_roa_pct IS NULL) AS null_roa,
    COUNT(*) FILTER (WHERE sector_concentration IS NULL) AS null_sector_concentration,
    COUNT(*) FILTER (WHERE bank_risk_factor IS NULL) AS null_bank_risk_factor
FROM bank_profiles;


-- 5. Check blank values in text columns
SELECT
    COUNT(*) FILTER (WHERE TRIM(bank_id) = '') AS blank_bank_id,
    COUNT(*) FILTER (WHERE TRIM(size_tier) = '') AS blank_size_tier,
    COUNT(*) FILTER (WHERE TRIM(baseline_car_pct) = '') AS blank_car,
    COUNT(*) FILTER (WHERE TRIM(baseline_roa_pct) = '') AS blank_roa,
    COUNT(*) FILTER (WHERE TRIM(sector_concentration) = '') AS blank_sector_concentration
FROM bank_profiles;


-- 6. Check common placeholder values
SELECT
    COUNT(*) FILTER (
        WHERE LOWER(TRIM(baseline_car_pct)) IN ('', '-', '--', 'na', 'n/a', 'null', 'missing', 'unknown', 'n.a.', 'not available')
    ) AS placeholder_car,
    COUNT(*) FILTER (
        WHERE LOWER(TRIM(baseline_liquidity_ratio_pct)) IN ('', '-', '--', 'na', 'n/a', 'null', 'missing', 'unknown', 'n.a.', 'not available')
    ) AS placeholder_liquidity,
    COUNT(*) FILTER (
        WHERE LOWER(TRIM(baseline_roa_pct)) IN ('', '-', '--', 'na', 'n/a', 'null', 'missing', 'unknown', 'n.a.', 'not available')
    ) AS placeholder_roa,
    COUNT(*) FILTER (
        WHERE LOWER(TRIM(sector_concentration)) IN ('', '-', '--', 'na', 'n/a', 'null', 'missing', 'unknown', 'n.a.', 'not available')
    ) AS placeholder_sector_concentration
FROM bank_profiles;


-- 7. Raw size tier values and frequencies
SELECT
    size_tier AS raw_size_tier,
    COUNT(*) AS bank_count
FROM bank_profiles
GROUP BY size_tier
ORDER BY bank_count DESC;


-- 8. Raw sector concentration values and frequencies
SELECT
    sector_concentration AS raw_sector_concentration,
    COUNT(*) AS bank_count
FROM bank_profiles
GROUP BY sector_concentration
ORDER BY bank_count DESC;


-- 9. Count distinct size tier labels
SELECT
    COUNT(DISTINCT size_tier) AS distinct_size_tier_labels
FROM bank_profiles;


-- 10. Count distinct sector concentration labels
SELECT
    COUNT(DISTINCT sector_concentration) AS distinct_sector_concentration_labels
FROM bank_profiles;


-- 11. Detect size tier values that differ only by capitalization or spaces
SELECT
    LOWER(TRIM(size_tier)) AS normalized_size_tier_for_analysis,
    COUNT(*) AS bank_count,
    STRING_AGG(DISTINCT size_tier, ', ') AS raw_values
FROM bank_profiles
GROUP BY LOWER(TRIM(size_tier))
ORDER BY bank_count DESC;


-- 12. Detect sector concentration values that differ only by capitalization or spaces
SELECT
    LOWER(TRIM(sector_concentration)) AS normalized_concentration_for_analysis,
    COUNT(*) AS bank_count,
    STRING_AGG(DISTINCT sector_concentration, ', ') AS raw_values
FROM bank_profiles
GROUP BY LOWER(TRIM(sector_concentration))
ORDER BY bank_count DESC;


-- 13. Check total assets formatting
SELECT
    COUNT(*) FILTER (WHERE total_assets_usd LIKE '$%') AS assets_with_dollar_sign,
    COUNT(*) FILTER (WHERE total_assets_usd LIKE '%,%') AS assets_with_commas
FROM bank_profiles;


-- 14. Check CAR percentage formatting
SELECT
    COUNT(*) FILTER (WHERE baseline_car_pct LIKE '%\%' ESCAPE '\') AS car_with_percent_sign,
    COUNT(*) FILTER (WHERE TRIM(baseline_car_pct) ~ '^[0-9]+(\.[0-9]+)?$') AS car_plain_numeric,
    COUNT(*) FILTER (
        WHERE TRIM(baseline_car_pct) !~ '^[0-9]+(\.[0-9]+)?%?$'
          AND TRIM(baseline_car_pct) <> ''
          AND baseline_car_pct IS NOT NULL
    ) AS car_non_numeric
FROM bank_profiles;


-- 15. Check liquidity ratio percentage formatting
SELECT
    COUNT(*) FILTER (WHERE baseline_liquidity_ratio_pct LIKE '%\%' ESCAPE '\') AS liquidity_with_percent_sign,
    COUNT(*) FILTER (WHERE TRIM(baseline_liquidity_ratio_pct) ~ '^[0-9]+(\.[0-9]+)?$') AS liquidity_plain_numeric
FROM bank_profiles;


-- 16. Check ROA percentage formatting
SELECT
    COUNT(*) FILTER (WHERE baseline_roa_pct LIKE '%\%' ESCAPE '\') AS roa_with_percent_sign
FROM bank_profiles;


-- 17. Find non-numeric CAR values
SELECT
    baseline_car_pct AS raw_car_value,
    COUNT(*) AS frequency
FROM bank_profiles
WHERE baseline_car_pct IS NOT NULL
  AND TRIM(baseline_car_pct) <> ''
  AND TRIM(baseline_car_pct) !~ '^[0-9]+(\.[0-9]+)?%?$'
GROUP BY baseline_car_pct
ORDER BY frequency DESC;


-- 18. Find non-numeric ROA values
SELECT
    baseline_roa_pct AS raw_roa_value,
    COUNT(*) AS frequency
FROM bank_profiles
WHERE baseline_roa_pct IS NOT NULL
  AND TRIM(baseline_roa_pct) <> ''
  AND TRIM(baseline_roa_pct) !~ '^[0-9]+(\.[0-9]+)?%?$'
GROUP BY baseline_roa_pct
ORDER BY frequency DESC;


-- 19. Find negative total assets
SELECT
    COUNT(*) AS negative_total_assets_count
FROM bank_profiles
WHERE NULLIF(REGEXP_REPLACE(total_assets_usd, '[^0-9.-]', '', 'g'), '')::numeric < 0;


-- 20. Display records with negative total assets
SELECT *
FROM bank_profiles
WHERE NULLIF(REGEXP_REPLACE(total_assets_usd, '[^0-9.-]', '', 'g'), '')::numeric < 0;


-- 21. Check zero values in major financial columns
SELECT
    COUNT(*) FILTER (WHERE NULLIF(REGEXP_REPLACE(total_assets_usd, '[^0-9.-]', '', 'g'), '')::numeric = 0) AS zero_total_assets,
    COUNT(*) FILTER (WHERE total_loans_usd = 0) AS zero_total_loans,
    COUNT(*) FILTER (WHERE deposit_base_usd = 0) AS zero_deposit_base
FROM bank_profiles;


-- 22. Check negative values in major financial columns
SELECT
    COUNT(*) FILTER (WHERE NULLIF(REGEXP_REPLACE(total_assets_usd, '[^0-9.-]', '', 'g'), '')::numeric < 0) AS negative_total_assets,
    COUNT(*) FILTER (WHERE total_loans_usd < 0) AS negative_total_loans,
    COUNT(*) FILTER (WHERE deposit_base_usd < 0) AS negative_deposit_base,
    COUNT(*) FILTER (WHERE bank_risk_factor < 0) AS negative_bank_risk_factor
FROM bank_profiles;


-- 23. Check financial consistency: loans greater than assets
SELECT
    COUNT(*) AS loans_greater_than_assets
FROM bank_profiles
WHERE total_loans_usd > NULLIF(REGEXP_REPLACE(total_assets_usd, '[^0-9.-]', '', 'g'), '')::numeric;


-- 24. Display banks where loans exceed assets
SELECT
    bank_id,
    total_assets_usd,
    total_loans_usd
FROM bank_profiles
WHERE total_loans_usd > NULLIF(REGEXP_REPLACE(total_assets_usd, '[^0-9.-]', '', 'g'), '')::numeric
ORDER BY (total_loans_usd - NULLIF(REGEXP_REPLACE(total_assets_usd, '[^0-9.-]', '', 'g'), '')::numeric) DESC;


-- 25. Check financial consistency: deposits greater than assets
SELECT
    COUNT(*) AS deposits_greater_than_assets
FROM bank_profiles
WHERE deposit_base_usd > NULLIF(REGEXP_REPLACE(total_assets_usd, '[^0-9.-]', '', 'g'), '')::numeric;


-- 26. Check financial consistency: deposits greater than loans
SELECT
    COUNT(*) AS deposits_greater_than_loans
FROM bank_profiles
WHERE deposit_base_usd > total_loans_usd;


-- 27. Descriptive statistics for total assets
WITH clean_assets AS (
    SELECT NULLIF(REGEXP_REPLACE(total_assets_usd, '[^0-9.-]', '', 'g'), '')::numeric AS asset_num
    FROM bank_profiles
)
SELECT
    COUNT(asset_num) AS valid_count,
    ROUND(AVG(asset_num), 2) AS mean,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY asset_num)::numeric, 2) AS median,
    ROUND(MIN(asset_num), 2) AS min,
    ROUND(MAX(asset_num), 2) AS max,
    ROUND(STDDEV(asset_num), 2) AS stddev,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY asset_num)::numeric, 2) AS q1,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY asset_num)::numeric, 2) AS q3
FROM clean_assets;


-- 28. Descriptive statistics for total loans
SELECT
    COUNT(total_loans_usd) AS valid_count,
    ROUND(AVG(total_loans_usd)::numeric, 2) AS mean,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY total_loans_usd)::numeric, 2) AS median,
    ROUND(MIN(total_loans_usd)::numeric, 2) AS min,
    ROUND(MAX(total_loans_usd)::numeric, 2) AS max,
    ROUND(STDDEV(total_loans_usd)::numeric, 2) AS stddev,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_loans_usd)::numeric, 2) AS q1,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_loans_usd)::numeric, 2) AS q3
FROM bank_profiles;


-- 29. Descriptive statistics for deposit base
SELECT
    COUNT(deposit_base_usd) AS valid_count,
    ROUND(AVG(deposit_base_usd)::numeric, 2) AS mean,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY deposit_base_usd)::numeric, 2) AS median,
    ROUND(MIN(deposit_base_usd)::numeric, 2) AS min,
    ROUND(MAX(deposit_base_usd)::numeric, 2) AS max,
    ROUND(STDDEV(deposit_base_usd)::numeric, 2) AS stddev,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY deposit_base_usd)::numeric, 2) AS q1,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY deposit_base_usd)::numeric, 2) AS q3
FROM bank_profiles;


-- 30. Descriptive statistics for bank risk factor
SELECT
    COUNT(bank_risk_factor) AS valid_count,
    ROUND(AVG(bank_risk_factor)::numeric, 4) AS mean,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY bank_risk_factor)::numeric, 4) AS median,
    ROUND(MIN(bank_risk_factor)::numeric, 4) AS min,
    ROUND(MAX(bank_risk_factor)::numeric, 4) AS max,
    ROUND(STDDEV(bank_risk_factor)::numeric, 4) AS stddev,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY bank_risk_factor)::numeric, 4) AS q1,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY bank_risk_factor)::numeric, 4) AS q3
FROM bank_profiles;


-- 31. Basic statistics for CAR
WITH clean_car AS (
    SELECT NULLIF(REGEXP_REPLACE(baseline_car_pct, '[^0-9.-]', '', 'g'), '')::numeric AS car_num
    FROM bank_profiles
    WHERE TRIM(baseline_car_pct) ~ '^[0-9]+(\.[0-9]+)?%?$'
)
SELECT
    COUNT(car_num) AS valid_car_count,
    ROUND(AVG(car_num), 4) AS mean_car,
    ROUND(MIN(car_num), 4) AS min_car,
    ROUND(MAX(car_num), 4) AS max_car
FROM clean_car;


-- 32. Basic statistics for liquidity ratio
WITH clean_liq AS (
    SELECT NULLIF(REGEXP_REPLACE(baseline_liquidity_ratio_pct, '[^0-9.-]', '', 'g'), '')::numeric AS liq_num
    FROM bank_profiles
)
SELECT
    COUNT(liq_num) AS valid_liquidity_count,
    ROUND(AVG(liq_num), 4) AS mean_liquidity,
    ROUND(MIN(liq_num), 4) AS min_liquidity,
    ROUND(MAX(liq_num), 4) AS max_liquidity,
    ROUND(STDDEV(liq_num), 4) AS stddev_liquidity
FROM clean_liq;


-- 33. Basic statistics for ROA
WITH clean_roa AS (
    SELECT NULLIF(REGEXP_REPLACE(baseline_roa_pct, '[^0-9.-]', '', 'g'), '')::numeric AS roa_num
    FROM bank_profiles
    WHERE TRIM(baseline_roa_pct) ~ '^-?[0-9]+(\.[0-9]+)?%?$'
)
SELECT
    COUNT(roa_num) AS valid_roa_count,
    ROUND(AVG(roa_num), 4) AS mean_roa,
    ROUND(MIN(roa_num), 4) AS min_roa,
    ROUND(MAX(roa_num), 4) AS max_roa
FROM clean_roa;


-- 34. Check suspicious CAR values
SELECT
    bank_id,
    baseline_car_pct
FROM bank_profiles
WHERE CASE 
        WHEN REGEXP_REPLACE(baseline_car_pct, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
        THEN REGEXP_REPLACE(baseline_car_pct, '[^0-9.-]', '', 'g')::numeric 
      END < 0
   OR CASE 
        WHEN REGEXP_REPLACE(baseline_car_pct, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
        THEN REGEXP_REPLACE(baseline_car_pct, '[^0-9.-]', '', 'g')::numeric 
      END > 100;
-- 35. Check suspicious ROA values
SELECT
    bank_id,
    baseline_roa_pct
FROM bank_profiles
WHERE NULLIF(REGEXP_REPLACE(baseline_roa_pct, '[^0-9.-]', '', 'g'), '')::numeric < -100
   OR NULLIF(REGEXP_REPLACE(baseline_roa_pct, '[^0-9.-]', '', 'g'), '')::numeric > 100;


-- 36. IQR outliers for total assets
WITH clean_data AS (
    SELECT 
        bank_id,
        NULLIF(REGEXP_REPLACE(total_assets_usd, '[^0-9.-]', '', 'g'), '')::numeric AS asset_num
    FROM bank_profiles
),
stats AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY asset_num) AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY asset_num) AS q3
    FROM clean_data
    WHERE asset_num IS NOT NULL AND asset_num >= 0
)
SELECT
    q1,
    q3,
    (q3 - q1) AS iqr,
    (q1 - 1.5 * (q3 - q1)) AS lower_bound,
    (q3 + 1.5 * (q3 - q1)) AS upper_bound,
    COUNT(*) FILTER (
        WHERE cd.asset_num < (q1 - 1.5 * (q3 - q1))
           OR cd.asset_num > (q3 + 1.5 * (q3 - q1))
    ) AS outlier_count
FROM stats
CROSS JOIN clean_data cd
WHERE cd.asset_num IS NOT NULL
GROUP BY q1, q3;


-- 37. IQR outliers for total loans
WITH stats AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_loans_usd) AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_loans_usd) AS q3
    FROM bank_profiles
    WHERE total_loans_usd IS NOT NULL AND total_loans_usd >= 0
)
SELECT
    q1,
    q3,
    (q3 - q1) AS iqr,
    (q1 - 1.5 * (q3 - q1)) AS lower_bound,
    (q3 + 1.5 * (q3 - q1)) AS upper_bound,
    COUNT(*) FILTER (
        WHERE total_loans_usd < (q1 - 1.5 * (q3 - q1))
           OR total_loans_usd > (q3 + 1.5 * (q3 - q1))
    ) AS outlier_count
FROM stats
CROSS JOIN bank_profiles
WHERE total_loans_usd IS NOT NULL
GROUP BY q1, q3;


-- 38. IQR outliers for deposit base
WITH stats AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY deposit_base_usd) AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY deposit_base_usd) AS q3
    FROM bank_profiles
    WHERE deposit_base_usd IS NOT NULL AND deposit_base_usd >= 0
)
SELECT
    q1,
    q3,
    (q3 - q1) AS iqr,
    (q1 - 1.5 * (q3 - q1)) AS lower_bound,
    (q3 + 1.5 * (q3 - q1)) AS upper_bound,
    COUNT(*) FILTER (
        WHERE deposit_base_usd < (q1 - 1.5 * (q3 - q1))
           OR deposit_base_usd > (q3 + 1.5 * (q3 - q1))
    ) AS outlier_count
FROM stats
CROSS JOIN bank_profiles
WHERE deposit_base_usd IS NOT NULL
GROUP BY q1, q3;


-- 39. Correlation between total assets and total loans
WITH clean_data AS (
    SELECT 
        NULLIF(REGEXP_REPLACE(total_assets_usd, '[^0-9.-]', '', 'g'), '')::numeric AS asset_num,
        total_loans_usd
    FROM bank_profiles
)
SELECT
    ROUND(CORR(asset_num, total_loans_usd)::numeric, 4) AS correlation_assets_loans
FROM clean_data
WHERE asset_num >= 0 AND total_loans_usd >= 0;


-- 40. Correlation between total assets and deposit base
WITH clean_data AS (
    SELECT 
        NULLIF(REGEXP_REPLACE(total_assets_usd, '[^0-9.-]', '', 'g'), '')::numeric AS asset_num,
        deposit_base_usd
    FROM bank_profiles
)
SELECT
    ROUND(CORR(asset_num, deposit_base_usd)::numeric, 4) AS correlation_assets_deposits
FROM clean_data
WHERE asset_num >= 0 AND deposit_base_usd >= 0;


-- 41. Correlation between total loans and deposit base
SELECT
    ROUND(CORR(total_loans_usd, deposit_base_usd)::numeric, 4) AS correlation_loans_deposits
FROM bank_profiles
WHERE total_loans_usd >= 0 AND deposit_base_usd >= 0;


-- 42. Correlation between bank risk factor and financial size
WITH clean_data AS (
    SELECT 
        NULLIF(REGEXP_REPLACE(total_assets_usd, '[^0-9.-]', '', 'g'), '')::numeric AS asset_num,
        bank_risk_factor
    FROM bank_profiles
)
SELECT
    ROUND(CORR(bank_risk_factor, asset_num)::numeric, 4) AS correlation_risk_assets
FROM clean_data
WHERE asset_num >= 0;



-- 43. Loan-to-asset ratio by bank
SELECT
    bank_id,
    ROUND((total_loans_usd / NULLIF(
        CASE 
            WHEN REGEXP_REPLACE(total_assets_usd, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
            THEN REGEXP_REPLACE(total_assets_usd, '[^0-9.-]', '', 'g')::numeric 
        END, 0))::numeric, 4) AS loan_to_asset_ratio
FROM bank_profiles
WHERE CASE 
        WHEN REGEXP_REPLACE(total_assets_usd, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
        THEN REGEXP_REPLACE(total_assets_usd, '[^0-9.-]', '', 'g')::numeric 
      END > 0
  AND total_loans_usd >= 0
ORDER BY loan_to_asset_ratio DESC;

-- 44. Deposit-to-asset ratio by bank
SELECT
    bank_id,
    ROUND((deposit_base_usd / NULLIF(
        CASE 
            WHEN REGEXP_REPLACE(total_assets_usd, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
            THEN REGEXP_REPLACE(total_assets_usd, '[^0-9.-]', '', 'g')::numeric 
        END, 0))::numeric, 4) AS deposit_to_asset_ratio
FROM bank_profiles
WHERE CASE 
        WHEN REGEXP_REPLACE(total_assets_usd, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
        THEN REGEXP_REPLACE(total_assets_usd, '[^0-9.-]', '', 'g')::numeric 
      END > 0
  AND deposit_base_usd >= 0
ORDER BY deposit_to_asset_ratio DESC;


-- 45. Loan-to-deposit ratio by bank
SELECT
    bank_id,
    ROUND((total_loans_usd / NULLIF(deposit_base_usd, 0))::numeric, 4) AS loan_to_deposit_ratio
FROM bank_profiles
WHERE total_loans_usd >= 0 AND deposit_base_usd > 0
ORDER BY loan_to_deposit_ratio DESC;


-- 46. Sector weight totals by bank
SELECT
    bank_id,
    ROUND((
        "sector_wt_Technology" +
        "sector_wt_Healthcare" +
        "sector_wt_Real_Estate" +
        "sector_wt_Energy" +
        "sector_wt_Industrials" +
        "sector_wt_Retail" +
        "sector_wt_Telecom" +
        "sector_wt_Consumer" +
        "sector_wt_Utilities" +
        "sector_wt_Financials"
    )::numeric, 4) AS total_sector_weight
FROM bank_profiles
ORDER BY total_sector_weight DESC;


-- 47. Identify banks whose sector weights do not sum approximately to 1
SELECT
    bank_id,
    ROUND((
        "sector_wt_Technology" +
        "sector_wt_Healthcare" +
        "sector_wt_Real_Estate" +
        "sector_wt_Energy" +
        "sector_wt_Industrials" +
        "sector_wt_Retail" +
        "sector_wt_Telecom" +
        "sector_wt_Consumer" +
        "sector_wt_Utilities" +
        "sector_wt_Financials"
    )::numeric, 4) AS total_sector_weight
FROM bank_profiles
WHERE ABS((
        "sector_wt_Technology" +
        "sector_wt_Healthcare" +
        "sector_wt_Real_Estate" +
        "sector_wt_Energy" +
        "sector_wt_Industrials" +
        "sector_wt_Retail" +
        "sector_wt_Telecom" +
        "sector_wt_Consumer" +
        "sector_wt_Utilities" +
        "sector_wt_Financials"
    ) - 1) > 0.01;


-- 48. Check negative sector weights
SELECT bank_id
FROM bank_profiles
WHERE "sector_wt_Technology" < 0 OR "sector_wt_Healthcare" < 0 OR "sector_wt_Real_Estate" < 0
   OR "sector_wt_Energy" < 0 OR "sector_wt_Industrials" < 0 OR "sector_wt_Retail" < 0
   OR "sector_wt_Telecom" < 0 OR "sector_wt_Consumer" < 0 OR "sector_wt_Utilities" < 0 OR "sector_wt_Financials" < 0;


-- 49. Check sector weights above 1
SELECT bank_id
FROM bank_profiles
WHERE "sector_wt_Technology" > 1 OR "sector_wt_Healthcare" > 1 OR "sector_wt_Real_Estate" > 1
   OR "sector_wt_Energy" > 1 OR "sector_wt_Industrials" > 1 OR "sector_wt_Retail" > 1
   OR "sector_wt_Telecom" > 1 OR "sector_wt_Consumer" > 1 OR "sector_wt_Utilities" > 1 OR "sector_wt_Financials" > 1;


-- 50. Sector weight statistics
SELECT
    ROUND(AVG("sector_wt_Technology")::numeric, 4) AS avg_technology,
    ROUND(AVG("sector_wt_Healthcare")::numeric, 4) AS avg_healthcare,
    ROUND(AVG("sector_wt_Real_Estate")::numeric, 4) AS avg_real_estate,
    ROUND(AVG("sector_wt_Energy")::numeric, 4) AS avg_energy,
    ROUND(AVG("sector_wt_Industrials")::numeric, 4) AS avg_industrials,
    ROUND(AVG("sector_wt_Retail")::numeric, 4) AS avg_retail,
    ROUND(AVG("sector_wt_Telecom")::numeric, 4) AS avg_telecom,
    ROUND(AVG("sector_wt_Consumer")::numeric, 4) AS avg_consumer,
    ROUND(AVG("sector_wt_Utilities")::numeric, 4) AS avg_utilities,
    ROUND(AVG("sector_wt_Financials")::numeric, 4) AS avg_financials
FROM bank_profiles;

-- 51. Zero sector weights
SELECT
    COUNT(*) FILTER (WHERE "sector_wt_Technology" = 0) AS zero_technology,
    COUNT(*) FILTER (WHERE "sector_wt_Healthcare" = 0) AS zero_healthcare,
    COUNT(*) FILTER (WHERE "sector_wt_Real_Estate" = 0) AS zero_real_estate,
    COUNT(*) FILTER (WHERE "sector_wt_Energy" = 0) AS zero_energy,
    COUNT(*) FILTER (WHERE "sector_wt_Industrials" = 0) AS zero_industrials,
    COUNT(*) FILTER (WHERE "sector_wt_Retail" = 0) AS zero_retail,
    COUNT(*) FILTER (WHERE "sector_wt_Telecom" = 0) AS zero_telecom,
    COUNT(*) FILTER (WHERE "sector_wt_Consumer" = 0) AS zero_consumer,
    COUNT(*) FILTER (WHERE "sector_wt_Utilities" = 0) AS zero_utilities,
    COUNT(*) FILTER (WHERE "sector_wt_Financials" = 0) AS zero_financials
FROM bank_profiles;


-- 52. Bank-level size tier summary
SELECT
    size_tier,
    COUNT(*) AS bank_count,
    ROUND(AVG(NULLIF(REGEXP_REPLACE(total_assets_usd, '[^0-9.-]', '', 'g'), '')::numeric), 2) AS avg_assets,
    ROUND(AVG(total_loans_usd)::numeric, 2) AS avg_loans,
    ROUND(AVG(deposit_base_usd)::numeric, 2) AS avg_deposits
FROM bank_profiles
WHERE total_assets_usd IS NOT NULL
GROUP BY size_tier
ORDER BY avg_assets DESC;


-- 53. Sector concentration summary
SELECT
    sector_concentration,
    COUNT(*) AS bank_count,
    ROUND(AVG(NULLIF(REGEXP_REPLACE(total_assets_usd, '[^0-9.-]', '', 'g'), '')::numeric), 2) AS avg_assets,
    ROUND(AVG(total_loans_usd)::numeric, 2) AS avg_loans,
    ROUND(AVG(bank_risk_factor)::numeric, 4) AS avg_risk_factor
FROM bank_profiles
GROUP BY sector_concentration
ORDER BY bank_count DESC;


-- 54. Identify unusually high sector concentration weights
	SELECT
    bank_id,
    GREATEST(
        "sector_wt_Technology", "sector_wt_Healthcare", "sector_wt_Real_Estate",
        "sector_wt_Energy", "sector_wt_Industrials", "sector_wt_Retail",
        "sector_wt_Telecom", "sector_wt_Consumer", "sector_wt_Utilities", "sector_wt_Financials"
    ) AS highest_sector_weight
FROM bank_profiles
ORDER BY highest_sector_weight DESC;

-- 55. Identify banks with highly concentrated sector exposure
SELECT
    bank_id,
    GREATEST(
        "sector_wt_Technology", "sector_wt_Healthcare", "sector_wt_Real_Estate",
        "sector_wt_Energy", "sector_wt_Industrials", "sector_wt_Retail",
        "sector_wt_Telecom", "sector_wt_Consumer", "sector_wt_Utilities", "sector_wt_Financials"
    ) AS highest_sector_weight
FROM bank_profiles
WHERE GREATEST(
        "sector_wt_Technology", "sector_wt_Healthcare", "sector_wt_Real_Estate",
        "sector_wt_Energy", "sector_wt_Industrials", "sector_wt_Retail",
        "sector_wt_Telecom", "sector_wt_Consumer", "sector_wt_Utilities", "sector_wt_Financials"
    ) > 0.40
ORDER BY highest_sector_weight DESC;

-- 56. Compare bank risk factor across size tiers
SELECT
    size_tier,
    COUNT(*) AS bank_count,
    ROUND(AVG(bank_risk_factor)::numeric, 4) AS avg_risk_factor,
    ROUND(MIN(bank_risk_factor)::numeric, 4) AS min_risk_factor,
    ROUND(MAX(bank_risk_factor)::numeric, 4) AS max_risk_factor
FROM bank_profiles
WHERE bank_risk_factor IS NOT NULL
GROUP BY size_tier
ORDER BY avg_risk_factor DESC;


-- 57. Identify records with unusual placeholder or suspicious values across important fields
SELECT *
FROM bank_profiles
WHERE LOWER(TRIM(COALESCE(size_tier, ''))) IN ('', 'na', 'n/a', 'null', 'unknown', 'missing', '-', '--')
   OR LOWER(TRIM(COALESCE(baseline_car_pct, ''))) IN ('', 'na', 'n/a', 'null', 'unknown', 'missing', '-', '--')
   OR LOWER(TRIM(COALESCE(baseline_roa_pct, ''))) IN ('', 'na', 'n/a', 'null', 'unknown', 'missing', '-', '--')
   OR LOWER(TRIM(COALESCE(sector_concentration, ''))) IN ('', 'na', 'n/a', 'null', 'unknown', 'missing', '-', '--')
   OR NULLIF(REGEXP_REPLACE(total_assets_usd, '[^0-9.-]', '', 'g'), '')::numeric < 0;


-- 58. Check whether each bank ID follows a consistent format
SELECT
    bank_id,
    COUNT(*) AS frequency
FROM bank_profiles
WHERE bank_id !~ '^BANK_[0-9]{3}$'
GROUP BY bank_id
ORDER BY frequency DESC;


-- 59. Overall bank size distribution
WITH clean_data AS (
    SELECT NULLIF(REGEXP_REPLACE(total_assets_usd, '[^0-9.-]', '', 'g'), '')::numeric AS asset_num
    FROM bank_profiles
)
SELECT
    CASE
        WHEN asset_num < 5000000000 THEN '< 5B'
        WHEN asset_num < 10000000000 THEN '5B - 10B'
        WHEN asset_num < 25000000000 THEN '10B - 25B'
        WHEN asset_num < 50000000000 THEN '25B - 50B'
        ELSE '50B+'
    END AS asset_size_range,
    COUNT(*) AS bank_count
FROM clean_data
WHERE asset_num >= 0
GROUP BY 1
ORDER BY
    CASE
        WHEN MIN(asset_num) < 5000000000 THEN 1
        WHEN MIN(asset_num) < 10000000000 THEN 2
        WHEN MIN(asset_num) < 25000000000 THEN 3
        WHEN MIN(asset_num) < 50000000000 THEN 4
        ELSE 5
    END;