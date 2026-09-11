import { FileText, Download } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";

export default function ReportsPage() {
  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold tracking-tight">Reports</h2>
        <p className="text-muted-foreground">Generated analysis reports and exports</p>
      </div>

      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
        {[
          {
            title: "Model Comparison Report",
            description: "Side-by-side performance comparison of all three models",
            filename: "model_comparison.csv",
          },
          {
            title: "Logistic Regression Results",
            description: "Full prediction results and metrics for LR model",
            filename: "logistic_regression_predictions.csv",
          },
          {
            title: "Random Forest Results",
            description: "Full prediction results and metrics for RF model",
            filename: "random_forest_predictions.csv",
          },
          {
            title: "XGBoost Results",
            description: "Full prediction results and metrics for XGBoost model",
            filename: "xgboost_predictions.csv",
          },
          {
            title: "Investigation Output",
            description: "Detailed feature analysis and investigation results",
            filename: "investigation_output.xlsx",
          },
          {
            title: "Model Audit Report",
            description: "Comprehensive audit of the ML pipeline",
            filename: "model_audit_results.xlsx",
          },
        ].map((report) => (
          <Card key={report.filename}>
            <CardHeader className="pb-3">
              <CardTitle className="text-base flex items-center gap-2">
                <FileText className="h-4 w-4 text-primary" />
                {report.title}
              </CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-sm text-muted-foreground mb-4">{report.description}</p>
              <Button variant="outline" size="sm" className="w-full" asChild>
                <a href={`http://localhost:8000/reports/${report.filename}`} download>
                  <Download className="h-4 w-4 mr-2" />
                  Download
                </a>
              </Button>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
}
