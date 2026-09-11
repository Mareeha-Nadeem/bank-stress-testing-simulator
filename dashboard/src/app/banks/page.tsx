"use client";

import * as React from "react";
import Link from "next/link";
import { Building2 } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { getBanks, type BankSummary } from "@/lib/api";

export default function BanksPage() {
  const [banks, setBanks] = React.useState<BankSummary[]>([]);
  const [loading, setLoading] = React.useState(true);

  React.useEffect(() => {
    getBanks()
      .then(setBanks)
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
        <h2 className="text-2xl font-bold tracking-tight">Banks</h2>
        <p className="text-muted-foreground">{banks.length} banks in the stress testing portfolio</p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Building2 className="h-5 w-5 text-primary" />
            All Banks
          </CardTitle>
        </CardHeader>
        <CardContent>
          {banks.length === 0 ? (
            <div className="flex flex-col items-center justify-center h-48 text-muted-foreground">
              <Building2 className="h-10 w-10 mb-2 opacity-40" />
              <p className="text-sm">No bank data available</p>
              <p className="text-xs mt-1">Ensure the backend is running</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b">
                    <th className="text-left py-2 px-3 font-medium text-muted-foreground">Bank ID</th>
                    <th className="text-left py-2 px-3 font-medium text-muted-foreground">Simulations</th>
                    <th className="text-left py-2 px-3 font-medium text-muted-foreground">Healthy</th>
                    <th className="text-left py-2 px-3 font-medium text-muted-foreground">Stressed</th>
                    <th className="text-left py-2 px-3 font-medium text-muted-foreground">Critical</th>
                    <th className="text-left py-2 px-3 font-medium text-muted-foreground">Details</th>
                  </tr>
                </thead>
                <tbody>
                  {banks.map((bank) => (
                    <tr key={bank.bank_id} className="border-b last:border-0 hover:bg-muted/50">
                      <td className="py-2 px-3 font-mono text-xs">{bank.bank_id}</td>
                      <td className="py-2 px-3">{bank.total_simulations}</td>
                      <td className="py-2 px-3">
                        <Badge variant="healthy">{bank.healthy_pct.toFixed(1)}%</Badge>
                      </td>
                      <td className="py-2 px-3">
                        <Badge variant="stressed">{bank.stressed_pct.toFixed(1)}%</Badge>
                      </td>
                      <td className="py-2 px-3">
                        <Badge variant="critical">{bank.critical_pct.toFixed(1)}%</Badge>
                      </td>
                      <td className="py-2 px-3">
                        <Link
                          href={`/banks/${encodeURIComponent(bank.bank_id)}`}
                          className="text-primary hover:underline text-xs"
                        >
                          View
                        </Link>
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
