-- MACRO STRESS SCENARIOS EDA AND DATA QUALITY AUDIT
-- Database: PostgreSQL / DBeaver
-- Read-Only Script

-- 1. Check the total number of rows
SELECT COUNT(*) AS total_rows
FROM macro_stress_scenarios;

-- 2. Check the number of unique scenarios
SELECT COUNT(DISTINCT scenario) AS unique_scenarios
FROM macro_stress_scenarios;

-- 3. Check the number of unique sectors
SELECT COUNT(DISTINCT sector) AS unique_sectors
FROM macro_stress_scenarios;

-- 4. Display a sample of the table
SELECT *
FROM macro_stress_scenarios
LIMIT 20;

-- 5. Check NULL values in every column
SELECT
    COUNT(*) FILTER (WHERE scenario IS NULL) AS scenario_nulls,
    COUNT(*) FILTER (WHERE sector IS NULL) AS sector_nulls,
    COUNT(*) FILTER (WHERE gdp_shock_pp IS NULL) AS gdp_shock_nulls,
    COUNT(*) FILTER (WHERE unemp_shock_pp IS NULL) AS unemployment_shock_nulls,
    COUNT(*) FILTER (WHERE rate_shock_pp IS NULL) AS rate_shock_nulls,
    COUNT(*) FILTER (WHERE credit_spread_bps IS NULL) AS credit_spread_nulls,
    COUNT(*) FILTER (WHERE inflation_shock_pp IS NULL) AS inflation_shock_nulls,
    COUNT(*) FILTER (WHERE fx_devaluation_pct IS NULL) AS fx_devaluation_nulls,
    COUNT(*) FILTER (WHERE pd_multiplier IS NULL) AS pd_multiplier_nulls,
    COUNT(*) FILTER (WHERE base_lgd IS NULL) AS base_lgd_nulls,
    COUNT(*) FILTER (WHERE stressed_lgd IS NULL) AS stressed_lgd_nulls
FROM macro_stress_scenarios;

-- 6. Check blank values in scenario
SELECT
    scenario,
    COUNT(*) AS row_count
FROM macro_stress_scenarios
WHERE scenario IS NULL
   OR TRIM(scenario) = ''
GROUP BY scenario;

-- 7. Check blank values in sector
SELECT
    sector,
    COUNT(*) AS row_count
FROM macro_stress_scenarios
WHERE sector IS NULL
   OR TRIM(sector) = ''
GROUP BY sector;

-- 8. Display all raw scenario values and their frequencies
SELECT
    scenario,
    COUNT(*) AS row_count
FROM macro_stress_scenarios
GROUP BY scenario
ORDER BY row_count DESC;

-- 9. Display normalized scenario values
SELECT
    LOWER(TRIM(scenario)) AS normalized_scenario,
    COUNT(*) AS row_count
FROM macro_stress_scenarios
GROUP BY LOWER(TRIM(scenario))
ORDER BY row_count DESC;

-- 10. Find scenario values with inconsistent capitalization or spaces
SELECT
    scenario,
    LOWER(TRIM(scenario)) AS normalized_scenario,
    COUNT(*) AS row_count
FROM macro_stress_scenarios
GROUP BY scenario, LOWER(TRIM(scenario))
ORDER BY normalized_scenario, scenario;

-- 11. Display all raw sector values and their frequencies
SELECT
    sector,
    COUNT(*) AS row_count
FROM macro_stress_scenarios
GROUP BY sector
ORDER BY row_count DESC;

-- 12. Display normalized sector values
SELECT
    LOWER(TRIM(sector)) AS normalized_sector,
    COUNT(*) AS row_count
FROM macro_stress_scenarios
GROUP BY LOWER(TRIM(sector))
ORDER BY row_count DESC;

-- 13. Find sector values with inconsistent capitalization or spaces
SELECT
    sector,
    LOWER(TRIM(sector)) AS normalized_sector,
    COUNT(*) AS row_count
FROM macro_stress_scenarios
GROUP BY sector, LOWER(TRIM(sector))
ORDER BY normalized_sector, sector;

-- 14. Check common sector spelling variations and non-standard names
SELECT
    sector,
    COUNT(*) AS row_count
FROM macro_stress_scenarios
WHERE LOWER(TRIM(sector)) IN (
    'tech',
    'technology',
    'retial',
    'retail',
    'tele com',
    'telecom',
    'health care',
    'healthcare',
    'industrial',
    'industrials',
    'utility',
    'utilities',
    'financial',
    'financials',
    'consumer goods',
    'consumer'
)
GROUP BY sector
ORDER BY sector;

