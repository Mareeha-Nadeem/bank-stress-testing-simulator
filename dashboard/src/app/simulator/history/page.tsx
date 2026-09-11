"use client";

import * as React from "react";
import { History as HistoryIcon, Trash2 } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";

interface HistoryEntry {
  bank_id: string;
  scenario_id: number;
  model_used: string;
  predicted_condition: string;
  timestamp: string;
  probabilities?: {
    healthy: number;
    stressed: number;
    critical: number;
  };
}

export default function HistoryPage() {
  const [history, setHistory] = React.useState<HistoryEntry[]>([]);

  React.useEffect(() => {
    const stored = localStorage.getItem("simulation_history");
    if (stored) {
      try {
        setHistory(JSON.parse(stored));
      } catch {
        // Ignore
      }
    }
  }, []);

  const clearHistory = () => {
    localStorage.removeItem("simulation_history");
    setHistory([]);
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold tracking-tight">Simulation History</h2>
          <p className="text-muted-foreground">
            Past prediction runs stored locally ({history.length} entries)
          </p>
        </div>
        {history.length > 0 && (
          <Button variant="outline" size="sm" onClick={clearHistory}>
            <Trash2 className="h-4 w-4 mr-2" />
            Clear
          </Button>
        )}
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <HistoryIcon className="h-5 w-5 text-primary" />
            All Simulations
          </CardTitle>
        </CardHeader>
        <CardContent>
          {history.length === 0 ? (
            <div className="flex flex-col items-center justify-center h-48 text-muted-foreground">
              <HistoryIcon className="h-10 w-10 mb-2 opacity-40" />
              <p className="text-sm">No simulations recorded yet</p>
              <p className="text-xs mt-1">Run a new simulation to get started</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b">
                    <th className="text-left py-2 px-3 font-medium text-muted-foreground">#</th>
                    <th className="text-left py-2 px-3 font-medium text-muted-foreground">Bank ID</th>
                    <th className="text-left py-2 px-3 font-medium text-muted-foreground">Scenario</th>
                    <th className="text-left py-2 px-3 font-medium text-muted-foreground">Model</th>
                    <th className="text-left py-2 px-3 font-medium text-muted-foreground">Prediction</th>
                    <th className="text-left py-2 px-3 font-medium text-muted-foreground">P(Healthy)</th>
                    <th className="text-left py-2 px-3 font-medium text-muted-foreground">P(Stressed)</th>
                    <th className="text-left py-2 px-3 font-medium text-muted-foreground">P(Critical)</th>
                    <th className="text-left py-2 px-3 font-medium text-muted-foreground">Time</th>
                  </tr>
                </thead>
                <tbody>
                  {history.map((entry, i) => (
                    <tr key={i} className="border-b last:border-0 hover:bg-muted/50">
                      <td className="py-2 px-3 text-muted-foreground">{i + 1}</td>
                      <td className="py-2 px-3 font-mono text-xs">{entry.bank_id}</td>
                      <td className="py-2 px-3">{entry.scenario_id}</td>
                      <td className="py-2 px-3 text-xs">{entry.model_used}</td>
                      <td className="py-2 px-3">
                        <Badge
                          variant={
                            entry.predicted_condition === "Healthy"
                              ? "healthy"
                              : entry.predicted_condition === "Stressed"
                              ? "stressed"
                              : "critical"
                          }
                        >
                          {entry.predicted_condition}
                        </Badge>
                      </td>
                      <td className="py-2 px-3 text-xs">
                        {entry.probabilities
                          ? `${(entry.probabilities.healthy * 100).toFixed(1)}%`
                          : "—"}
                      </td>
                      <td className="py-2 px-3 text-xs">
                        {entry.probabilities
                          ? `${(entry.probabilities.stressed * 100).toFixed(1)}%`
                          : "—"}
                      </td>
                      <td className="py-2 px-3 text-xs">
                        {entry.probabilities
                          ? `${(entry.probabilities.critical * 100).toFixed(1)}%`
                          : "—"}
                      </td>
                      <td className="py-2 px-3 text-xs text-muted-foreground">
                        {new Date(entry.timestamp).toLocaleString()}
                      </td>
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
