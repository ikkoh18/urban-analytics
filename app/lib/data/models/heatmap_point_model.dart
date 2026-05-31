import 'package:latlong2/latlong.dart';

class HeatmapPoint {
  const HeatmapPoint(this.latLng, this.intensity);
  final LatLng latLng;
  final double intensity;
}
