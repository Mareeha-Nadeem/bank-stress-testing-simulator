const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL || "http://localhost:8000";

export type ModelType = "logistic_regression" | "random_forest";

export interface PredictRequest {
  model: ModelType;
  size_score: number;
  concentration_flag: number;
  top_sector_weight: number;
  sector_risk_score: number;
  bank_risk_factor: number;
  loan_to_asset_ratio: number;
  deposit_to_asset_ratio: number;
  car_buffer: number;
  liquidity_buffer: number;
  baseline_roa_pct: number;
  severity_score: number;
  shock_severity_score: number;
}

export interface PredictResponse {
  predicted_condition: string;
  predicted_condition_code: number;
  prob_healthy: number;
  prob_stressed: number;
  prob_critical: number;
  model_used: string;
}

export interface RecommendRequest extends PredictRequest {
  predicted_condition: string;
  prob_healthy: number;
  prob_stressed: number;
  prob_critical: number;
}

export interface RecommendResponse {
  explanation: string;
  key_drivers: string[];
  next_steps: string[];
}

export interface PerClassMetrics {
  precision: number;
  recall: number;
  f1_score: number;
  support: number;
}

export interface ModelMetrics {
  model_name: string;
  accuracy: number;
  macro_avg: PerClassMetrics;
  weighted_avg: PerClassMetrics;
  per_class: Record<string, PerClassMetrics>;
}

export interface BankSummary {
  bank_id: string;
  total_simulations: number;
  healthy_pct: number;
  stressed_pct: number;
  critical_pct: number;
}

export interface BankDetail {
  bank_id: string;
  profile: Record<string, unknown>;
  simulations: Record<string, unknown>[];
}

export interface ScenarioSummary {
  scenario_id: string;
  num_banks: number;
  dominant_condition: string;
  healthy_pct: number;
  stressed_pct: number;
  critical_pct: number;
}

export async function predict(data: PredictRequest): Promise<PredictResponse> {
  const res = await fetch(`${BACKEND_URL}/predict`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Prediction failed (${res.status}): ${text}`);
  }
  return res.json();
}

export async function getRecommendation(
  data: PredictRequest & { predicted_condition: string; prob_healthy: number; prob_stressed: number; prob_critical: number }
): Promise<RecommendResponse> {
  const res = await fetch(`${BACKEND_URL}/recommend`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Recommendation failed (${res.status}): ${text}`);
  }
  return res.json();
}

export async function getModelMetrics(modelName: string): Promise<ModelMetrics> {
  const res = await fetch(`${BACKEND_URL}/metrics/${modelName}`);
  if (!res.ok) throw new Error(`Failed to fetch metrics for ${modelName}`);
  return res.json();
}

export async function getAllModelMetrics(): Promise<ModelMetrics[]> {
  const models = ["logistic_regression", "random_forest", "xgboost"];
  const results = await Promise.all(models.map(getModelMetrics));
  return results;
}

export async function getBanks(): Promise<BankSummary[]> {
  const res = await fetch(`${BACKEND_URL}/banks`);
  if (!res.ok) throw new Error("Failed to fetch banks");
  return res.json();
}

export async function getBankDetail(bankId: string): Promise<BankDetail> {
  const res = await fetch(`${BACKEND_URL}/banks/${encodeURIComponent(bankId)}`);
  if (!res.ok) throw new Error(`Failed to fetch bank ${bankId}`);
  return res.json();
}

export async function getScenarios(): Promise<ScenarioSummary[]> {
  const res = await fetch(`${BACKEND_URL}/scenarios`);
  if (!res.ok) throw new Error("Failed to fetch scenarios");
  return res.json();
}
