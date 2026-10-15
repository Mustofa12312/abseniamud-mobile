class AttendanceSummaryModel {
  final String period;
  final int hadir;
  final int terlambat;
  final int tidakHadir;
  final int izinSakit;
  final int belumCheckout;
  final int total;

  AttendanceSummaryModel({
    required this.period,
    required this.hadir,
    required this.terlambat,
    required this.tidakHadir,
    required this.izinSakit,
    required this.belumCheckout,
    required this.total,
  });

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value != null) return int.tryParse(value.toString()) ?? 0;
    return 0;
  }

  factory AttendanceSummaryModel.fromJson(Map<String, dynamic> json) {
    return AttendanceSummaryModel(
      period: json['period']?.toString() ?? '',
      hadir: _toInt(json['hadir']),
      terlambat: _toInt(json['terlambat']),
      tidakHadir: _toInt(json['tidak_hadir']),
      izinSakit: _toInt(json['izin_sakit']),
      belumCheckout: _toInt(json['belum_checkout']),
      total: _toInt(json['total']),
    );
  }

  factory AttendanceSummaryModel.empty() {
    return AttendanceSummaryModel(
      period: '-',
      hadir: 0,
      terlambat: 0,
      tidakHadir: 0,
      izinSakit: 0,
      belumCheckout: 0,
      total: 0,
    );
  }
}
