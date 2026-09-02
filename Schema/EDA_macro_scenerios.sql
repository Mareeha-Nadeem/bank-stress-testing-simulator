-- MACRO SCENARIOS EDA AND DATA QUALITY AUDIT
-- PostgreSQL / DBeaver
-- This script is READ-ONLY and does not modify the source table.


-- 1. Check the total number of rows
SELECT COUNT(*) AS total_rows
FROM macro_scenarios;


-- 2. Check the number of unique scenario IDs
SELECT COUNT(DISTINCT scenario_id) AS unique_scenario_ids
FROM macro_scenarios;


-- 3. Compare total rows with unique scenario IDs
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT scenario_id) AS unique_scenario_ids,
    COUNT(*) - COUNT(DISTINCT scenario_id) AS duplicate_id_rows
FROM macro_scenarios;


-- 4. Display a sample of the data
SELECT *
FROM macro_scenarios
LIMIT 20;


-- 5. Check for NULL scenario IDs
SELECT COUNT(*) AS null_scenario_ids
FROM macro_scenarios
WHERE scenario_id IS NULL;


-- 6. Check for blank scenario IDs
SELECT COUNT(*) AS blank_scenario_ids
FROM macro_scenarios
WHERE TRIM(scenario_id::varchar) = '';


-- 7. Find duplicate scenario IDs
SELECT
    scenario_id,
    COUNT(*) AS occurrence_count
FROM macro_scenarios
GROUP BY scenario_id
HAVING COUNT(*) > 1
ORDER BY occurrence_count DESC, scenario_id;


-- 8. Check whether duplicate IDs contain conflicting data
SELECT
    scenario_id,
    COUNT(*) AS occurrence_count,
    COUNT(DISTINCT stress_intensity) AS different_stress_values,
    COUNT(DISTINCT scenario_severity) AS different_severity_values,
    COUNT(DISTINCT gdp_shock_pp) AS different_gdp_values,
    COUNT(DISTINCT unemp_shock_pp) AS different_unemployment_values,
    COUNT(DISTINCT rate_shock_pp) AS different_rate_values,
    COUNT(DISTINCT credit_spread_bps) AS different_credit_spread_values,
    COUNT(DISTINCT inflation_shock_pp) AS different_inflation_values,
    COUNT(DISTINCT fx_devaluation_pct) AS different_fx_values
FROM macro_scenarios
GROUP BY scenario_id
HAVING COUNT(*) > 1
ORDER BY scenario_id;


-- 9. Check for completely identical duplicate rows
SELECT
    scenario_id,
    stress_intensity,
    scenario_severity,
    gdp_shock_pp,
    unemp_shock_pp,
    rate_shock_pp,
    credit_spread_bps,
    inflation_shock_pp,
    fx_devaluation_pct,
    COUNT(*) AS duplicate_count
FROM macro_scenarios
GROUP BY
    scenario_id,
    stress_intensity,
    scenario_severity,
    gdp_shock_pp,
    unemp_shock_pp,
    rate_shock_pp,
    credit_spread_bps,
    inflation_shock_pp,
    fx_devaluation_pct
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;


-- 10. Check all raw scenario severity values
SELECT
    scenario_severity,
    COUNT(*) AS row_count
FROM macro_scenarios
GROUP BY scenario_severity
ORDER BY row_count DESC;


-- 11. Check normalized scenario severity values
SELECT
    LOWER(TRIM(scenario_severity::varchar)) AS normalized_severity,
    COUNT(*) AS row_count
FROM macro_scenarios
GROUP BY LOWER(TRIM(scenario_severity::varchar))
ORDER BY row_count DESC;


-- 12. Check for unexpected scenario severity values
SELECT
    scenario_severity,
    COUNT(*) AS row_count
FROM macro_scenarios
WHERE LOWER(TRIM(scenario_severity::varchar)) NOT IN (
    'baseline',
    'mild',
    'moderate',
    'adverse',
    'severe'
)
OR scenario_severity IS NULL
OR TRIM(scenario_severity::varchar) = ''
GROUP BY scenario_severity
ORDER BY row_count DESC;


-- 13. Check scenario severity values containing extra spaces
SELECT
    scenario_severity,
    COUNT(*) AS row_count
