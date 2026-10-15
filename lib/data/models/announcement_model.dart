class AnnouncementModel {
  final int id;
  final String title;
  final String content;
  final bool isImportant;
  final String createdAt;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    required this.isImportant,
    required this.createdAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      isImportant: json['is_important'] == true || json['is_important'] == 1,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
