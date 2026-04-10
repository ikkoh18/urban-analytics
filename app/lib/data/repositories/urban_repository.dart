import '../models/urban_data_model.dart';
import '../models/crime_model.dart';
import '../models/risk_score_model.dart';

abstract class UrbanRepository {
  Future<List<UrbanDataModel>> getUrbanData({DateTime? from, DateTime? to});
  Future<List<CrimeModel>> getCrimeData({DateTime? from, DateTime? to});
  Future<List<RiskScoreModel>> getRiskScores({required String areaName});
}