FROM macro_scenarios
WHERE scenario_severity::varchar <> TRIM(scenario_severity::varchar)
GROUP BY scenario_severity
ORDER BY row_count DESC;


-- 14. Count SQL NULL values in every column
SELECT
    COUNT(*) FILTER (WHERE scenario_id IS NULL) AS scenario_id_nulls,
    COUNT(*) FILTER (WHERE stress_intensity IS NULL) AS stress_intensity_nulls,
    COUNT(*) FILTER (WHERE scenario_severity IS NULL) AS severity_nulls,
    COUNT(*) FILTER (WHERE gdp_shock_pp IS NULL) AS gdp_shock_nulls,
    COUNT(*) FILTER (WHERE unemp_shock_pp IS NULL) AS unemployment_shock_nulls,
    COUNT(*) FILTER (WHERE rate_shock_pp IS NULL) AS rate_shock_nulls,
    COUNT(*) FILTER (WHERE credit_spread_bps IS NULL) AS credit_spread_nulls,
    COUNT(*) FILTER (WHERE inflation_shock_pp IS NULL) AS inflation_shock_nulls,
    COUNT(*) FILTER (WHERE fx_devaluation_pct IS NULL) AS fx_devaluation_nulls
FROM macro_scenarios;


-- 15. Check missing-like values in rate shock
SELECT
    rate_shock_pp,
    COUNT(*) AS row_count
FROM macro_scenarios
WHERE rate_shock_pp IS NULL
   OR TRIM(rate_shock_pp::varchar) = ''
   OR UPPER(TRIM(rate_shock_pp::varchar)) IN ('N/A', 'NA', '-')
GROUP BY rate_shock_pp
ORDER BY row_count DESC;


-- 16. Display distinct rate shock values
SELECT
    rate_shock_pp,
    COUNT(*) AS row_count
FROM macro_scenarios
GROUP BY rate_shock_pp
ORDER BY row_count DESC;


-- 17. Display distinct credit spread values
SELECT
    credit_spread_bps,
    COUNT(*) AS row_count
FROM macro_scenarios
GROUP BY credit_spread_bps
ORDER BY row_count DESC;


-- 18. Find credit spread values containing the bps unit
SELECT
    credit_spread_bps,
    COUNT(*) AS row_count
FROM macro_scenarios
WHERE LOWER(credit_spread_bps::varchar) LIKE '%bps%'
GROUP BY credit_spread_bps
ORDER BY row_count DESC;


-- 19. Check missing-like credit spread values
SELECT
    credit_spread_bps,
    COUNT(*) AS row_count
FROM macro_scenarios
WHERE credit_spread_bps IS NULL
   OR TRIM(credit_spread_bps::varchar) = ''
   OR UPPER(TRIM(credit_spread_bps::varchar)) IN ('N/A', 'NA', '-')
GROUP BY credit_spread_bps
ORDER BY row_count DESC;


-- 20. Check minimum, maximum, average and standard deviation of stress intensity
SELECT
    COUNT(stress_intensity) AS non_null_count,
    MIN(stress_intensity) AS minimum_value,
    MAX(stress_intensity) AS maximum_value,
    AVG(stress_intensity) AS average_value,
    STDDEV_POP(stress_intensity) AS standard_deviation
FROM macro_scenarios;


-- 21. Check minimum, maximum, average and standard deviation of GDP shock
SELECT
    COUNT(gdp_shock_pp) AS non_null_count,
    MIN(gdp_shock_pp) AS minimum_value,
    MAX(gdp_shock_pp) AS maximum_value,
    AVG(gdp_shock_pp) AS average_value,
    STDDEV_POP(gdp_shock_pp) AS standard_deviation
FROM macro_scenarios;


-- 22. Check minimum, maximum, average and standard deviation of unemployment shock
SELECT
    COUNT(unemp_shock_pp) AS non_null_count,
    MIN(unemp_shock_pp) AS minimum_value,
    MAX(unemp_shock_pp) AS maximum_value,
    AVG(unemp_shock_pp) AS average_value,
    STDDEV_POP(unemp_shock_pp) AS standard_deviation
FROM macro_scenarios;


