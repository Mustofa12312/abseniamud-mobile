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

  factory AttendanceSummaryModel.fromJson(Map<String, dynamic> json) {
    return AttendanceSummaryModel(
      period: json['period'] ?? '',
      hadir: json['hadir'] ?? 0,
      terlambat: json['terlambat'] ?? 0,
      tidakHadir: json['tidak_hadir'] ?? 0,
      izinSakit: json['izin_sakit'] ?? 0,
      belumCheckout: json['belum_checkout'] ?? 0,
      total: json['total'] ?? 0,
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
