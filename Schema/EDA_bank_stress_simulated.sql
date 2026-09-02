-- 1. Total rows
SELECT COUNT(*) AS total_rows
FROM bank_stress_simulated_panel;


-- 2. Unique banks
SELECT COUNT(DISTINCT bank_id) AS unique_banks
FROM bank_stress_simulated_panel;


-- 3. Unique scenarios
SELECT COUNT(DISTINCT scenario_id) AS unique_scenarios
FROM bank_stress_simulated_panel;


-- 4. List all scenarios
SELECT scenario_id, COUNT(*) AS row_count
FROM bank_stress_simulated_panel
GROUP BY scenario_id
ORDER BY scenario_id;


-- 5. Rows per bank
SELECT bank_id, COUNT(*) AS scenario_rows
FROM bank_stress_simulated_panel
GROUP BY bank_id
ORDER BY scenario_rows, bank_id;


-- 6. Duplicate bank + scenario combinations
SELECT
    bank_id,
    scenario_id,
    COUNT(*) AS duplicate_count
FROM bank_stress_simulated_panel
GROUP BY bank_id, scenario_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;


-- 7. NULL values
SELECT
    COUNT(*) FILTER (WHERE bank_id IS NULL) AS bank_id_nulls,
    COUNT(*) FILTER (WHERE scenario_id IS NULL) AS scenario_id_nulls,
    COUNT(*) FILTER (WHERE size_tier IS NULL) AS size_tier_nulls,
    COUNT(*) FILTER (WHERE sector_concentration IS NULL) AS sector_concentration_nulls,
    COUNT(*) FILTER (WHERE total_assets_usd IS NULL) AS total_assets_nulls,
    COUNT(*) FILTER (WHERE total_loans_usd IS NULL) AS total_loans_nulls,
    COUNT(*) FILTER (WHERE baseline_car_pct IS NULL) AS baseline_car_nulls,
    COUNT(*) FILTER (WHERE baseline_liquidity_ratio_pct IS NULL) AS baseline_liquidity_nulls,
    COUNT(*) FILTER (WHERE baseline_roa_pct IS NULL) AS baseline_roa_nulls,
    COUNT(*) FILTER (WHERE gdp_shock_pp IS NULL) AS gdp_nulls,
    COUNT(*) FILTER (WHERE unemp_shock_pp IS NULL) AS unemployment_nulls,
    COUNT(*) FILTER (WHERE rate_shock_pp IS NULL) AS rate_nulls,
    COUNT(*) FILTER (WHERE credit_spread_bps IS NULL) AS credit_spread_nulls,
    COUNT(*) FILTER (WHERE inflation_shock_pp IS NULL) AS inflation_nulls,
    COUNT(*) FILTER (WHERE fx_devaluation_pct IS NULL) AS fx_nulls,
    COUNT(*) FILTER (WHERE scenario_severity IS NULL) AS scenario_severity_nulls,
    COUNT(*) FILTER (WHERE weighted_pd_multiplier IS NULL) AS pd_multiplier_nulls,
    COUNT(*) FILTER (WHERE projected_npl_ratio_pct IS NULL) AS npl_ratio_nulls,
    COUNT(*) FILTER (WHERE stressed_el_rate_pct IS NULL) AS el_rate_nulls,
    COUNT(*) FILTER (WHERE incremental_credit_loss_usd IS NULL) AS loss_nulls,
    COUNT(*) FILTER (WHERE car_after_pct IS NULL) AS car_after_nulls,
    COUNT(*) FILTER (WHERE roa_after_pct IS NULL) AS roa_after_nulls,
    COUNT(*) FILTER (WHERE liquidity_after_pct IS NULL) AS liquidity_after_nulls,
    COUNT(*) FILTER (WHERE bank_condition IS NULL) AS bank_condition_nulls
FROM bank_stress_simulated_panel;


-- 8. Blank/whitespace values in text columns
SELECT
    COUNT(*) FILTER (WHERE TRIM(bank_id::VARCHAR) = '') AS blank_bank_ids,
    COUNT(*) FILTER (WHERE TRIM(scenario_id::VARCHAR) = '') AS blank_scenario_ids,
    COUNT(*) FILTER (WHERE TRIM(size_tier::VARCHAR) = '') AS blank_size_tier,
    COUNT(*) FILTER (WHERE TRIM(sector_concentration::VARCHAR) = '') AS blank_sector_concentration,
    COUNT(*) FILTER (WHERE TRIM(scenario_severity::VARCHAR) = '') AS blank_scenario_severity,
    COUNT(*) FILTER (WHERE TRIM(bank_condition::VARCHAR) = '') AS blank_bank_condition