-- 23. Check minimum, maximum, average and standard deviation of inflation shock
SELECT
    COUNT(inflation_shock_pp) AS non_null_count,
    MIN(inflation_shock_pp) AS minimum_value,
    MAX(inflation_shock_pp) AS maximum_value,
    AVG(inflation_shock_pp) AS average_value,
    STDDEV_POP(inflation_shock_pp) AS standard_deviation
FROM macro_scenarios;


-- 24. Check minimum, maximum, average and standard deviation of FX devaluation
SELECT
    COUNT(fx_devaluation_pct) AS non_null_count,
    MIN(fx_devaluation_pct) AS minimum_value,
    MAX(fx_devaluation_pct) AS maximum_value,
    AVG(fx_devaluation_pct) AS average_value,
    STDDEV_POP(fx_devaluation_pct) AS standard_deviation
FROM macro_scenarios;


-- 25. Calculate quartiles for stress intensity
SELECT
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY stress_intensity::numeric) AS q1,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY stress_intensity::numeric) AS median,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY stress_intensity::numeric) AS q3
FROM macro_scenarios
WHERE stress_intensity IS NOT NULL;


-- 26. Calculate quartiles for GDP shock
SELECT
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY gdp_shock_pp::numeric) AS q1,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY gdp_shock_pp::numeric) AS median,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY gdp_shock_pp::numeric) AS q3
FROM macro_scenarios
WHERE gdp_shock_pp IS NOT NULL;


-- 27. Calculate quartiles for unemployment shock
SELECT
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY unemp_shock_pp::numeric) AS q1,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY unemp_shock_pp::numeric) AS median,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY unemp_shock_pp::numeric) AS q3
FROM macro_scenarios
WHERE unemp_shock_pp IS NOT NULL;


-- 28. Calculate quartiles for inflation shock
SELECT
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY inflation_shock_pp::numeric) AS q1,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY inflation_shock_pp::numeric) AS median,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY inflation_shock_pp::numeric) AS q3
FROM macro_scenarios
WHERE inflation_shock_pp IS NOT NULL;


-- 29. Calculate quartiles for FX devaluation
SELECT
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY fx_devaluation_pct::numeric) AS q1,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY fx_devaluation_pct::numeric) AS median,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY fx_devaluation_pct::numeric) AS q3
FROM macro_scenarios
WHERE fx_devaluation_pct IS NOT NULL;


-- 30. Find negative unemployment shocks
SELECT *
FROM macro_scenarios
WHERE unemp_shock_pp < 0
ORDER BY unemp_shock_pp;


-- 31. Find positive GDP shocks
SELECT *
FROM macro_scenarios
WHERE gdp_shock_pp > 0
ORDER BY gdp_shock_pp DESC;


-- 32. Find negative inflation shocks
SELECT *
FROM macro_scenarios
WHERE inflation_shock_pp < 0
ORDER BY inflation_shock_pp;


-- 33. Find negative FX devaluation values
SELECT *
FROM macro_scenarios
WHERE fx_devaluation_pct < 0
ORDER BY fx_devaluation_pct;


-- 34. Check scenario severity distribution
WITH counts AS (
    SELECT
        LOWER(TRIM(scenario_severity::varchar)) AS normalized_severity,
        COUNT(*) AS scenario_count
    FROM macro_scenarios
    GROUP BY LOWER(TRIM(scenario_severity::varchar))
)
SELECT
    normalized_severity,
    scenario_count,
    ROUND(scenario_count * 100.0 / SUM(scenario_count) OVER (), 2) AS percentage_of_scenarios
FROM counts
ORDER BY scenario_count DESC;


-- 35. Compare stress intensity across severity levels
SELECT
    LOWER(TRIM(scenario_severity::varchar)) AS normalized_severity,
    COUNT(*) AS scenario_count,
    ROUND(AVG(stress_intensity)::numeric, 3) AS average_stress,
    ROUND(MIN(stress_intensity)::numeric, 3) AS minimum_stress,
    ROUND(MAX(stress_intensity)::numeric, 3) AS maximum_stress
FROM macro_scenarios
GROUP BY LOWER(TRIM(scenario_severity::varchar))
ORDER BY average_stress;


