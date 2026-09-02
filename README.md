# Bank Stress-Testing Simulator — Data Quality EDA

## Project
A "what-if" simulator: given a macroeconomic shock scenario, predict how many loans go bad and whether banks still meet regulatory capital/liquidity requirements. Data is synthetically generated to resemble real-world bank data, and deliberately includes realistic data-quality issues.

## Files
| File | Rows | Grain |
|---|---|---|
| `bank_profiles.csv` | 42 | One row per bank |
| `loan_portfolio.csv` | 3,006 | One row per loan (not linked to a bank by ID — connects via `sector`) |
| `macro_scenarios.csv` | 504 | One row per macro shock scenario |
| `macro_stress_scenarios.csv` | 60 | One row per (scenario × sector) |
| `bank_stress_simulated_panel.csv` | 20,025 | One row per (bank × scenario) — the output/target table |

## Schema relationships
- `bank_profiles.bank_id` ↔ `panel.bank_id` (clean join)
- `macro_scenarios.scenario_id` ↔ `panel.scenario_id` (clean join)
- `loan_portfolio.sector` ↔ `macro_stress_scenarios.sector` — **should** match but needs cleaning first
- `macro_stress_scenarios.scenario` (e.g. `gfc_like`, `covid_like`) vs `panel.scenario_severity` (baseline/mild/moderate/adverse/severe) — different vocabularies, mapping still needs to be decided

## Data quality findings

### `bank_profiles.csv`
- `bank_id`: 5 rows with format inconsistencies (whitespace, missing underscore, hyphen, lowercase)
- 2 exact duplicate rows
- `total_assets_usd`: 5 rows with `$`/comma formatting
- `baseline_liquidity_ratio_pct`: 6 rows with `%` suffix
- `baseline_roa_pct`: 5 missing (3 NaN + 2 `'unknown'`)
- `size_tier`: ~10 spelling/casing variants of 3 real tiers
- `sector_concentration`: 7 variants of 2 real categories

### `bank_stress_simulated_panel.csv`
- `car_after_pct`: 130 missing (74 NaN + 56 disguised tokens) — **critical column**, drives the regulatory pass/fail check
- `incremental_credit_loss_usd`: 120 rows with `$`/comma formatting
- `liquidity_after_pct`: 150 missing (69 NaN + 60 text tokens + 21 fake `-1` sentinels — caught via range check, not visible in dtype/regex alone)
- `roa_after_pct`: 15 rows with a 100x decimal-shift error (e.g. `52.0` instead of `0.52`) — fix by dividing by 100, not dropping
- `bank_condition`: 13 variants of 3 real classes (**target/label column** — highest priority fix)
- `scenario_severity`: 15 variants of 5 real severity tiers
- 25 duplicate rows
- `size_tier`, `sector_concentration`: clean in this file (unlike in `bank_profiles`)

### `loan_portfolio.csv`
- `loan_id`: 8 lowercase IDs
- 6 duplicate rows
- `sector`: **48 spelling variants of 10 real sectors** — worst fragmentation in the dataset; must be cleaned to match `macro_stress_scenarios.sector` before any sector-level join
- `pd_annual`: 131 rows needing cleanup — mix of percent-string encoding (e.g. `'1.07%'` = `0.0107`, not just symbol removal) and true missing tokens
- `lgd`: 51 rows needing cleanup (30 NaN + 21 missing tokens)
- `ead`: 51 rows with comma formatting
- `loan_amount`: 5 negative values (likely sign error, not confirmed)

## Key lessons from this EDA
- Dtype and `.isna()` checks alone are not enough — sentinel values (`-1`, `999`, `-999`) can hide inside clean-looking numeric columns and only surface via range/plausibility checks.
- The same column name can be clean in one file and dirty in another (`size_tier`, `sector_concentration`) — check every file independently.
- Some "non-numeric" issues are unit mismatches, not formatting issues (`pd_annual` percent-strings) — blind symbol-stripping would produce invalid values.

## Still to do
- Map `macro_scenarios.csv` and `macro_stress_scenarios.csv`
- Decide on missing-value strategy per column (drop / impute / flag)
- Build the full cleaning script, duplicates dropped first
- Resolve the `scenario` vs `scenario_severity` vocabulary mismatch
