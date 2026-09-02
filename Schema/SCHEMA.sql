-- DROP SCHEMA public;

CREATE SCHEMA public AUTHORIZATION pg_database_owner;

COMMENT ON SCHEMA public IS 'standard public schema';
-- public.bank_profiles definition

-- Drop table

-- DROP TABLE public.bank_profiles;

CREATE TABLE public.bank_profiles (
	bank_id varchar(50) NULL,
	size_tier varchar(50) NULL,
	total_assets_usd varchar(50) NULL,
	total_loans_usd float4 NULL,
	deposit_base_usd float4 NULL,
	baseline_car_pct varchar(50) NULL,
	baseline_liquidity_ratio_pct varchar(50) NULL,
	baseline_roa_pct varchar(50) NULL,
	sector_concentration varchar(50) NULL,
	bank_risk_factor float4 NULL,
	"sector_wt_Technology" float4 NULL,
	"sector_wt_Healthcare" float4 NULL,
	"sector_wt_Real_Estate" float4 NULL,
	"sector_wt_Energy" float4 NULL,
	"sector_wt_Industrials" float4 NULL,
	"sector_wt_Retail" float4 NULL,
	"sector_wt_Telecom" float4 NULL,
	"sector_wt_Consumer" float4 NULL,
	"sector_wt_Utilities" float4 NULL,
	"sector_wt_Financials" float4 NULL
);


-- public.bank_stress_simulated_panel definition

-- Drop table

-- DROP TABLE public.bank_stress_simulated_panel;

CREATE TABLE public.bank_stress_simulated_panel (
	bank_id varchar(50) NULL,
	scenario_id varchar(50) NULL,
	size_tier varchar(50) NULL,
	sector_concentration varchar(50) NULL,
	total_assets_usd float4 NULL,
	total_loans_usd float4 NULL,
	baseline_car_pct float4 NULL,
	baseline_liquidity_ratio_pct float4 NULL,
	baseline_roa_pct float4 NULL,
	gdp_shock_pp float4 NULL,
	unemp_shock_pp float4 NULL,
	rate_shock_pp float4 NULL,
	credit_spread_bps float4 NULL,
	inflation_shock_pp float4 NULL,
	fx_devaluation_pct float4 NULL,
	scenario_severity varchar(50) NULL,
	weighted_pd_multiplier float4 NULL,
	projected_npl_ratio_pct float4 NULL,
	stressed_el_rate_pct float4 NULL,
	incremental_credit_loss_usd varchar(50) NULL,
	car_after_pct varchar(50) NULL,
	roa_after_pct float4 NULL,
	liquidity_after_pct varchar(50) NULL,
	bank_condition varchar(50) NULL
);


-- public.loan_portfolio definition

-- Drop table

-- DROP TABLE public.loan_portfolio;

CREATE TABLE public.loan_portfolio (
	loan_id varchar(50) NULL,
	sector varchar(50) NULL,
	pd_annual varchar(50) NULL,
	lgd varchar(50) NULL,
	ead varchar(50) NULL,
	rwa float4 NULL,
	loan_amount float4 NULL
);


-- public.macro_scenarios definition

-- Drop table

-- DROP TABLE public.macro_scenarios;

CREATE TABLE public.macro_scenarios (
	scenario_id varchar(50) NULL,
	stress_intensity float4 NULL,
	scenario_severity varchar(50) NULL,
	gdp_shock_pp float4 NULL,
	unemp_shock_pp float4 NULL,
	rate_shock_pp varchar(50) NULL,
	credit_spread_bps varchar(50) NULL,
	inflation_shock_pp float4 NULL,
	fx_devaluation_pct float4 NULL
);


-- public.macro_stress_scenarios definition

-- Drop table

-- DROP TABLE public.macro_stress_scenarios;

CREATE TABLE public.macro_stress_scenarios (
	scenario varchar(50) NULL,
	sector varchar(50) NULL,
	gdp_shock_pp float4 NULL,
	unemp_shock_pp float4 NULL,
	rate_shock_pp float4 NULL,
	credit_spread_bps float4 NULL,
	inflation_shock_pp float4 NULL,
	fx_devaluation_pct float4 NULL,
	pd_multiplier varchar(50) NULL,
	base_lgd float4 NULL,
	stressed_lgd float4 NULL
);