-- 15. Find duplicate scenario-sector combinations
SELECT
    LOWER(TRIM(scenario)) AS normalized_scenario,
    LOWER(TRIM(sector)) AS normalized_sector,
    COUNT(*) AS row_count
FROM macro_stress_scenarios
GROUP BY
    LOWER(TRIM(scenario)),
    LOWER(TRIM(sector))
HAVING COUNT(*) > 1
ORDER BY row_count DESC;

-- 16. Check whether raw duplicate rows exist
SELECT
    scenario,
    sector,
    gdp_shock_pp,
    unemp_shock_pp,
    rate_shock_pp,
    credit_spread_bps,
    inflation_shock_pp,
    fx_devaluation_pct,
    pd_multiplier,
    base_lgd,
    stressed_lgd,
    COUNT(*) AS duplicate_count
FROM macro_stress_scenarios
GROUP BY
    scenario,
    sector,
    gdp_shock_pp,
    unemp_shock_pp,
    rate_shock_pp,
    credit_spread_bps,
    inflation_shock_pp,
    fx_devaluation_pct,
    pd_multiplier,
    base_lgd,
    stressed_lgd
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- 17. Check distinct PD multiplier values
SELECT
    pd_multiplier,
    COUNT(*) AS row_count
FROM macro_stress_scenarios
GROUP BY pd_multiplier
ORDER BY row_count DESC;

-- 18. Check missing-like PD multiplier values
SELECT
    pd_multiplier,
    COUNT(*) AS row_count
FROM macro_stress_scenarios
WHERE pd_multiplier IS NULL
   OR TRIM(pd_multiplier) = ''
   OR UPPER(TRIM(pd_multiplier)) IN ('NA', 'N/A', '-')
GROUP BY pd_multiplier
ORDER BY row_count DESC;

-- 19. Isolate specific rows with missing PD multipliers for manual review
SELECT
    LOWER(TRIM(scenario)) AS scenario,
    LOWER(TRIM(sector)) AS sector,
    pd_multiplier
FROM macro_stress_scenarios
WHERE pd_multiplier IS NULL
   OR TRIM(pd_multiplier) = ''
   OR UPPER(TRIM(pd_multiplier)) IN ('NA', 'N/A', '-')
ORDER BY scenario, sector;

-- 20. Check PD multiplier values that are not numeric
SELECT
    scenario,
    sector,
    pd_multiplier
FROM macro_stress_scenarios
WHERE pd_multiplier IS NOT NULL
  AND TRIM(pd_multiplier) <> ''
  AND UPPER(TRIM(pd_multiplier)) NOT IN ('NA', 'N/A', '-')
  AND TRIM(pd_multiplier) !~ '^-?[0-9]+(\.[0-9]+)?$'
ORDER BY scenario, sector;

-- 21. Preview numeric PD multiplier values
SELECT
    scenario,
    sector,
    pd_multiplier,
    CASE
        WHEN TRIM(pd_multiplier) ~ '^-?[0-9]+(\.[0-9]+)?$'
        THEN TRIM(pd_multiplier)::numeric
        ELSE NULL
    END AS numeric_pd_multiplier
FROM macro_stress_scenarios
ORDER BY scenario, sector;

-- 22. Calculate descriptive statistics for GDP shock
SELECT
    COUNT(gdp_shock_pp) AS non_null_count,
    MIN(gdp_shock_pp) AS minimum,
    MAX(gdp_shock_pp) AS maximum,
    AVG(gdp_shock_pp::numeric) AS average,
    STDDEV_POP(gdp_shock_pp::numeric) AS standard_deviation
FROM macro_stress_scenarios;

-- 23. Calculate descriptive statistics for unemployment shock
SELECT
    COUNT(unemp_shock_pp) AS non_null_count,
    MIN(unemp_shock_pp) AS minimum,
    MAX(unemp_shock_pp) AS maximum,
    AVG(unemp_shock_pp::numeric) AS average,
    STDDEV_POP(unemp_shock_pp::numeric) AS standard_deviation
FROM macro_stress_scenarios;

-- 24. Calculate descriptive statistics for rate shock
SELECT
    COUNT(rate_shock_pp) AS non_null_count,
    MIN(rate_shock_pp) AS minimum,
    MAX(rate_shock_pp) AS maximum,
    AVG(rate_shock_pp::numeric) AS average,
    STDDEV_POP(rate_shock_pp::numeric) AS standard_deviation