FROM bank_stress_simulated_panel;


-- 9. Bank ID frequency
SELECT bank_id, COUNT(*) AS frequency
FROM bank_stress_simulated_panel
GROUP BY bank_id
ORDER BY frequency DESC, bank_id;


-- 10. Scenario distribution
SELECT scenario_id, COUNT(*) AS frequency
FROM bank_stress_simulated_panel
GROUP BY scenario_id
ORDER BY scenario_id;


-- 11. Size tier raw values
SELECT size_tier, COUNT(*) AS frequency
FROM bank_stress_simulated_panel
GROUP BY size_tier
ORDER BY frequency DESC;


-- 12. Sector concentration raw values
SELECT sector_concentration, COUNT(*) AS frequency
FROM bank_stress_simulated_panel
GROUP BY sector_concentration
ORDER BY frequency DESC;


-- 13. Scenario severity raw values
SELECT scenario_severity, COUNT(*) AS frequency
FROM bank_stress_simulated_panel
GROUP BY scenario_severity
ORDER BY frequency DESC;


-- 14. Bank condition raw values
SELECT bank_condition, COUNT(*) AS frequency
FROM bank_stress_simulated_panel
GROUP BY bank_condition
ORDER BY frequency DESC;


-- 15. Detect case/spacing inconsistencies in size tier
SELECT
    LOWER(TRIM(size_tier::VARCHAR)) AS normalized_value,
    COUNT(DISTINCT size_tier) AS raw_variants,
    STRING_AGG(DISTINCT size_tier::VARCHAR, ', ' ORDER BY size_tier::VARCHAR) AS variants
FROM bank_stress_simulated_panel
GROUP BY LOWER(TRIM(size_tier::VARCHAR))
HAVING COUNT(DISTINCT size_tier) > 1;


-- 16. Detect case/spacing inconsistencies in sector concentration
SELECT
    LOWER(TRIM(sector_concentration::VARCHAR)) AS normalized_value,
    COUNT(DISTINCT sector_concentration) AS raw_variants,
    STRING_AGG(DISTINCT sector_concentration::VARCHAR, ', ' ORDER BY sector_concentration::VARCHAR) AS variants
FROM bank_stress_simulated_panel
GROUP BY LOWER(TRIM(sector_concentration::VARCHAR))
HAVING COUNT(DISTINCT sector_concentration) > 1;


-- 17. Detect inconsistencies in scenario severity
SELECT
    LOWER(TRIM(scenario_severity::VARCHAR)) AS normalized_value,
    COUNT(DISTINCT scenario_severity) AS raw_variants,
    STRING_AGG(DISTINCT scenario_severity::VARCHAR, ', ' ORDER BY scenario_severity::VARCHAR) AS variants
FROM bank_stress_simulated_panel
GROUP BY LOWER(TRIM(scenario_severity::VARCHAR))
HAVING COUNT(DISTINCT scenario_severity) > 1;


-- 18. Detect inconsistencies in bank condition
SELECT
    LOWER(TRIM(bank_condition::VARCHAR)) AS normalized_value,
    COUNT(DISTINCT bank_condition) AS raw_variants,
    STRING_AGG(DISTINCT bank_condition::VARCHAR, ', ' ORDER BY bank_condition::VARCHAR) AS variants
FROM bank_stress_simulated_panel
GROUP BY LOWER(TRIM(bank_condition::VARCHAR))
HAVING COUNT(DISTINCT bank_condition) > 1;


