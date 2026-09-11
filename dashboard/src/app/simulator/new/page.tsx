"use client";

import * as React from "react";
import { FlaskConical, RotateCcw, Brain, AlertTriangle, CheckCircle, ListChecks, Sparkles, RefreshCw } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { Slider } from "@/components/ui/slider";
import { Switch } from "@/components/ui/switch";
import { Select } from "@/components/ui/select";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import { predict, getRecommendation, type PredictResponse, type RecommendResponse, type ModelType } from "@/lib/api";

const DEFAULT_VALUES = {
  size_score: 0.5,
  concentration_flag: 0,
  top_sector_weight: 0.25,
  sector_risk_score: 0.0,
  bank_risk_factor: 0.0,
  loan_to_asset_ratio: 0.5,
  deposit_to_asset_ratio: 0.7,
  car_buffer: 3.0,
  liquidity_buffer: 20.0,
  baseline_roa_pct: 1.5,
  severity_score: 2,
  shock_severity_score: 0.5,
};

export default function NewSimulationPage() {
  const [model, setModel] = React.useState<ModelType>("logistic_regression");
  const [values, setValues] = React.useState(DEFAULT_VALUES);
  const [result, setResult] = React.useState<PredictResponse | null>(null);
  const [recommendation, setRecommendation] = React.useState<RecommendResponse | null>(null);
  const [recLoading, setRecLoading] = React.useState(false);
  const [recError, setRecError] = React.useState<string | null>(null);
  const [loading, setLoading] = React.useState(false);
  const [error, setError] = React.useState<string | null>(null);

  const updateValue = <K extends keyof typeof DEFAULT_VALUES>(
    key: K,
    val: (typeof DEFAULT_VALUES)[K]
  ) => {
    setValues((prev) => ({ ...prev, [key]: val }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    setResult(null);

    try {
      const response = await predict({
        model,
        ...values,
      });
      setResult(response);

      // Save to history
      const entry = {
        bank_id: "SIM-" + Date.now().toString(36).toUpperCase(),
        scenario_id: Math.floor(Math.random() * 500) + 1,
        model_used: response.model_used,
        predicted_condition: response.predicted_condition,
        timestamp: new Date().toISOString(),
        probabilities: {
          healthy: response.prob_healthy,
          stressed: response.prob_stressed,
          critical: response.prob_critical,
        },
      };
      const stored = localStorage.getItem("simulation_history");
      const history = stored ? JSON.parse(stored) : [];
      history.unshift(entry);
      localStorage.setItem("simulation_history", JSON.stringify(history.slice(0, 100)));

      // Fetch recommendation from LLM
      setRecLoading(true);
      setRecError(null);
      setRecommendation(null);
      try {
        const rec = await getRecommendation({
          model,
          ...values,
          predicted_condition: response.predicted_condition,
          prob_healthy: response.prob_healthy,
          prob_stressed: response.prob_stressed,
          prob_critical: response.prob_critical,
        });
        setRecommendation(rec);
      } catch (recErr) {
        setRecError(recErr instanceof Error ? recErr.message : "Recommendation failed");
      } finally {
        setRecLoading(false);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : "Prediction failed");
    } finally {
      setLoading(false);
    }
  };

  const handleReset = () => {
    setValues(DEFAULT_VALUES);
    setResult(null);
    setRecommendation(null);
    setRecError(null);
    setError(null);
  };

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold tracking-tight">New Simulation</h2>
        <p className="text-muted-foreground">
          Configure bank parameters and run a stress test prediction
        </p>
      </div>

      <div className="grid gap-6 lg:grid-cols-3">
        {/* Form */}
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <FlaskConical className="h-5 w-5 text-primary" />
              Simulation Parameters
            </CardTitle>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="space-y-6">
              {/* Model selector */}
              <div className="space-y-2">
                <Label>Model</Label>
                <RadioGroup
                  value={model}
                  onValueChange={(v) => setModel(v as ModelType)}
                  className="flex gap-4"
                >
                  <label className="flex items-center gap-2 cursor-pointer rounded-lg border p-3 flex-1 data-[state=checked]:border-primary data-[state=checked]:bg-primary/5 hover:bg-accent/50 transition-colors">
                    <RadioGroupItem value="logistic_regression" />
                    <span className="text-sm font-medium">Logistic Regression</span>
                  </label>
                  <label className="flex items-center gap-2 cursor-pointer rounded-lg border p-3 flex-1 data-[state=checked]:border-primary data-[state=checked]:bg-primary/5 hover:bg-accent/50 transition-colors">
                    <RadioGroupItem value="random_forest" />
                    <span className="text-sm font-medium">Random Forest</span>
                  </label>
                </RadioGroup>
              </div>

              {/* Feature inputs grid */}
              <div className="grid gap-4 md:grid-cols-2">
                <div className="space-y-2">
                  <Label htmlFor="size_score">Size Score</Label>
                  <Input
                    id="size_score"
                    type="number"
                    step="0.01"
                    value={values.size_score}
                    onChange={(e) => updateValue("size_score", parseFloat(e.target.value) || 0)}
                  />
                </div>

                <div className="space-y-2">
                  <Label className="flex items-center justify-between">
                    <span>Concentration Flag</span>
                    <span className="text-xs text-muted-foreground">
                      {values.concentration_flag ? "Yes (1)" : "No (0)"}
                    </span>
                  </Label>
                  <div className="flex items-center h-10">
                    <Switch
                      checked={values.concentration_flag === 1}
                      onCheckedChange={(checked) =>
                        updateValue("concentration_flag", checked ? 1 : 0)
                      }
                    />
                  </div>
                </div>

                <div className="space-y-2">
                  <Label className="flex items-center justify-between">
                    <span>Top Sector Weight</span>
                    <span className="text-xs text-muted-foreground">
                      {values.top_sector_weight.toFixed(2)}
                    </span>
                  </Label>
                  <Slider
                    value={[values.top_sector_weight]}
                    onValueChange={([v]) => updateValue("top_sector_weight", v)}
                    min={0}
                    max={1}
                    step={0.01}
                    className="py-3"
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="sector_risk_score">Sector Risk Score</Label>
                  <Input
                    id="sector_risk_score"
                    type="number"
                    step="0.01"
                    value={values.sector_risk_score}
                    onChange={(e) =>
                      updateValue("sector_risk_score", parseFloat(e.target.value) || 0)
                    }
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="bank_risk_factor">Bank Risk Factor</Label>
                  <Input
                    id="bank_risk_factor"
                    type="number"
                    step="0.01"
                    value={values.bank_risk_factor}
                    onChange={(e) =>
                      updateValue("bank_risk_factor", parseFloat(e.target.value) || 0)
                    }
                  />
                </div>

                <div className="space-y-2">
                  <Label className="flex items-center justify-between">
                    <span>Loan to Asset Ratio</span>
                    <span className="text-xs text-muted-foreground">
                      {values.loan_to_asset_ratio.toFixed(2)}
                    </span>
                  </Label>
                  <Slider
                    value={[values.loan_to_asset_ratio]}
                    onValueChange={([v]) => updateValue("loan_to_asset_ratio", v)}
                    min={0}
                    max={1}
                    step={0.01}
                    className="py-3"
                  />
                </div>

                <div className="space-y-2">
                  <Label className="flex items-center justify-between">
                    <span>Deposit to Asset Ratio</span>
                    <span className="text-xs text-muted-foreground">
                      {values.deposit_to_asset_ratio.toFixed(2)}
                    </span>
                  </Label>
                  <Slider
                    value={[values.deposit_to_asset_ratio]}
                    onValueChange={([v]) => updateValue("deposit_to_asset_ratio", v)}
                    min={0}
                    max={1}
                    step={0.01}
                    className="py-3"
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="car_buffer">CAR Buffer</Label>
                  <Input
                    id="car_buffer"
                    type="number"
                    step="0.1"
                    value={values.car_buffer}
                    onChange={(e) =>
                      updateValue("car_buffer", parseFloat(e.target.value) || 0)
                    }
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="liquidity_buffer">Liquidity Buffer</Label>
                  <Input
                    id="liquidity_buffer"
                    type="number"
                    step="0.1"
                    value={values.liquidity_buffer}
                    onChange={(e) =>
                      updateValue("liquidity_buffer", parseFloat(e.target.value) || 0)
                    }
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="baseline_roa_pct">Baseline ROA %</Label>
                  <Input
                    id="baseline_roa_pct"
                    type="number"
                    step="0.01"
                    value={values.baseline_roa_pct}
                    onChange={(e) =>
                      updateValue("baseline_roa_pct", parseFloat(e.target.value) || 0)
                    }
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="severity_score">Severity Score</Label>
                  <Select
                    id="severity_score"
                    value={String(values.severity_score)}
                    onChange={(e) =>
                      updateValue("severity_score", parseInt(e.target.value, 10))
                    }
                    options={[
                      { value: "1", label: "1 — Mild" },
                      { value: "2", label: "2 — Moderate" },
                      { value: "3", label: "3 — Severe" },
                    ]}
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="shock_severity_score">Shock Severity Score</Label>
                  <Input
                    id="shock_severity_score"
                    type="number"
                    step="0.01"
                    value={values.shock_severity_score}
                    onChange={(e) =>
                      updateValue("shock_severity_score", parseFloat(e.target.value) || 0)
                    }
                  />
                </div>
              </div>

              <div className="flex gap-3">
                <Button type="submit" disabled={loading} className="flex-1">
                  {loading ? "Predicting..." : "Run Simulation"}
                </Button>
                <Button type="button" variant="outline" onClick={handleReset}>
                  <RotateCcw className="h-4 w-4 mr-2" />
                  Reset
                </Button>
              </div>
            </form>
          </CardContent>
        </Card>

        {/* Result panel */}
        <div className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Prediction Result</CardTitle>
            </CardHeader>
            <CardContent>
              {loading && (
                <div className="space-y-4">
                  <Skeleton className="h-10 w-full" />
                  <Skeleton className="h-6 w-full" />
                  <Skeleton className="h-32 w-full" />
                </div>
              )}

              {error && (
                <div className="rounded-lg bg-destructive/10 p-4 text-sm text-destructive">
                  {error}
                </div>
              )}

              {!loading && !error && !result && (
                <div className="flex flex-col items-center justify-center h-48 text-muted-foreground">
                  <FlaskConical className="h-10 w-10 mb-2 opacity-40" />
                  <p className="text-sm">Configure parameters and submit</p>
                </div>
              )}

              {!loading && result && (
                <div className="space-y-4">
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-muted-foreground">Model</span>
                    <Badge variant="secondary">{result.model_used}</Badge>
                  </div>

                  <div className="flex items-center justify-between">
                    <span className="text-sm text-muted-foreground">Prediction</span>
                    <Badge
                      variant={
                        result.predicted_condition === "Healthy"
                          ? "healthy"
                          : result.predicted_condition === "Stressed"
                          ? "stressed"
                          : "critical"
                      }
                      className="text-sm px-3 py-1"
                    >
                      {result.predicted_condition}
                    </Badge>
                  </div>

                  <div className="space-y-2">
                    <span className="text-sm text-muted-foreground">Probabilities</span>
                    <div className="flex h-8 w-full rounded-lg overflow-hidden">
                      <div
                        className="bg-healthy flex items-center justify-center text-xs font-medium text-white"
                        style={{ width: `${(result.prob_healthy * 100).toFixed(0)}%` }}
                      >
                        {result.prob_healthy > 0.1
                          ? `${(result.prob_healthy * 100).toFixed(0)}%`
                          : ""}
                      </div>
                      <div
                        className="bg-stressed flex items-center justify-center text-xs font-medium text-white"
                        style={{ width: `${(result.prob_stressed * 100).toFixed(0)}%` }}
                      >
                        {result.prob_stressed > 0.1
                          ? `${(result.prob_stressed * 100).toFixed(0)}%`
                          : ""}
                      </div>
                      <div
                        className="bg-critical flex items-center justify-center text-xs font-medium text-white"
                        style={{ width: `${(result.prob_critical * 100).toFixed(0)}%` }}
                      >
                        {result.prob_critical > 0.1
                          ? `${(result.prob_critical * 100).toFixed(0)}%`
                          : ""}
                      </div>
                    </div>
                    <div className="flex justify-between text-xs text-muted-foreground">
                      <span>Healthy: {(result.prob_healthy * 100).toFixed(1)}%</span>
                      <span>Stressed: {(result.prob_stressed * 100).toFixed(1)}%</span>
                      <span>Critical: {(result.prob_critical * 100).toFixed(1)}%</span>
                    </div>
                  </div>

                  <Button
                    variant="outline"
                    className="w-full"
                    onClick={handleReset}
                  >
                    Run Another Simulation
                  </Button>
                </div>
              )}
            </CardContent>
          </Card>

          {/* AI Recommendation Section */}
          {result && (
            <Card className="border-primary/20">
              <CardHeader className="pb-3">
                <CardTitle className="flex items-center gap-2 text-base">
                  <Brain className="h-5 w-5 text-primary" />
                  AI Analysis & Recommendations
                </CardTitle>
              </CardHeader>
              <CardContent>
                {recLoading && (
                  <div className="space-y-3">
                    <div className="flex items-center gap-2 text-sm text-muted-foreground">
                      <Sparkles className="h-4 w-4 animate-pulse text-primary" />
                      Analyzing prediction with AI...
                    </div>
                    <Skeleton className="h-16 w-full" />
                    <Skeleton className="h-10 w-full" />
                    <Skeleton className="h-10 w-full" />
                  </div>
                )}

                {recError && (
                  <div className="space-y-3">
                    <div className="rounded-lg bg-destructive/10 p-3 text-sm text-destructive">
                      {recError}
                    </div>
                    <Button
                      variant="outline"
                      size="sm"
                      className="w-full"
                      onClick={async () => {
                        if (!result) return;
                        setRecLoading(true);
                        setRecError(null);
                        try {
                          const rec = await getRecommendation({
                            model,
                            ...values,
                            predicted_condition: result.predicted_condition,
                            prob_healthy: result.prob_healthy,
                            prob_stressed: result.prob_stressed,
                            prob_critical: result.prob_critical,
                          });
                          setRecommendation(rec);
                        } catch (err) {
                          setRecError(err instanceof Error ? err.message : "Recommendation failed");
                        } finally {
                          setRecLoading(false);
                        }
                      }}
                    >
                      <RefreshCw className="h-4 w-4 mr-2" />
                      Retry
                    </Button>
                  </div>
                )}

                {!recLoading && !recError && recommendation && (
                  <div className="space-y-4">
                    {/* Explanation */}
                    <div className="space-y-2">
                      <div className="flex items-center gap-2 text-sm font-medium">
                        <Sparkles className="h-4 w-4 text-primary" />
                        Why this prediction?
                      </div>
                      <p className="text-sm text-muted-foreground leading-relaxed">
                        {recommendation.explanation}
                      </p>
                    </div>

                    {/* Key Drivers */}
                    {recommendation.key_drivers.length > 0 && (
                      <div className="space-y-2">
                        <div className="flex items-center gap-2 text-sm font-medium">
                          <AlertTriangle className="h-4 w-4 text-amber-500" />
                          Key Contributing Factors
                        </div>
                        <ul className="space-y-1.5">
                          {recommendation.key_drivers.map((driver, i) => (
                            <li
                              key={i}
                              className="flex items-start gap-2 text-sm text-muted-foreground"
                            >
                              <span className="mt-1.5 h-1.5 w-1.5 rounded-full bg-amber-500 shrink-0" />
                              {driver}
                            </li>
                          ))}
                        </ul>
                      </div>
                    )}

                    {/* Next Steps */}
                    {recommendation.next_steps.length > 0 && (
                      <div className="space-y-2">
                        <div className="flex items-center gap-2 text-sm font-medium">
                          <ListChecks className="h-4 w-4 text-emerald-500" />
                          Recommended Next Steps
                        </div>
                        <ol className="space-y-1.5">
                          {recommendation.next_steps.map((step, i) => (
                            <li
                              key={i}
                              className="flex items-start gap-2 text-sm text-muted-foreground"
                            >
                              <span className="mt-0.5 flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-emerald-500/10 text-xs font-medium text-emerald-600">
                                {i + 1}
                              </span>
                              {step}
                            </li>
                          ))}
                        </ol>
                      </div>
                    )}
                  </div>
                )}
              </CardContent>
            </Card>
          )}
        </div>
      </div>
    </div>
  );
}
