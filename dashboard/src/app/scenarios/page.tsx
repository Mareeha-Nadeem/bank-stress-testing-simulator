"use client";

import * as React from "react";
import { Globe } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { getScenarios, type ScenarioSummary } from "@/lib/api";

export default function ScenariosPage() {
  const [scenarios, setScenarios] = React.useState<ScenarioSummary[]>([]);
  const [loading, setLoading] = React.useState(true);

  React.useEffect(() => {
    getScenarios()
      .then(setScenarios)
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-10 w-64" />
        <Skeleton className="h-96 rounded-xl" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold tracking-tight">Scenarios</h2>
        <p className="text-muted-foreground">{scenarios.length} macro-economic stress scenarios</p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Globe className="h-5 w-5 text-primary" />
            Scenario Overview
          </CardTitle>
        </CardHeader>
        <CardContent>
          {scenarios.length === 0 ? (
            <div className="flex flex-col items-center justify-center h-48 text-muted-foreground">
              <Globe className="h-10 w-10 mb-2 opacity-40" />
              <p className="text-sm">No scenario data available</p>
              <p className="text-xs mt-1">Ensure the backend is running</p>
            </div>
          ) : (
            <div className="overflow-x-auto max-h-[600px]">
              <table className="w-full text-sm">
                <thead className="sticky top-0 bg-background">
                  <tr className="border-b">
                    <th className="text-left py-2 px-3 font-medium text-muted-foreground">ID</th>
                    <th className="text-left py-2 px-3 font-medium text-muted-foreground">Banks</th>
                    <th className="text-left py-2 px-3 font-medium text-muted-foreground">Dominant</th>
                    <th className="text-left py-2 px-3 font-medium text-muted-foreground">Healthy</th>
                    <th className="text-left py-2 px-3 font-medium text-muted-foreground">Stressed</th>
                    <th className="text-left py-2 px-3 font-medium text-muted-foreground">Critical</th>
                  </tr>
                </thead>
                <tbody>
                  {scenarios.map((s) => (
                    <tr key={s.scenario_id} className="border-b last:border-0 hover:bg-muted/50">
                      <td className="py-2 px-3 font-mono text-xs">{s.scenario_id}</td>
                      <td className="py-2 px-3">{s.num_banks}</td>
                      <td className="py-2 px-3">
                        <Badge variant={s.dominant_condition === "Healthy" ? "healthy" : s.dominant_condition === "Stressed" ? "stressed" : "critical"}>
                          {s.dominant_condition}
                        </Badge>
                      </td>
                      <td className="py-2 px-3 text-xs">{s.healthy_pct.toFixed(1)}%</td>
                      <td className="py-2 px-3 text-xs">{s.stressed_pct.toFixed(1)}%</td>
                      <td className="py-2 px-3 text-xs">{s.critical_pct.toFixed(1)}%</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
