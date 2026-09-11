"use client";

import * as React from "react";
import Image from "next/image";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { getModelMetrics, type ModelMetrics } from "@/lib/api";

const MODEL_LABELS: Record<string, string> = {
  logistic_regression: "Logistic Regression",
  random_forest: "Random Forest",
  xgboost: "XGBoost",
};

const EVAL_IMAGES: { key: string; label: string; filename: string }[] = [
  { key: "roc", label: "ROC Curves (per class)", filename: "_roc_curve.png" },
  { key: "pr", label: "Precision-Recall Curves (per class)", filename: "_pr_curve.png" },
  { key: "confusion", label: "Confusion Matrix", filename: "_confusion_matrix.png" },
  { key: "calibration", label: "Calibration Curves", filename: "_calibration_curve.png" },
];

interface ModelDetailClientProps {
  modelSlug: string;
}

export function ModelDetailClient({ modelSlug }: ModelDetailClientProps) {
  const [metrics, setMetrics] = React.useState<ModelMetrics | null>(null);
  const [loading, setLoading] = React.useState(true);
  const [error, setError] = React.useState<string | null>(null);
  const [lightboxSrc, setLightboxSrc] = React.useState<string | null>(null);
  const [lightboxTitle, setLightboxTitle] = React.useState("");

  const modelName = MODEL_LABELS[modelSlug] || modelSlug;

  React.useEffect(() => {
    getModelMetrics(modelSlug)
      .then(setMetrics)
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false));
  }, [modelSlug]);

  if (loading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-10 w-64" />
        <Skeleton className="h-64 rounded-xl" />
        <div className="grid grid-cols-2 gap-4">
          {Array.from({ length: 4 }).map((_, i) => (
            <Skeleton key={i} className="h-64 rounded-xl" />
          ))}
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="space-y-6">
        <div className="rounded-lg bg-destructive/10 p-4 text-sm text-destructive">
          Failed to load metrics for {modelName}: {error}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold tracking-tight">{modelName}</h2>
        <p className="text-muted-foreground">Detailed performance metrics</p>
      </div>

      {/* Per-class metrics table */}
      {metrics && (
        <Card>
          <CardHeader>
            <CardTitle>Per-Class Metrics</CardTitle>
          </CardHeader>
          <CardContent>
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
                  {Object.entries(metrics.per_class).map(([cls, vals]) => (
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
                    <td className="py-2 px-3" colSpan={3}>{metrics.accuracy.toFixed(4)}</td>
                    <td className="py-2 px-3">
                      {Object.values(metrics.per_class).reduce((s, v) => s + v.support, 0)}
                    </td>
                  </tr>
                  <tr className="font-medium text-muted-foreground">
                    <td className="py-2 px-3">Macro Avg</td>
                    <td className="py-2 px-3">{metrics.macro_avg.precision.toFixed(4)}</td>
                    <td className="py-2 px-3">{metrics.macro_avg.recall.toFixed(4)}</td>
                    <td className="py-2 px-3">{metrics.macro_avg.f1_score.toFixed(4)}</td>
                    <td className="py-2 px-3">
                      {Object.values(metrics.per_class).reduce((s, v) => s + v.support, 0)}
                    </td>
                  </tr>
                  <tr className="font-medium text-muted-foreground">
                    <td className="py-2 px-3">Weighted Avg</td>
                    <td className="py-2 px-3">{metrics.weighted_avg.precision.toFixed(4)}</td>
                    <td className="py-2 px-3">{metrics.weighted_avg.recall.toFixed(4)}</td>
                    <td className="py-2 px-3">{metrics.weighted_avg.f1_score.toFixed(4)}</td>
                    <td className="py-2 px-3">
                      {Object.values(metrics.per_class).reduce((s, v) => s + v.support, 0)}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Evaluation images */}
      <div>
        <h3 className="text-lg font-semibold mb-4">Evaluation Plots</h3>
        <div className="grid gap-4 md:grid-cols-2">
          {EVAL_IMAGES.map((img) => {
            const src = `/evaluation/${modelSlug}${img.filename}`;
            return (
              <Card
                key={img.key}
                className="cursor-pointer hover:shadow-md transition-shadow"
                onClick={() => {
                  setLightboxSrc(src);
                  setLightboxTitle(img.label);
                }}
              >
                <CardHeader className="pb-3">
                  <CardTitle className="text-sm">{img.label}</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="relative w-full aspect-[4/3] bg-muted rounded-lg overflow-hidden">
                    <Image
                      src={src}
                      alt={img.label}
                      fill
                      className="object-contain"
                      sizes="(max-width: 768px) 100vw, 50vw"
                      onError={(e) => {
                        (e.target as HTMLImageElement).style.display = "none";
                      }}
                    />
                  </div>
                  <p className="text-xs text-muted-foreground mt-2 text-center">
                    Click to zoom
                  </p>
                </CardContent>
              </Card>
            );
          })}
        </div>
      </div>

      {/* Lightbox modal */}
      <Dialog open={!!lightboxSrc} onOpenChange={(open) => !open && setLightboxSrc(null)}>
        <DialogContent className="max-w-4xl">
          <DialogHeader>
            <DialogTitle>{lightboxTitle}</DialogTitle>
          </DialogHeader>
          {lightboxSrc && (
            <div className="relative w-full aspect-[4/3] bg-muted rounded-lg overflow-hidden">
              <Image
                src={lightboxSrc}
                alt={lightboxTitle}
                fill
                className="object-contain"
                sizes="100vw"
              />
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
