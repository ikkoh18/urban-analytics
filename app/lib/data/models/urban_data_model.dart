class UrbanDataModel {
  final DateTime timestamp;
  final int crimeCount;
  final double trafficFlow;
  final double avgSpeed;
  final double temperature;
  final double precipitation;

  const UrbanDataModel({
    required this.timestamp,
    required this.crimeCount,
    required this.trafficFlow,
    required this.avgSpeed,
    required this.temperature,
    required this.precipitation,
  });
}
