import '../../data/models/risk_score_model.dart';

class CalculateRiskScore {
  RiskScoreModel call({
    required String areaName,
    required int hour,
    required double crimeNorm,
    required double congestionNorm,
  }) {
    final riskScore = (crimeNorm + congestionNorm) / 2;
    final riskLevel = _toRiskLevel(riskScore);

    return RiskScoreModel(
      areaName: areaName,
      hour: hour,
      crimeNorm: crimeNorm,
      congestionNorm: congestionNorm,
      riskScore: riskScore,
      riskLevel: riskLevel,
    );
  }

  String _toRiskLevel(double score) {
    if (score < 0.33) return 'low';
    if (score < 0.66) return 'moderate';
    return 'high';
  }
}
