class RiskScoreModel {
  final String areaName;
  final int hour;
  final double crimeNorm;
  final double congestionNorm;
  final double riskScore;  // (crimeNorm + congestionNorm) / 2
  final String riskLevel;  // 'low', 'moderate', 'high'

  const RiskScoreModel({
    required this.areaName,
    required this.hour,
    required this.crimeNorm,
    required this.congestionNorm,
    required this.riskScore,
    required this.riskLevel,
  });
}