-- 19. Placeholder/sentinel values
SELECT *
FROM bank_stress_simulated_panel
WHERE CASE 
        WHEN REGEXP_REPLACE(car_after_pct::VARCHAR, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
        THEN REGEXP_REPLACE(car_after_pct::VARCHAR, '[^0-9.-]', '', 'g')::NUMERIC 
      END IN (999, -999)
   OR roa_after_pct IN (999, -999)
   OR CASE 
        WHEN REGEXP_REPLACE(liquidity_after_pct::VARCHAR, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
        THEN REGEXP_REPLACE(liquidity_after_pct::VARCHAR, '[^0-9.-]', '', 'g')::NUMERIC 
      END IN (999, -999);


-- 20. Negative financial values
SELECT *
FROM bank_stress_simulated_panel
WHERE total_assets_usd < 0
   OR total_loans_usd < 0
   OR CASE 
        WHEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
        THEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g')::NUMERIC 
      END < 0;


-- 21. Zero financial values
SELECT *
FROM bank_stress_simulated_panel
WHERE total_assets_usd = 0
   OR total_loans_usd = 0
   OR CASE 
        WHEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
        THEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g')::NUMERIC 
      END = 0;


-- 22. Negative risk/probability metrics
SELECT *
FROM bank_stress_simulated_panel
WHERE weighted_pd_multiplier < 0
   OR projected_npl_ratio_pct < 0
   OR stressed_el_rate_pct < 0
   OR CASE 
        WHEN REGEXP_REPLACE(car_after_pct::VARCHAR, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
        THEN REGEXP_REPLACE(car_after_pct::VARCHAR, '[^0-9.-]', '', 'g')::NUMERIC 
      END < 0
   OR CASE 
        WHEN REGEXP_REPLACE(liquidity_after_pct::VARCHAR, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
        THEN REGEXP_REPLACE(liquidity_after_pct::VARCHAR, '[^0-9.-]', '', 'g')::NUMERIC 
      END < 0;


-- 23. Probability/rate values above logical bounds
SELECT *
FROM bank_stress_simulated_panel
WHERE projected_npl_ratio_pct > 100
   OR stressed_el_rate_pct > 100;


-- 24. Descriptive statistics — assets
SELECT
    COUNT(total_assets_usd) AS n,
    MIN(total_assets_usd) AS minimum,
    MAX(total_assets_usd) AS maximum,
    AVG(total_assets_usd) AS mean,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY total_assets_usd) AS median,
    STDDEV(total_assets_usd) AS std_dev
FROM bank_stress_simulated_panel;


-- 25. Descriptive statistics — loans
SELECT
    COUNT(total_loans_usd) AS n,
    MIN(total_loans_usd) AS minimum,
    MAX(total_loans_usd) AS maximum,
    AVG(total_loans_usd) AS mean,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY total_loans_usd) AS median,
    STDDEV(total_loans_usd) AS std_dev
FROM bank_stress_simulated_panel;


-- 26. Descriptive statistics — PD Multiplier
SELECT
    COUNT(weighted_pd_multiplier) AS n,
    MIN(weighted_pd_multiplier) AS minimum,
    MAX(weighted_pd_multiplier) AS maximum,
    AVG(weighted_pd_multiplier) AS mean,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY weighted_pd_multiplier) AS median,
    STDDEV(weighted_pd_multiplier) AS std_dev
FROM bank_stress_simulated_panel;


-- 27. Descriptive statistics — Projected NPL Ratio
SELECT
    COUNT(projected_npl_ratio_pct) AS n,
    MIN(projected_npl_ratio_pct) AS minimum,
    MAX(projected_npl_ratio_pct) AS maximum,
    AVG(projected_npl_ratio_pct) AS mean,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY projected_npl_ratio_pct) AS median,
    STDDEV(projected_npl_ratio_pct) AS std_dev
FROM bank_stress_simulated_panel;


-- 28. Descriptive statistics — Stressed EL Rate
SELECT
    COUNT(stressed_el_rate_pct) AS n,
    MIN(stressed_el_rate_pct) AS minimum,
    MAX(stressed_el_rate_pct) AS maximum,
    AVG(stressed_el_rate_pct) AS mean,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY stressed_el_rate_pct) AS median,
    STDDEV(stressed_el_rate_pct) AS std_dev
FROM bank_stress_simulated_panel;


-- 29. Descriptive statistics — Incremental Loss Amount
WITH cleaned AS (
    SELECT 
        CASE 
            WHEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
            THEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g')::NUMERIC 
        END AS clean_loss
    FROM bank_stress_simulated_panel
)
SELECT
    COUNT(clean_loss) AS n,
    MIN(clean_loss) AS minimum,
    MAX(clean_loss) AS maximum,
    AVG(clean_loss) AS mean,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY clean_loss) AS median,
    STDDEV(clean_loss) AS std_dev
FROM cleaned;


-- 30. Descriptive statistics — CAR After
WITH cleaned AS (
    SELECT 
        CASE 
            WHEN REGEXP_REPLACE(car_after_pct::VARCHAR, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
            THEN REGEXP_REPLACE(car_after_pct::VARCHAR, '[^0-9.-]', '', 'g')::NUMERIC 
        END AS clean_car
    FROM bank_stress_simulated_panel
)
SELECT
    COUNT(clean_car) AS n,
    MIN(clean_car) AS minimum,
    MAX(clean_car) AS maximum,
    AVG(clean_car) AS mean,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY clean_car) AS median,
    STDDEV(clean_car) AS std_dev