FROM macro_stress_scenarios;

-- 25. Calculate descriptive statistics for credit spread
SELECT
    COUNT(credit_spread_bps) AS non_null_count,
    MIN(credit_spread_bps) AS minimum,
    MAX(credit_spread_bps) AS maximum,
    AVG(credit_spread_bps::numeric) AS average,
    STDDEV_POP(credit_spread_bps::numeric) AS standard_deviation
FROM macro_stress_scenarios;

-- 26. Calculate descriptive statistics for inflation shock
SELECT
    COUNT(inflation_shock_pp) AS non_null_count,
    MIN(inflation_shock_pp) AS minimum,
    MAX(inflation_shock_pp) AS maximum,
    AVG(inflation_shock_pp::numeric) AS average,
    STDDEV_POP(inflation_shock_pp::numeric) AS standard_deviation
FROM macro_stress_scenarios;

-- 27. Calculate descriptive statistics for FX devaluation
SELECT
    COUNT(fx_devaluation_pct) AS non_null_count,
    MIN(fx_devaluation_pct) AS minimum,
    MAX(fx_devaluation_pct) AS maximum,
    AVG(fx_devaluation_pct::numeric) AS average,
    STDDEV_POP(fx_devaluation_pct::numeric) AS standard_deviation
FROM macro_stress_scenarios;

-- 28. Calculate descriptive statistics for base LGD
SELECT
    COUNT(base_lgd) AS non_null_count,
    MIN(base_lgd) AS minimum,
    MAX(base_lgd) AS maximum,
    AVG(base_lgd::numeric) AS average,
    STDDEV_POP(base_lgd::numeric) AS standard_deviation
FROM macro_stress_scenarios;

-- 29. Calculate descriptive statistics for stressed LGD
SELECT
    COUNT(stressed_lgd) AS non_null_count,
    MIN(stressed_lgd) AS minimum,
    MAX(stressed_lgd) AS maximum,
    AVG(stressed_lgd::numeric) AS average,
    STDDEV_POP(stressed_lgd::numeric) AS standard_deviation
FROM macro_stress_scenarios;

-- 30. Check whether stressed LGD is lower than base LGD
SELECT *
FROM macro_stress_scenarios
WHERE stressed_lgd < base_lgd
ORDER BY scenario, sector;

-- 31. Check whether stressed LGD is equal to base LGD
SELECT
    scenario,
    COUNT(*) AS unchanged_lgd_rows
FROM macro_stress_scenarios
WHERE stressed_lgd = base_lgd
GROUP BY scenario
ORDER BY scenario;

-- 32. Calculate the LGD increase caused by stress
SELECT
    scenario,
    sector,
    base_lgd,
    stressed_lgd,
    (stressed_lgd - base_lgd)::numeric AS lgd_absolute_change,
    CASE
        WHEN base_lgd <> 0
        THEN (((stressed_lgd - base_lgd) / base_lgd) * 100)::numeric
        ELSE NULL
    END AS lgd_percentage_change
FROM macro_stress_scenarios
ORDER BY scenario, lgd_absolute_change DESC;

-- 33. Compare average LGD across scenarios
SELECT
    LOWER(TRIM(scenario)) AS normalized_scenario,
    COUNT(*) AS row_count,
    ROUND(AVG(base_lgd::numeric), 4) AS average_base_lgd,
    ROUND(AVG(stressed_lgd::numeric), 4) AS average_stressed_lgd,
    ROUND(AVG((stressed_lgd - base_lgd)::numeric), 4) AS average_lgd_increase
FROM macro_stress_scenarios
GROUP BY LOWER(TRIM(scenario))
ORDER BY average_stressed_lgd;

-- 34. Compare macroeconomic shocks across scenarios
SELECT
    LOWER(TRIM(scenario)) AS normalized_scenario,
    COUNT(*) AS row_count,
    AVG(gdp_shock_pp::numeric) AS average_gdp_shock,
    AVG(unemp_shock_pp::numeric) AS average_unemployment_shock,
    AVG(rate_shock_pp::numeric) AS average_rate_shock,
    AVG(credit_spread_bps::numeric) AS average_credit_spread,
    AVG(inflation_shock_pp::numeric) AS average_inflation_shock,
    AVG(fx_devaluation_pct::numeric) AS average_fx_devaluation
