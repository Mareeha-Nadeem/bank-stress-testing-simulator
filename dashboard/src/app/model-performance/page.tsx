"use client";

import * as React from "react";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from "recharts";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { getAllModelMetrics, type ModelMetrics } from "@/lib/api";

const MODEL_LABELS: Record<string, string> = {
  logistic_regression: "Logistic Regression",
  random_forest: "Random Forest",
  xgboost: "XGBoost",
};

export default function ModelPerformanceOverview() {
  const [metrics, setMetrics] = React.useState<ModelMetrics[]>([]);
  const [loading, setLoading] = React.useState(true);
  const [error, setError] = React.useState<string | null>(null);

  React.useEffect(() => {
    getAllModelMetrics()
      .then(setMetrics)
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-10 w-64" />
        <Skeleton className="h-64 rounded-xl" />
        <Skeleton className="h-80 rounded-xl" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="space-y-6">
        <div className="rounded-lg bg-destructive/10 p-4 text-sm text-destructive">
          Failed to load metrics: {error}
        </div>
      </div>
    );
  }

  const comparisonRows = metrics.map((m) => ({
    model: MODEL_LABELS[m.model_name] || m.model_name,
    accuracy: m.accuracy,
    macro_precision: m.macro_avg.precision,
    macro_recall: m.macro_avg.recall,
    macro_f1: m.macro_avg.f1_score,
  }));

  const f1ChartData = metrics.map((m) => ({
    model: MODEL_LABELS[m.model_name] || m.model_name,
    "Macro F1": Number(m.macro_avg.f1_score.toFixed(4)),
    "Macro Precision": Number(m.macro_avg.precision.toFixed(4)),
    "Macro Recall": Number(m.macro_avg.recall.toFixed(4)),
  }));

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold tracking-tight">Model Performance</h2>
        <p className="text-muted-foreground">Comparison across all trained models</p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Model Comparison</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b">
                  <th className="text-left py-2 px-3 font-medium text-muted-foreground">Model</th>
                  <th className="text-left py-2 px-3 font-medium text-muted-foreground">Accuracy</th>
                  <th className="text-left py-2 px-3 font-medium text-muted-foreground">Macro Precision</th>
                  <th className="text-left py-2 px-3 font-medium text-muted-foreground">Macro Recall</th>
                  <th className="text-left py-2 px-3 font-medium text-muted-foreground">Macro F1</th>
                </tr>
              </thead>
              <tbody>
                {comparisonRows.map((row, i) => (
                  <tr key={i} className="border-b last:border-0">
                    <td className="py-3 px-3 font-medium">{row.model}</td>
                    <td className="py-3 px-3">{row.accuracy.toFixed(4)}</td>
                    <td className="py-3 px-3">{row.macro_precision.toFixed(4)}</td>
                    <td className="py-3 px-3">{row.macro_recall.toFixed(4)}</td>
                    <td className="py-3 px-3 font-semibold">{row.macro_f1.toFixed(4)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Macro Metrics Comparison</CardTitle>
        </CardHeader>
        <CardContent>
          <ResponsiveContainer width="100%" height={320}>
            <BarChart data={f1ChartData} margin={{ top: 20, right: 30, left: 20, bottom: 5 }}>
              <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
              <XAxis dataKey="model" className="text-xs" />
              <YAxis domain={[0.7, 1.0]} className="text-xs" />
              <Tooltip
                contentStyle={{
                  backgroundColor: "hsl(var(--card))",
                  border: "1px solid hsl(var(--border))",
                  borderRadius: "0.5rem",
                }}
              />
              <Legend />
              <Bar dataKey="Macro F1" fill="hsl(217, 91%, 60%)" radius={[4, 4, 0, 0]} />
              <Bar dataKey="Macro Precision" fill="hsl(142, 71%, 45%)" radius={[4, 4, 0, 0]} />
              <Bar dataKey="Macro Recall" fill="hsl(38, 92%, 50%)" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Per-Class Breakdown</CardTitle>
        </CardHeader>
        <CardContent>
          <Tabs defaultValue={metrics[0]?.model_name || "logistic_regression"}>
            <TabsList className="mb-4">
              {metrics.map((m) => (
                <TabsTrigger key={m.model_name} value={m.model_name}>
                  {MODEL_LABELS[m.model_name] || m.model_name}
                </TabsTrigger>
              ))}
            </TabsList>
            {metrics.map((m) => (
              <TabsContent key={m.model_name} value={m.model_name}>
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-b">
                        <th className="text-left py-2 px-3 font-medium text-muted-foreground">Class</th>
                        <th className="text-left py-2 px-3 font-medium text-muted-foreground">Precision</th>
                        <th className="text-left py-2 px-3 font-medium text-muted-foreground">Recall</th>
                        <th className="text-left py-2 px-3 font-medium text-muted-foreground">F1 Score</th>
                        <th className="text-left py-2 px-3 font-medium text-muted-foreground">Support</th>
                      </tr>
                    </thead>
                    <tbody>
                      {Object.entries(m.per_class).map(([cls, vals]) => (
                        <tr key={cls} className="border-b last:border-0">
                          <td className="py-2 px-3">
                            <Badge
                              variant={
                                cls === "Healthy" ? "healthy"
                                : cls === "Stressed" ? "stressed"
                                : cls === "Critical" ? "critical"
                                : "secondary"
                              }
                            >
                              {cls}
                            </Badge>
                          </td>
                          <td className="py-2 px-3">{vals.precision.toFixed(4)}</td>
                          <td className="py-2 px-3">{vals.recall.toFixed(4)}</td>
                          <td className="py-2 px-3">{vals.f1_score.toFixed(4)}</td>
                          <td className="py-2 px-3">{vals.support}</td>
                        </tr>
                      ))}
                      <tr className="border-t-2 font-semibold">
                        <td className="py-2 px-3">Accuracy</td>
                        <td className="py-2 px-3" colSpan={3}>{m.accuracy.toFixed(4)}</td>
                        <td className="py-2 px-3">
                          {Object.values(m.per_class).reduce((s, v) => s + v.support, 0)}
                        </td>
                      </tr>
                      <tr className="font-medium text-muted-foreground">
                        <td className="py-2 px-3">Macro Avg</td>
                        <td className="py-2 px-3">{m.macro_avg.precision.toFixed(4)}</td>
                        <td className="py-2 px-3">{m.macro_avg.recall.toFixed(4)}</td>
                        <td className="py-2 px-3">{m.macro_avg.f1_score.toFixed(4)}</td>
                        <td className="py-2 px-3">
                          {Object.values(m.per_class).reduce((s, v) => s + v.support, 0)}
                        </td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </TabsContent>
            ))}
          </Tabs>
        </CardContent>
      </Card>
    </div>
  );
}