-- 36. Compare macroeconomic shocks by severity
SELECT
    LOWER(TRIM(scenario_severity::varchar)) AS normalized_severity,
    COUNT(*) AS scenario_count,
    ROUND(AVG(gdp_shock_pp)::numeric, 3) AS avg_gdp_shock,
    ROUND(AVG(unemp_shock_pp)::numeric, 3) AS avg_unemployment_shock,
    ROUND(AVG(inflation_shock_pp)::numeric, 3) AS avg_inflation_shock,
    ROUND(AVG(fx_devaluation_pct)::numeric, 3) AS avg_fx_devaluation
FROM macro_scenarios
GROUP BY LOWER(TRIM(scenario_severity::varchar))
ORDER BY normalized_severity;


-- 37. Find scenarios with the highest stress intensity
SELECT *
FROM macro_scenarios
WHERE stress_intensity IS NOT NULL
ORDER BY stress_intensity DESC
LIMIT 20;


-- 38. Find scenarios with the largest GDP shocks
SELECT *
FROM macro_scenarios
WHERE gdp_shock_pp IS NOT NULL
ORDER BY gdp_shock_pp DESC
LIMIT 20;


-- 39. Find scenarios with the highest unemployment shocks
SELECT *
FROM macro_scenarios
WHERE unemp_shock_pp IS NOT NULL
ORDER BY unemp_shock_pp DESC
LIMIT 20;


-- 40. Find scenarios with the highest inflation shocks
SELECT *
FROM macro_scenarios
WHERE inflation_shock_pp IS NOT NULL
ORDER BY inflation_shock_pp DESC
LIMIT 20;


-- 41. Find scenarios with the highest FX devaluation
SELECT *
FROM macro_scenarios
WHERE fx_devaluation_pct IS NOT NULL
ORDER BY fx_devaluation_pct DESC
LIMIT 20;


-- 42. Check correlation between stress intensity and GDP shock
SELECT
    CORR(stress_intensity::double precision, gdp_shock_pp::double precision) AS stress_gdp_correlation
FROM macro_scenarios;


-- 43. Check correlation between stress intensity and unemployment shock
SELECT
    CORR(stress_intensity::double precision, unemp_shock_pp::double precision) AS stress_unemployment_correlation
FROM macro_scenarios;


-- 44. Check correlation between stress intensity and inflation shock
SELECT
    CORR(stress_intensity::double precision, inflation_shock_pp::double precision) AS stress_inflation_correlation
FROM macro_scenarios;


-- 45. Check correlation between stress intensity and FX devaluation
SELECT
    CORR(stress_intensity::double precision, fx_devaluation_pct::double precision) AS stress_fx_correlation
FROM macro_scenarios;


-- 46. Check correlations among numeric macroeconomic variables
SELECT
    CORR(gdp_shock_pp::double precision, unemp_shock_pp::double precision) AS gdp_unemployment_correlation,
    CORR(gdp_shock_pp::double precision, inflation_shock_pp::double precision) AS gdp_inflation_correlation,
    CORR(gdp_shock_pp::double precision, fx_devaluation_pct::double precision) AS gdp_fx_correlation,
    CORR(unemp_shock_pp::double precision, inflation_shock_pp::double precision) AS unemployment_inflation_correlation,
    CORR(unemp_shock_pp::double precision, fx_devaluation_pct::double precision) AS unemployment_fx_correlation,
    CORR(inflation_shock_pp::double precision, fx_devaluation_pct::double precision) AS inflation_fx_correlation
FROM macro_scenarios;


-- 47. Find potential IQR outliers for stress intensity
WITH quartiles AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY stress_intensity::numeric) AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY stress_intensity::numeric) AS q3
    FROM macro_scenarios
    WHERE stress_intensity IS NOT NULL
)
SELECT
    m.*,
    q.q1,
    q.q3,
    q.q3 - q.q1 AS iqr
FROM macro_scenarios m
CROSS JOIN quartiles q
WHERE m.stress_intensity < q.q1 - 1.5 * (q.q3 - q.q1)
   OR m.stress_intensity > q.q3 + 1.5 * (q.q3 - q.q1)
ORDER BY m.stress_intensity;


-- 48. Find potential IQR outliers for GDP shock
WITH quartiles AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY gdp_shock_pp::numeric) AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY gdp_shock_pp::numeric) AS q3
    FROM macro_scenarios
    WHERE gdp_shock_pp IS NOT NULL
)
SELECT
    m.*,
    q.q1,
    q.q3,
    q.q3 - q.q1 AS iqr
