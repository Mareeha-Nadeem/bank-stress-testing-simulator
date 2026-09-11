"use client";

import * as React from "react";
import { useParams } from "next/navigation";
import Link from "next/link";
import { ArrowLeft, Building2 } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { getBankDetail, type BankDetail } from "@/lib/api";

export default function BankDetailPage() {
  const params = useParams();
  const bankId = decodeURIComponent(params.id as string);
  const [bank, setBank] = React.useState<BankDetail | null>(null);
  const [loading, setLoading] = React.useState(true);

  React.useEffect(() => {
    getBankDetail(bankId)
      .then(setBank)
      .catch(() => {})
      .finally(() => setLoading(false));
  }, [bankId]);

  if (loading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-10 w-64" />
        <Skeleton className="h-64 rounded-xl" />
      </div>
    );
  }

  if (!bank) {
    return (
      <div className="space-y-6">
        <div className="rounded-lg bg-destructive/10 p-4 text-sm text-destructive">
          Bank not found: {bankId}
        </div>
        <Link href="/banks">
          <Button variant="outline">
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back to Banks
          </Button>
        </Link>
      </div>
    );
  }

  const profileEntries = Object.entries(bank.profile || {});

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Link href="/banks">
          <Button variant="ghost" size="icon">
            <ArrowLeft className="h-5 w-5" />
          </Button>
        </Link>
        <div>
          <h2 className="text-2xl font-bold tracking-tight">{bankId}</h2>
          <p className="text-muted-foreground">Bank profile and simulations</p>
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Building2 className="h-5 w-5 text-primary" />
            Profile
          </CardTitle>
        </CardHeader>
        <CardContent>
          {profileEntries.length === 0 ? (
            <p className="text-sm text-muted-foreground">No profile data available</p>
          ) : (
            <div className="grid gap-3 md:grid-cols-2 lg:grid-cols-3">
              {profileEntries.map(([key, val]) => (
                <div key={key} className="space-y-1">
                  <p className="text-xs text-muted-foreground">{key}</p>
                  <p className="text-sm font-medium">
                    {typeof val === "number" ? Number(val).toFixed(4) : String(val)}
                  </p>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Simulations ({bank.simulations?.length || 0})</CardTitle>
        </CardHeader>
        <CardContent>
          {!bank.simulations || bank.simulations.length === 0 ? (
            <p className="text-sm text-muted-foreground">No simulation records</p>
          ) : (
            <div className="overflow-x-auto max-h-96">
              <table className="w-full text-sm">
                <thead className="sticky top-0 bg-background">
                  <tr className="border-b">
                    {Object.keys(bank.simulations[0]).map((col) => (
                      <th key={col} className="text-left py-2 px-3 font-medium text-muted-foreground">{col}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {bank.simulations.slice(0, 50).map((sim, i) => (
                    <tr key={i} className="border-b last:border-0 hover:bg-muted/50">
                      {Object.values(sim).map((val, j) => (
                        <td key={j} className="py-2 px-3">
                          {typeof val === "string" && ["Healthy", "Stressed", "Critical"].includes(val) ? (
                            <Badge variant={val === "Healthy" ? "healthy" : val === "Stressed" ? "stressed" : "critical"}>
                              {val}
                            </Badge>
                          ) : typeof val === "number" ? (
                            Number(val).toFixed(4)
                          ) : (
                            String(val)
                          )}
                        </td>
                      ))}
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