FROM cleaned;


-- 31. Descriptive statistics — ROA After
SELECT
    COUNT(roa_after_pct) AS n,
    MIN(roa_after_pct) AS minimum,
    MAX(roa_after_pct) AS maximum,
    AVG(roa_after_pct) AS mean,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY roa_after_pct) AS median,
    STDDEV(roa_after_pct) AS std_dev
FROM bank_stress_simulated_panel;


-- 32. IQR outliers — PD Multiplier
WITH stats AS (
    SELECT 
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY weighted_pd_multiplier) AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY weighted_pd_multiplier) AS q3
    FROM bank_stress_simulated_panel
)
SELECT b.*, (s.q3 - s.q1) AS iqr
FROM bank_stress_simulated_panel b, stats s
WHERE b.weighted_pd_multiplier < (s.q1 - 1.5 * (s.q3 - s.q1))
   OR b.weighted_pd_multiplier > (s.q3 + 1.5 * (s.q3 - s.q1));


-- 33. IQR outliers — Projected NPL Ratio
WITH stats AS (
    SELECT 
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY projected_npl_ratio_pct) AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY projected_npl_ratio_pct) AS q3
    FROM bank_stress_simulated_panel
)
SELECT b.*, (s.q3 - s.q1) AS iqr
FROM bank_stress_simulated_panel b, stats s
WHERE b.projected_npl_ratio_pct < (s.q1 - 1.5 * (s.q3 - s.q1))
   OR b.projected_npl_ratio_pct > (s.q3 + 1.5 * (s.q3 - s.q1));


-- 34. IQR outliers — Stressed EL Rate
WITH stats AS (
    SELECT 
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY stressed_el_rate_pct) AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY stressed_el_rate_pct) AS q3
    FROM bank_stress_simulated_panel
)
SELECT b.*, (s.q3 - s.q1) AS iqr
FROM bank_stress_simulated_panel b, stats s
WHERE b.stressed_el_rate_pct < (s.q1 - 1.5 * (s.q3 - s.q1))
   OR b.stressed_el_rate_pct > (s.q3 + 1.5 * (s.q3 - s.q1));


-- 35. IQR outliers — Incremental Loss Amount
WITH cleaned AS (
    SELECT *, 
        CASE 
            WHEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
            THEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g')::NUMERIC 
        END AS clean_loss
    FROM bank_stress_simulated_panel
),
stats AS (
    SELECT 
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY clean_loss) AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY clean_loss) AS q3
    FROM cleaned
    WHERE clean_loss IS NOT NULL
)
SELECT c.*, (s.q3 - s.q1) AS iqr
FROM cleaned c, stats s
WHERE c.clean_loss < (s.q1 - 1.5 * (s.q3 - s.q1))
   OR c.clean_loss > (s.q3 + 1.5 * (s.q3 - s.q1));


-- 36. IQR outliers — CAR After
WITH cleaned AS (
    SELECT *, 
        CASE 
            WHEN REGEXP_REPLACE(car_after_pct::VARCHAR, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
            THEN REGEXP_REPLACE(car_after_pct::VARCHAR, '[^0-9.-]', '', 'g')::NUMERIC 
        END AS clean_car
    FROM bank_stress_simulated_panel
),
stats AS (
    SELECT 
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY clean_car) AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY clean_car) AS q3
    FROM cleaned
    WHERE clean_car IS NOT NULL
)
SELECT c.*, (s.q3 - s.q1) AS iqr
FROM cleaned c, stats s
WHERE c.clean_car < (s.q1 - 1.5 * (s.q3 - s.q1))
   OR c.clean_car > (s.q3 + 1.5 * (s.q3 - s.q1));


-- 37. IQR outliers — ROA After
WITH stats AS (
    SELECT 
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY roa_after_pct) AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY roa_after_pct) AS q3
    FROM bank_stress_simulated_panel
)
SELECT b.*, (s.q3 - s.q1) AS iqr
FROM bank_stress_simulated_panel b, stats s
WHERE b.roa_after_pct < (s.q1 - 1.5 * (s.q3 - s.q1))
   OR b.roa_after_pct > (s.q3 + 1.5 * (s.q3 - s.q1));


-- 38. Bank condition by scenario
SELECT
    scenario_id,
    bank_condition,
    COUNT(*) AS frequency
FROM bank_stress_simulated_panel
GROUP BY scenario_id, bank_condition
ORDER BY scenario_id, frequency DESC;