FROM macro_scenarios m
CROSS JOIN quartiles q
WHERE m.gdp_shock_pp < q.q1 - 1.5 * (q.q3 - q.q1)
   OR m.gdp_shock_pp > q.q3 + 1.5 * (q.q3 - q.q1)
ORDER BY m.gdp_shock_pp;


-- 49. Find potential IQR outliers for unemployment shock
WITH quartiles AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY unemp_shock_pp::numeric) AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY unemp_shock_pp::numeric) AS q3
    FROM macro_scenarios
    WHERE unemp_shock_pp IS NOT NULL
)
SELECT
    m.*,
    q.q1,
    q.q3,
    q.q3 - q.q1 AS iqr
FROM macro_scenarios m
CROSS JOIN quartiles q
WHERE m.unemp_shock_pp < q.q1 - 1.5 * (q.q3 - q.q1)
   OR m.unemp_shock_pp > q.q3 + 1.5 * (q.q3 - q.q1)
ORDER BY m.unemp_shock_pp;


-- 50. Find potential IQR outliers for inflation shock
WITH quartiles AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY inflation_shock_pp::numeric) AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY inflation_shock_pp::numeric) AS q3
    FROM macro_scenarios
    WHERE inflation_shock_pp IS NOT NULL
)
SELECT
    m.*,
    q.q1,
    q.q3,
    q.q3 - q.q1 AS iqr
FROM macro_scenarios m
CROSS JOIN quartiles q
WHERE m.inflation_shock_pp < q.q1 - 1.5 * (q.q3 - q.q1)
   OR m.inflation_shock_pp > q.q3 + 1.5 * (q.q3 - q.q1)
ORDER BY m.inflation_shock_pp;


-- 51. Find potential IQR outliers for FX devaluation
WITH quartiles AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY fx_devaluation_pct::numeric) AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY fx_devaluation_pct::numeric) AS q3
    FROM macro_scenarios
    WHERE fx_devaluation_pct IS NOT NULL
)
SELECT
    m.*,
    q.q1,
    q.q3,
    q.q3 - q.q1 AS iqr
FROM macro_scenarios m
CROSS JOIN quartiles q
WHERE m.fx_devaluation_pct < q.q1 - 1.5 * (q.q3 - q.q1)
   OR m.fx_devaluation_pct > q.q3 + 1.5 * (q.q3 - q.q1)
ORDER BY m.fx_devaluation_pct;


-- 52. Check whether severity labels generally follow stress intensity ordering
SELECT
    LOWER(TRIM(scenario_severity::varchar)) AS normalized_severity,
    MIN(stress_intensity) AS minimum_stress,
    AVG(stress_intensity) AS average_stress,
    MAX(stress_intensity) AS maximum_stress,
    COUNT(*) AS scenario_count
FROM macro_scenarios
GROUP BY LOWER(TRIM(scenario_severity::varchar))
ORDER BY average_stress;


-- 53. Find scenarios with multiple potential data-quality problems
SELECT
    scenario_id,
    scenario_severity,
    rate_shock_pp,
    credit_spread_bps,
    stress_intensity,
    gdp_shock_pp,
    unemp_shock_pp,
    inflation_shock_pp,
    fx_devaluation_pct,
    (
        CASE
            WHEN scenario_id IS NULL OR TRIM(scenario_id::varchar) = '' THEN 1
            ELSE 0
        END
        +
        CASE
            WHEN scenario_severity IS NULL
              OR TRIM(scenario_severity::varchar) = ''
              OR LOWER(TRIM(scenario_severity::varchar)) NOT IN (
                    'baseline',
                    'mild',
                    'moderate',
                    'adverse',
                    'severe'
                )
            THEN 1
            ELSE 0
        END
        +
        CASE
            WHEN rate_shock_pp IS NULL
              OR TRIM(rate_shock_pp::varchar) = ''
              OR UPPER(TRIM(rate_shock_pp::varchar)) IN ('N/A', 'NA', '-')
            THEN 1
            ELSE 0
        END
        +
        CASE
            WHEN credit_spread_bps IS NULL
              OR TRIM(credit_spread_bps::varchar) = ''
              OR UPPER(TRIM(credit_spread_bps::varchar)) IN ('N/A', 'NA', '-')
            THEN 1
            ELSE 0
        END
        +
        CASE
            WHEN stress_intensity IS NULL THEN 1
            ELSE 0
        END
        +
        CASE
            WHEN gdp_shock_pp IS NULL THEN 1
            ELSE 0
        END
        +
        CASE
            WHEN unemp_shock_pp IS NULL THEN 1
            ELSE 0
        END
        +
        CASE
            WHEN inflation_shock_pp IS NULL THEN 1
            ELSE 0
        END
        +
        CASE
            WHEN fx_devaluation_pct IS NULL THEN 1
            ELSE 0
        END
    ) AS quality_issue_count
