"use client";

import * as React from "react";
import {
  Building2,
  HeartPulse,
  AlertTriangle,
  Siren,
} from "lucide-react";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Cell,
} from "recharts";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { StatCard } from "@/components/stat-card";
import { type BankSummary } from "@/lib/api";

interface HistoryEntry {
  bank_id: string;
  scenario_id: number;
  model_used: string;
  predicted_condition: string;
  timestamp: string;
}

const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL || "http://localhost:8000";

export default function DashboardPage() {
  const [banks, setBanks] = React.useState<BankSummary[]>([]);
  const [history, setHistory] = React.useState<HistoryEntry[]>([]);
  const [loading, setLoading] = React.useState(true);

  React.useEffect(() => {
    async function loadData() {
      try {
        const res = await fetch(`${BACKEND_URL}/banks`);
        if (res.ok) setBanks(await res.json());
      } catch {
        // Backend may not be running
      }
      try {
        const stored = localStorage.getItem("simulation_history");
        if (stored) setHistory(JSON.parse(stored));
      } catch {
        // Ignore
      }
      setLoading(false);
    }
    loadData();
  }, []);

  const totalBanks = banks.length || 40;

  const totalHealthy = banks.length
    ? banks.reduce((sum, b) => sum + b.healthy_pct, 0) / banks.length
    : 51.45;
  const totalStressed = banks.length
    ? banks.reduce((sum, b) => sum + b.stressed_pct, 0) / banks.length
    : 32.78;
  const totalCritical = banks.length
    ? banks.reduce((sum, b) => sum + b.critical_pct, 0) / banks.length
    : 15.76;

  const chartData = [
    { name: "Healthy", value: Number(totalHealthy.toFixed(1)), fill: "hsl(142, 71%, 45%)" },
    { name: "Stressed", value: Number(totalStressed.toFixed(1)), fill: "hsl(38, 92%, 50%)" },
    { name: "Critical", value: Number(totalCritical.toFixed(1)), fill: "hsl(0, 84%, 60%)" },
  ];

  const recentHistory = history.slice(0, 10);

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
          {Array.from({ length: 4 }).map((_, i) => (
            <Skeleton key={i} className="h-32 rounded-xl" />
          ))}
        </div>
        <div className="grid gap-6 lg:grid-cols-2">
          <Skeleton className="h-80 rounded-xl" />
          <Skeleton className="h-80 rounded-xl" />
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold tracking-tight">Dashboard</h2>
        <p className="text-muted-foreground">Overview of bank stress testing portfolio</p>
      </div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <StatCard
          title="Total Banks"
          value={totalBanks}
          icon={Building2}
          iconColor="text-primary"
          iconBg="bg-primary/10"
        />
        <StatCard
          title="% Healthy"
          value={`${totalHealthy.toFixed(1)}%`}
          icon={HeartPulse}
          iconColor="text-healthy"
          iconBg="bg-healthy/10"
        />
        <StatCard
          title="% Stressed"
          value={`${totalStressed.toFixed(1)}%`}
          icon={AlertTriangle}
          iconColor="text-stressed"
          iconBg="bg-stressed/10"
        />
        <StatCard
          title="% Critical"
          value={`${totalCritical.toFixed(1)}%`}
          icon={Siren}
          iconColor="text-critical"
          iconBg="bg-critical/10"
        />
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Condition Distribution</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={280}>
              <BarChart data={chartData} margin={{ top: 20, right: 30, left: 20, bottom: 5 }}>
                <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
                <XAxis dataKey="name" className="text-xs" />
                <YAxis className="text-xs" />
                <Tooltip
                  contentStyle={{
                    backgroundColor: "hsl(var(--card))",
                    border: "1px solid hsl(var(--border))",
                    borderRadius: "0.5rem",
                  }}
                />
                <Bar dataKey="value" radius={[8, 8, 0, 0]}>
                  {chartData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.fill} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Recent Simulations</CardTitle>
          </CardHeader>
          <CardContent>
            {recentHistory.length === 0 ? (
              <div className="flex flex-col items-center justify-center h-64 text-muted-foreground">
                <p className="text-sm">No simulations yet</p>
                <p className="text-xs mt-1">Run a simulation to see results here</p>
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b">
                      <th className="text-left py-2 px-2 font-medium text-muted-foreground">Bank</th>
                      <th className="text-left py-2 px-2 font-medium text-muted-foreground">Scenario</th>
                      <th className="text-left py-2 px-2 font-medium text-muted-foreground">Model</th>
                      <th className="text-left py-2 px-2 font-medium text-muted-foreground">Result</th>
                    </tr>
                  </thead>
                  <tbody>
                    {recentHistory.map((entry, i) => (
                      <tr key={i} className="border-b last:border-0">
                        <td className="py-2 px-2">{entry.bank_id}</td>
                        <td className="py-2 px-2">{entry.scenario_id}</td>
                        <td className="py-2 px-2 text-xs">{entry.model_used}</td>
                        <td className="py-2 px-2">
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
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
