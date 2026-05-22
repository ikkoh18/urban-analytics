class WeatherCurrent {
  final int hour;
  final double temperature;   // °C
  final double precipitation; // mm

  const WeatherCurrent({
    required this.hour,
    required this.temperature,
    required this.precipitation,
  });

  factory WeatherCurrent.fromJson(Map<String, dynamic> json) => WeatherCurrent(
        hour:          json['hour'] as int,
        temperature:   (json['temperature'] as num).toDouble(),
        precipitation: (json['precipitation'] as num).toDouble(),
      );

  factory WeatherCurrent.fallback(int hour) =>
      WeatherCurrent(hour: hour, temperature: 20.0, precipitation: 0.0);
}