FROM macro_scenarios
WHERE
    scenario_id IS NULL
    OR TRIM(scenario_id::varchar) = ''
    OR scenario_severity IS NULL
    OR TRIM(scenario_severity::varchar) = ''
    OR LOWER(TRIM(scenario_severity::varchar)) NOT IN (
        'baseline',
        'mild',
        'moderate',
        'adverse',
        'severe'
    )
    OR rate_shock_pp IS NULL
    OR TRIM(rate_shock_pp::varchar) = ''
    OR UPPER(TRIM(rate_shock_pp::varchar)) IN ('N/A', 'NA', '-')
    OR credit_spread_bps IS NULL
    OR TRIM(credit_spread_bps::varchar) = ''
    OR UPPER(TRIM(credit_spread_bps::varchar)) IN ('N/A', 'NA', '-')
    OR stress_intensity IS NULL
    OR gdp_shock_pp IS NULL
    OR unemp_shock_pp IS NULL
    OR inflation_shock_pp IS NULL
    OR fx_devaluation_pct IS NULL
ORDER BY quality_issue_count DESC, scenario_id;


-- 54. Create a final data-quality dashboard
SELECT
    COUNT(*) AS total_rows,

    COUNT(DISTINCT scenario_id) AS unique_scenario_ids,

    COUNT(*) - COUNT(DISTINCT scenario_id) AS duplicate_id_rows,

    COUNT(*) FILTER (
        WHERE scenario_id IS NULL
           OR TRIM(scenario_id::varchar) = ''
    ) AS missing_scenario_ids,

    COUNT(*) FILTER (
        WHERE scenario_severity IS NULL
           OR TRIM(scenario_severity::varchar) = ''
    ) AS missing_severity,

    COUNT(*) FILTER (
        WHERE LOWER(TRIM(scenario_severity::varchar)) NOT IN (
            'baseline',
            'mild',
            'moderate',
            'adverse',
            'severe'
        )
        AND scenario_severity IS NOT NULL
        AND TRIM(scenario_severity::varchar) <> ''
    ) AS invalid_severity_values,

    COUNT(*) FILTER (
        WHERE rate_shock_pp IS NULL
           OR TRIM(rate_shock_pp::varchar) = ''
           OR UPPER(TRIM(rate_shock_pp::varchar)) IN ('N/A', 'NA', '-')
    ) AS invalid_rate_shock_values,

    COUNT(*) FILTER (
        WHERE credit_spread_bps IS NULL
           OR TRIM(credit_spread_bps::varchar) = ''
           OR UPPER(TRIM(credit_spread_bps::varchar)) IN ('N/A', 'NA', '-')
    ) AS missing_credit_spread,

    COUNT(*) FILTER (
        WHERE stress_intensity IS NULL
    ) AS missing_stress_intensity,

    COUNT(*) FILTER (
        WHERE gdp_shock_pp IS NULL
    ) AS missing_gdp_shock,

    COUNT(*) FILTER (
        WHERE unemp_shock_pp IS NULL
    ) AS missing_unemployment_shock,

    COUNT(*) FILTER (
        WHERE inflation_shock_pp IS NULL
    ) AS missing_inflation_shock,

    COUNT(*) FILTER (
        WHERE fx_devaluation_pct IS NULL
    ) AS missing_fx_devaluation

FROM macro_scenarios;


-- 55. Check rows that contain unusual text in rate shock
SELECT
    scenario_id,
    rate_shock_pp