-- 39. Bank condition by scenario severity
SELECT
    scenario_severity,
    bank_condition,
    COUNT(*) AS frequency
FROM bank_stress_simulated_panel
GROUP BY scenario_severity, bank_condition
ORDER BY scenario_severity, frequency DESC;


-- 40. Average stressed metrics by scenario
SELECT
    scenario_id,
    AVG(weighted_pd_multiplier) AS avg_pd_multiplier,
    AVG(projected_npl_ratio_pct) AS avg_npl_ratio,
    AVG(stressed_el_rate_pct) AS avg_el_rate,
    AVG(CASE 
        WHEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
        THEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g')::NUMERIC 
    END) AS avg_loss,
    AVG(CASE 
        WHEN REGEXP_REPLACE(car_after_pct::VARCHAR, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
        THEN REGEXP_REPLACE(car_after_pct::VARCHAR, '[^0-9.-]', '', 'g')::NUMERIC 
    END) AS avg_car_after,
    AVG(roa_after_pct) AS avg_roa_after,
    AVG(CASE 
        WHEN REGEXP_REPLACE(liquidity_after_pct::VARCHAR, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
        THEN REGEXP_REPLACE(liquidity_after_pct::VARCHAR, '[^0-9.-]', '', 'g')::NUMERIC 
    END) AS avg_liquidity_after
FROM bank_stress_simulated_panel
GROUP BY scenario_id
ORDER BY scenario_id;


-- 41. Average stressed metrics by scenario severity
SELECT
    scenario_severity,
    AVG(weighted_pd_multiplier) AS avg_pd_multiplier,
    AVG(projected_npl_ratio_pct) AS avg_npl_ratio,
    AVG(stressed_el_rate_pct) AS avg_el_rate,
    AVG(CASE 
        WHEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
        THEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g')::NUMERIC 
    END) AS avg_loss,
    AVG(CASE 
        WHEN REGEXP_REPLACE(car_after_pct::VARCHAR, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
        THEN REGEXP_REPLACE(car_after_pct::VARCHAR, '[^0-9.-]', '', 'g')::NUMERIC 
    END) AS avg_car_after,
    AVG(roa_after_pct) AS avg_roa_after,
    AVG(CASE 
        WHEN REGEXP_REPLACE(liquidity_after_pct::VARCHAR, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
        THEN REGEXP_REPLACE(liquidity_after_pct::VARCHAR, '[^0-9.-]', '', 'g')::NUMERIC 
    END) AS avg_liquidity_after
FROM bank_stress_simulated_panel
GROUP BY scenario_severity
ORDER BY scenario_severity;


-- 42. Bank condition by size tier
SELECT
    size_tier,
    bank_condition,
    COUNT(*) AS frequency
FROM bank_stress_simulated_panel
GROUP BY size_tier, bank_condition
ORDER BY size_tier, frequency DESC;


-- 43. Bank condition by sector concentration
SELECT
    sector_concentration,
    bank_condition,
    COUNT(*) AS frequency
FROM bank_stress_simulated_panel
GROUP BY sector_concentration, bank_condition
ORDER BY sector_concentration, frequency DESC;


-- 44. Average loss by size tier
SELECT
    size_tier,
    COUNT(*) AS banks,
    AVG(CASE 
        WHEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
        THEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g')::NUMERIC 
    END) AS avg_loss,
    SUM(CASE 
        WHEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
        THEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g')::NUMERIC 
    END) AS total_loss
FROM bank_stress_simulated_panel
GROUP BY size_tier
ORDER BY total_loss DESC;


-- 45. Average loss by sector concentration
SELECT
    sector_concentration,
    COUNT(*) AS banks,
    AVG(CASE 
        WHEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
        THEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g')::NUMERIC 
    END) AS avg_loss,
    SUM(CASE 
        WHEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
        THEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g')::NUMERIC 
    END) AS total_loss
FROM bank_stress_simulated_panel
GROUP BY sector_concentration
ORDER BY total_loss DESC;


-- 46. Macro values by scenario
SELECT
    scenario_id,
    MIN(gdp_shock_pp) AS gdp_shock,
    MIN(unemp_shock_pp) AS unemp_shock,
    MIN(rate_shock_pp) AS rate_shock,
    MIN(credit_spread_bps) AS credit_spread,
    MIN(inflation_shock_pp) AS inflation_shock,
    MIN(fx_devaluation_pct) AS fx_devaluation,
    COUNT(DISTINCT scenario_severity) AS severity_count
FROM bank_stress_simulated_panel
GROUP BY scenario_id
ORDER BY scenario_id;


-- 47. Check whether macro variables are consistent within each scenario
SELECT
    scenario_id,
    COUNT(DISTINCT gdp_shock_pp) AS gdp_values,
    COUNT(DISTINCT unemp_shock_pp) AS unemp_values,
    COUNT(DISTINCT rate_shock_pp) AS rate_values,
    COUNT(DISTINCT credit_spread_bps) AS spread_values,
    COUNT(DISTINCT inflation_shock_pp) AS inflation_values,
    COUNT(DISTINCT fx_devaluation_pct) AS fx_values,
    COUNT(DISTINCT scenario_severity) AS severities
FROM bank_stress_simulated_panel
GROUP BY scenario_id
HAVING COUNT(DISTINCT gdp_shock_pp) > 1
    OR COUNT(DISTINCT unemp_shock_pp) > 1
    OR COUNT(DISTINCT rate_shock_pp) > 1
    OR COUNT(DISTINCT credit_spread_bps) > 1
    OR COUNT(DISTINCT inflation_shock_pp) > 1
    OR COUNT(DISTINCT fx_devaluation_pct) > 1
    OR COUNT(DISTINCT scenario_severity) > 1;


-- 48. Check baseline consistency for each bank across scenarios
SELECT
    bank_id,
    COUNT(DISTINCT size_tier) AS size_tier_values,
    COUNT(DISTINCT sector_concentration) AS concentration_values,
    COUNT(DISTINCT ROUND(total_assets_usd::NUMERIC, 2)) AS asset_values,
    COUNT(DISTINCT ROUND(total_loans_usd::NUMERIC, 2)) AS loan_values,
    COUNT(DISTINCT ROUND(baseline_car_pct::NUMERIC, 4)) AS car_values,
    COUNT(DISTINCT ROUND(baseline_liquidity_ratio_pct::NUMERIC, 4)) AS liquidity_values,
    COUNT(DISTINCT ROUND(baseline_roa_pct::NUMERIC, 4)) AS roa_values
FROM bank_stress_simulated_panel
GROUP BY bank_id
HAVING COUNT(DISTINCT size_tier) > 1
    OR COUNT(DISTINCT sector_concentration) > 1
    OR COUNT(DISTINCT ROUND(total_assets_usd::NUMERIC, 2)) > 1
    OR COUNT(DISTINCT ROUND(total_loans_usd::NUMERIC, 2)) > 1
    OR COUNT(DISTINCT ROUND(baseline_car_pct::NUMERIC, 4)) > 1
    OR COUNT(DISTINCT ROUND(baseline_liquidity_ratio_pct::NUMERIC, 4)) > 1
    OR COUNT(DISTINCT ROUND(baseline_roa_pct::NUMERIC, 4)) > 1;


-- 49. Loan-to-asset ratio
SELECT
    bank_id,
    scenario_id,
    total_loans_usd,
    total_assets_usd,
    total_loans_usd::NUMERIC / NULLIF(total_assets_usd, 0) AS loan_to_asset_ratio
FROM bank_stress_simulated_panel
ORDER BY loan_to_asset_ratio DESC;


-- 50. Loss-to-loan ratio
SELECT
    bank_id,
    scenario_id,
    incremental_credit_loss_usd,
    total_loans_usd,
    CASE 
        WHEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
        THEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g')::NUMERIC 
    END / NULLIF(total_loans_usd, 0) AS loss_to_loan_ratio
FROM bank_stress_simulated_panel
ORDER BY loss_to_loan_ratio DESC;


-- 51. Loss-to-asset ratio
SELECT
    bank_id,
    scenario_id,
    incremental_credit_loss_usd,
    total_assets_usd,
    CASE 
        WHEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
        THEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g')::NUMERIC 
    END / NULLIF(total_assets_usd, 0) AS loss_to_asset_ratio
FROM bank_stress_simulated_panel
ORDER BY loss_to_asset_ratio DESC;


-- 52. Correlation: PD Multiplier vs Projected NPL Ratio
SELECT CORR(weighted_pd_multiplier, projected_npl_ratio_pct) AS pd_npl_correlation
FROM bank_stress_simulated_panel;


-- 53. Correlation: PD Multiplier vs Loss Amount
SELECT CORR(weighted_pd_multiplier, 
    CASE 
        WHEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
        THEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g')::NUMERIC 
    END) AS pd_loss_correlation
FROM bank_stress_simulated_panel;


-- 54. Correlation: Projected NPL Ratio vs Loss Amount
SELECT CORR(projected_npl_ratio_pct, 
    CASE 
        WHEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
        THEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g')::NUMERIC 
    END) AS npl_loss_correlation
FROM bank_stress_simulated_panel;


-- 55. Correlation: Stressed EL Rate vs Loss Amount
SELECT CORR(stressed_el_rate_pct, 
    CASE 
        WHEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
        THEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g')::NUMERIC 
    END) AS el_loss_correlation
FROM bank_stress_simulated_panel;


-- 56. Correlation: ROA After vs Loss Amount
SELECT CORR(roa_after_pct, 
    CASE 
        WHEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
        THEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g')::NUMERIC 
    END) AS roa_loss_correlation
FROM bank_stress_simulated_panel;


-- 57. Correlation: CAR After vs Loss Amount
SELECT CORR(
    CASE 
        WHEN REGEXP_REPLACE(car_after_pct::VARCHAR, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
        THEN REGEXP_REPLACE(car_after_pct::VARCHAR, '[^0-9.-]', '', 'g')::NUMERIC 
    END, 
    CASE 
        WHEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
        THEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g')::NUMERIC 
    END) AS car_loss_correlation
FROM bank_stress_simulated_panel;


-- 58. Banks with unusually high losses
SELECT
    bank_id,
    scenario_id,
    incremental_credit_loss_usd,
    weighted_pd_multiplier,
    projected_npl_ratio_pct,
    stressed_el_rate_pct,
    car_after_pct,
    bank_condition
FROM bank_stress_simulated_panel
ORDER BY CASE 
        WHEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
        THEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g')::NUMERIC 
    END DESC NULLS LAST
LIMIT 20;


-- 59. Banks with lowest CAR after
SELECT
    bank_id,
    scenario_id,
    car_after_pct,
    incremental_credit_loss_usd,
    bank_condition
FROM bank_stress_simulated_panel
ORDER BY CASE 
        WHEN REGEXP_REPLACE(car_after_pct::VARCHAR, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
        THEN REGEXP_REPLACE(car_after_pct::VARCHAR, '[^0-9.-]', '', 'g')::NUMERIC 
    END ASC NULLS LAST
LIMIT 20;


-- 60. Highest PD Multiplier
SELECT
    bank_id,
    scenario_id,
    weighted_pd_multiplier,
    projected_npl_ratio_pct,
    incremental_credit_loss_usd,
    bank_condition
FROM bank_stress_simulated_panel
ORDER BY weighted_pd_multiplier DESC
LIMIT 20;


-- 61. Lowest ROA After
SELECT
    bank_id,
    scenario_id,
    roa_after_pct,
    incremental_credit_loss_usd,
    car_after_pct,
    bank_condition
FROM bank_stress_simulated_panel
ORDER BY roa_after_pct ASC
LIMIT 20;


-- 62. Check bank condition consistency with ROA after
SELECT
    bank_condition,
    COUNT(*) AS frequency,
    MIN(roa_after_pct) AS min_roa_after,
    MAX(roa_after_pct) AS max_roa_after,
    AVG(roa_after_pct) AS avg_roa_after
FROM bank_stress_simulated_panel
GROUP BY bank_condition
ORDER BY bank_condition;


-- 63. Check bank condition consistency with CAR after
SELECT
    bank_condition,
    COUNT(*) AS frequency,
    MIN(CASE 
        WHEN REGEXP_REPLACE(car_after_pct::VARCHAR, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
        THEN REGEXP_REPLACE(car_after_pct::VARCHAR, '[^0-9.-]', '', 'g')::NUMERIC 
    END) AS min_car,
    MAX(CASE 
        WHEN REGEXP_REPLACE(car_after_pct::VARCHAR, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
        THEN REGEXP_REPLACE(car_after_pct::VARCHAR, '[^0-9.-]', '', 'g')::NUMERIC 
    END) AS max_car,
    AVG(CASE 
        WHEN REGEXP_REPLACE(car_after_pct::VARCHAR, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
        THEN REGEXP_REPLACE(car_after_pct::VARCHAR, '[^0-9.-]', '', 'g')::NUMERIC 
    END) AS avg_car
FROM bank_stress_simulated_panel
GROUP BY bank_condition
ORDER BY bank_condition;


-- 64. Check scenario progression for each bank
SELECT
    bank_id,
    scenario_id,
    scenario_severity,
    weighted_pd_multiplier,
    projected_npl_ratio_pct,
    stressed_el_rate_pct,
    incremental_credit_loss_usd,
    car_after_pct,
    roa_after_pct,
    bank_condition
FROM bank_stress_simulated_panel
ORDER BY bank_id, scenario_id;


-- 65. Count conditions per bank
SELECT
    bank_id,
    COUNT(*) AS scenarios,
    COUNT(*) FILTER (WHERE LOWER(TRIM(bank_condition::VARCHAR)) = 'healthy') AS healthy_count,
    COUNT(*) FILTER (WHERE LOWER(TRIM(bank_condition::VARCHAR)) = 'stressed') AS stressed_count,
    COUNT(*) FILTER (WHERE LOWER(TRIM(bank_condition::VARCHAR)) = 'critical') AS critical_count
FROM bank_stress_simulated_panel
GROUP BY bank_id
ORDER BY bank_id;


-- 66. Banks appearing in fewer/more scenario records than expected
SELECT
    bank_id,
    COUNT(DISTINCT scenario_id) AS scenario_count
FROM bank_stress_simulated_panel
GROUP BY bank_id
HAVING COUNT(DISTINCT scenario_id) <> (
    SELECT COUNT(DISTINCT scenario_id)
    FROM bank_stress_simulated_panel
)
ORDER BY bank_id;


-- 67. Scenario-bank coverage matrix
SELECT
    scenario_id,
    COUNT(DISTINCT bank_id) AS distinct_banks
FROM bank_stress_simulated_panel
GROUP BY scenario_id
ORDER BY scenario_id;


-- 68. Exact suspicious records containing known formatting/typo variants
SELECT *
FROM bank_stress_simulated_panel
WHERE scenario_severity IN ('advers', ' mild', 'Mild', 'Adverse')
   OR bank_condition IN ('Critcal', 'healthy')
   OR incremental_credit_loss_usd::VARCHAR LIKE '%$%';


-- 69. Distinct values for every categorical field
SELECT DISTINCT size_tier
FROM bank_stress_simulated_panel
ORDER BY size_tier;

SELECT DISTINCT sector_concentration
FROM bank_stress_simulated_panel
ORDER BY sector_concentration;

SELECT DISTINCT scenario_severity
FROM bank_stress_simulated_panel
ORDER BY scenario_severity;

SELECT DISTINCT bank_condition
FROM bank_stress_simulated_panel
ORDER BY bank_condition;


-- 70. Overall numerical summary by scenario
SELECT
    scenario_id,
    COUNT(*) AS observations,
    MIN(weighted_pd_multiplier) AS min_pd_mult,
    MAX(weighted_pd_multiplier) AS max_pd_mult,
    AVG(weighted_pd_multiplier) AS avg_pd_mult,
    MIN(projected_npl_ratio_pct) AS min_npl,
    MAX(projected_npl_ratio_pct) AS max_npl,
    AVG(projected_npl_ratio_pct) AS avg_npl,
    MIN(stressed_el_rate_pct) AS min_el,
    MAX(stressed_el_rate_pct) AS max_el,
    AVG(stressed_el_rate_pct) AS avg_el,
    MIN(CASE 
        WHEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
        THEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g')::NUMERIC 
    END) AS min_loss,
    MAX(CASE 
        WHEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
        THEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g')::NUMERIC 
    END) AS max_loss,
    AVG(CASE 
        WHEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
        THEN REGEXP_REPLACE(incremental_credit_loss_usd::VARCHAR, '[^0-9.-]', '', 'g')::NUMERIC 
    END) AS avg_loss,
    MIN(CASE 
        WHEN REGEXP_REPLACE(car_after_pct::VARCHAR, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
        THEN REGEXP_REPLACE(car_after_pct::VARCHAR, '[^0-9.-]', '', 'g')::NUMERIC 
    END) AS min_car,
    MAX(CASE 
        WHEN REGEXP_REPLACE(car_after_pct::VARCHAR, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
        THEN REGEXP_REPLACE(car_after_pct::VARCHAR, '[^0-9.-]', '', 'g')::NUMERIC 
    END) AS max_car,
    AVG(CASE 
        WHEN REGEXP_REPLACE(car_after_pct::VARCHAR, '[^0-9.-]', '', 'g') ~ '^-?[0-9]+(\.[0-9]+)?$' 
        THEN REGEXP_REPLACE(car_after_pct::VARCHAR, '[^0-9.-]', '', 'g')::NUMERIC 
    END) AS avg_car
FROM bank_stress_simulated_panel
GROUP BY scenario_id
ORDER BY scenario_id;