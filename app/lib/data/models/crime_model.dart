class CrimeModel {
  final DateTime timestamp;
  final String crmCdDesc;
  final int? victAge;
  final String? victSex;
  final String? weaponUsedCd;
  final double lat;
  final double lon;
  final String areaName;

  const CrimeModel({
    required this.timestamp,
    required this.crmCdDesc,
    this.victAge,
    this.victSex,
    this.weaponUsedCd,
    required this.lat,
    required this.lon,
    required this.areaName,
  });
}