FROM macro_scenarios
WHERE rate_shock_pp IS NOT NULL
  AND TRIM(rate_shock_pp::varchar) <> ''
  AND UPPER(TRIM(rate_shock_pp::varchar)) NOT IN ('N/A', 'NA', '-')
  AND TRIM(rate_shock_pp::varchar) !~ '^-?[0-9]+(\.[0-9]+)?$'
ORDER BY scenario_id;


-- 56. Check rows that contain unusual text in credit spread
SELECT
    scenario_id,
    credit_spread_bps
FROM macro_scenarios
WHERE credit_spread_bps IS NOT NULL
  AND TRIM(credit_spread_bps::varchar) <> ''
  AND UPPER(TRIM(credit_spread_bps::varchar)) NOT IN ('N/A', 'NA', '-')
  AND REGEXP_REPLACE(
        LOWER(TRIM(credit_spread_bps::varchar)),
        '\s*bps\s*$',
        ''
      ) !~ '^-?[0-9]+(\.[0-9]+)?$'
ORDER BY scenario_id;


-- 57. Preview how rate shock values can be converted to numeric
SELECT
    scenario_id,
    rate_shock_pp AS original_rate_shock,
    CASE
        WHEN TRIM(rate_shock_pp::varchar) ~ '^-?[0-9]+(\.[0-9]+)?$'
        THEN TRIM(rate_shock_pp::varchar)::numeric
        ELSE NULL
    END AS cleaned_rate_shock
FROM macro_scenarios
ORDER BY scenario_id;


-- 58. Preview how credit spread values can be converted to numeric
SELECT
    scenario_id,
    credit_spread_bps AS original_credit_spread,
    CASE
        WHEN REGEXP_REPLACE(
                LOWER(TRIM(credit_spread_bps::varchar)),
                '\s*bps\s*$',
                ''
             ) ~ '^-?[0-9]+(\.[0-9]+)?$'
        THEN REGEXP_REPLACE(
                LOWER(TRIM(credit_spread_bps::varchar)),
                '\s*bps\s*$',
                ''
             )::numeric
        ELSE NULL
    END AS cleaned_credit_spread
FROM macro_scenarios
ORDER BY scenario_id;


-- 59. Preview standardized scenario severity values
SELECT
    scenario_id,
    scenario_severity AS original_severity,
    CASE
        WHEN LOWER(TRIM(scenario_severity::varchar)) IN ('baseline')
            THEN 'baseline'
        WHEN LOWER(TRIM(scenario_severity::varchar)) IN ('mild', 'mld')
            THEN 'mild'
        WHEN LOWER(TRIM(scenario_severity::varchar)) IN ('moderate', 'moderat')
            THEN 'moderate'
        WHEN LOWER(TRIM(scenario_severity::varchar)) IN ('adverse', 'advers')
            THEN 'adverse'
        WHEN LOWER(TRIM(scenario_severity::varchar)) = 'severe'
            THEN 'severe'
        ELSE NULL
    END AS standardized_severity
FROM macro_scenarios
ORDER BY scenario_id;


-- 60. Final list of scenario IDs requiring manual review
SELECT
    scenario_id,
    scenario_severity,
    rate_shock_pp,
    credit_spread_bps,
    stress_intensity,
    gdp_shock_pp,
    unemp_shock_pp,
    inflation_shock_pp,
    fx_devaluation_pct
FROM macro_scenarios
WHERE
    scenario_id IN (
        SELECT scenario_id
        FROM macro_scenarios
        GROUP BY scenario_id
        HAVING COUNT(*) > 1
    )
    OR scenario_severity IS NULL
    OR TRIM(scenario_severity::varchar) = ''
    OR LOWER(TRIM(scenario_severity::varchar)) NOT IN (
        'baseline',
        'mild',
        'moderate',
        'adverse',
        'severe'
    )
    OR rate_shock_pp IS NULL
    OR TRIM(rate_shock_pp::varchar) = ''
    OR UPPER(TRIM(rate_shock_pp::varchar)) IN ('N/A', 'NA', '-')
    OR credit_spread_bps IS NULL
    OR TRIM(credit_spread_bps::varchar) = ''
    OR UPPER(TRIM(credit_spread_bps::varchar)) IN ('N/A', 'NA', '-')
ORDER BY scenario_id;