FROM macro_stress_scenarios
GROUP BY LOWER(TRIM(scenario))
ORDER BY normalized_scenario;

-- 35. Compare scenarios by sector
SELECT
    LOWER(TRIM(sector)) AS normalized_sector,
    COUNT(*) AS row_count,
    AVG(gdp_shock_pp::numeric) AS average_gdp_shock,
    AVG(unemp_shock_pp::numeric) AS average_unemployment_shock,
    AVG(rate_shock_pp::numeric) AS average_rate_shock,
    AVG(credit_spread_bps::numeric) AS average_credit_spread,
    AVG(stressed_lgd::numeric) AS average_stressed_lgd
FROM macro_stress_scenarios
GROUP BY LOWER(TRIM(sector))
ORDER BY normalized_sector;

-- 36. Calculate average PD multiplier by scenario
SELECT
    LOWER(TRIM(scenario)) AS normalized_scenario,
    COUNT(*) FILTER (
        WHERE TRIM(pd_multiplier) ~ '^-?[0-9]+(\.[0-9]+)?$'
    ) AS numeric_pd_rows,
    AVG(
        CASE
            WHEN TRIM(pd_multiplier) ~ '^-?[0-9]+(\.[0-9]+)?$'
            THEN TRIM(pd_multiplier)::numeric
            ELSE NULL
        END
    ) AS average_pd_multiplier
FROM macro_stress_scenarios
GROUP BY LOWER(TRIM(scenario))
ORDER BY normalized_scenario;

-- 37. Find the highest PD multiplier values
SELECT
    scenario,
    sector,
    pd_multiplier
FROM macro_stress_scenarios
WHERE TRIM(pd_multiplier) ~ '^-?[0-9]+(\.[0-9]+)?$'
ORDER BY TRIM(pd_multiplier)::numeric DESC
LIMIT 20;

-- 38. Find the highest stressed LGD values
SELECT
    scenario,
    sector,
    base_lgd,
    stressed_lgd
FROM macro_stress_scenarios
ORDER BY stressed_lgd DESC
LIMIT 20;

-- 39. Find the largest GDP shocks
SELECT
    scenario,
    sector,
    gdp_shock_pp
FROM macro_stress_scenarios
ORDER BY gdp_shock_pp
LIMIT 20;

-- 40. Find the highest unemployment shocks
SELECT
    scenario,
    sector,
    unemp_shock_pp
FROM macro_stress_scenarios
ORDER BY unemp_shock_pp DESC
LIMIT 20;

-- 41. Find the highest credit spread shocks
SELECT
    scenario,
    sector,
    credit_spread_bps
FROM macro_stress_scenarios
ORDER BY credit_spread_bps DESC
LIMIT 20;

-- 42. Find the highest FX devaluation values
SELECT
    scenario,
    sector,
    fx_devaluation_pct
FROM macro_stress_scenarios
ORDER BY fx_devaluation_pct DESC
LIMIT 20;

-- 43. Check for negative GDP shocks
SELECT
    scenario,
    sector,
    gdp_shock_pp
FROM macro_stress_scenarios
WHERE gdp_shock_pp < 0
ORDER BY gdp_shock_pp;

-- 44. Check for negative unemployment shocks
SELECT
    scenario,
    sector,
    unemp_shock_pp
FROM macro_stress_scenarios
WHERE unemp_shock_pp < 0
ORDER BY unemp_shock_pp;

-- 45. Check for negative rate shocks
SELECT
    scenario,
    sector,
    rate_shock_pp
FROM macro_stress_scenarios
WHERE rate_shock_pp < 0
ORDER BY rate_shock_pp;

-- 46. Check for negative credit spread values
SELECT
    scenario,
    sector,
    credit_spread_bps
FROM macro_stress_scenarios
WHERE credit_spread_bps < 0
ORDER BY credit_spread_bps;

-- 47. Check for negative inflation shocks
SELECT
    scenario,
    sector,
    inflation_shock_pp
FROM macro_stress_scenarios
WHERE inflation_shock_pp < 0
ORDER BY inflation_shock_pp;

-- 48. Check for negative FX devaluation
SELECT
    scenario,
    sector,
    fx_devaluation_pct
FROM macro_stress_scenarios
WHERE fx_devaluation_pct < 0
ORDER BY fx_devaluation_pct;

-- 49. Check that LGD values are between 0 and 1
SELECT
    scenario,
    sector,
    base_lgd,
    stressed_lgd
FROM macro_stress_scenarios
WHERE base_lgd < 0
   OR base_lgd > 1
   OR stressed_lgd < 0
   OR stressed_lgd > 1
ORDER BY scenario, sector;

-- 50. Check whether baseline scenarios have non-zero macro shocks
SELECT *
FROM macro_stress_scenarios
WHERE LOWER(TRIM(scenario)) = 'baseline'
  AND (
      gdp_shock_pp <> 0
      OR unemp_shock_pp <> 0
      OR rate_shock_pp <> 0
      OR credit_spread_bps <> 0
      OR inflation_shock_pp <> 0
      OR fx_devaluation_pct <> 0
  );

-- 51. Check whether baseline scenarios have LGD changes
SELECT
    scenario,
    sector,
    base_lgd,
    stressed_lgd
FROM macro_stress_scenarios
WHERE LOWER(TRIM(scenario)) = 'baseline'
  AND base_lgd <> stressed_lgd;

-- 52. Check correlation between GDP shock and stressed LGD
SELECT
    CORR(gdp_shock_pp::double precision, stressed_lgd::double precision) AS gdp_lgd_correlation
FROM macro_stress_scenarios;

-- 53. Check correlation between unemployment shock and stressed LGD
SELECT
    CORR(unemp_shock_pp::double precision, stressed_lgd::double precision) AS unemployment_lgd_correlation
FROM macro_stress_scenarios;

-- 54. Check correlation between credit spread and stressed LGD
SELECT
    CORR(credit_spread_bps::double precision, stressed_lgd::double precision) AS credit_spread_lgd_correlation
FROM macro_stress_scenarios;

-- 55. Check correlation between FX devaluation and stressed LGD
SELECT
    CORR(fx_devaluation_pct::double precision, stressed_lgd::double precision) AS fx_lgd_correlation
FROM macro_stress_scenarios;

-- 56. Check correlation between inflation shock and stressed LGD
SELECT
    CORR(inflation_shock_pp::double precision, stressed_lgd::double precision) AS inflation_lgd_correlation
FROM macro_stress_scenarios;

-- 57. Check correlation between rate shock and stressed LGD
SELECT
    CORR(rate_shock_pp::double precision, stressed_lgd::double precision) AS rate_lgd_correlation
FROM macro_stress_scenarios;

-- 58. Identify rows with missing or suspicious values
SELECT
    scenario,
    sector,
    gdp_shock_pp,
    unemp_shock_pp,
    rate_shock_pp,
    credit_spread_bps,
    inflation_shock_pp,
    fx_devaluation_pct,
    pd_multiplier,
    base_lgd,
    stressed_lgd
FROM macro_stress_scenarios
WHERE scenario IS NULL
   OR TRIM(scenario) = ''
   OR sector IS NULL
   OR TRIM(sector) = ''
   OR pd_multiplier IS NULL
   OR TRIM(pd_multiplier) = ''
   OR UPPER(TRIM(pd_multiplier)) IN ('NA', 'N/A', '-')
   OR base_lgd IS NULL
   OR stressed_lgd IS NULL
ORDER BY scenario, sector;

-- 59. Summarize data quality issues
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (
        WHERE scenario IS NULL OR TRIM(scenario) = ''
    ) AS missing_scenario,
    COUNT(*) FILTER (
        WHERE sector IS NULL OR TRIM(sector) = ''
    ) AS missing_sector,
    COUNT(*) FILTER (
        WHERE pd_multiplier IS NULL
           OR TRIM(pd_multiplier) = ''
           OR UPPER(TRIM(pd_multiplier)) IN ('NA', 'N/A', '-')
    ) AS missing_pd_multiplier,
    COUNT(*) FILTER (
        WHERE base_lgd IS NULL
    ) AS missing_base_lgd,
    COUNT(*) FILTER (
        WHERE stressed_lgd IS NULL
    ) AS missing_stressed_lgd,
    COUNT(*) FILTER (
        WHERE stressed_lgd < base_lgd
    ) AS stressed_lgd_lower_than_base,
    COUNT(*) FILTER (
        WHERE base_lgd < 0 OR base_lgd > 1
    ) AS invalid_base_lgd,
    COUNT(*) FILTER (
        WHERE stressed_lgd < 0 OR stressed_lgd > 1
    ) AS invalid_stressed_lgd
FROM macro_stress_scenarios;