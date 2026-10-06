// A scan result the farmer bookmarked, stored in the `saved_items` table.
class SavedItem {
  final String id;
  final String? scanId;
  final String title;
  final String subtitle;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SavedItem({
    required this.id,
    required this.scanId,
    required this.title,
    required this.subtitle,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SavedItem.fromJson(Map<String, dynamic> json) {
    return SavedItem(
      id: json['id'].toString(),
      scanId: json['scan_id']?.toString(),
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      note: json['note'] ?? '',
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      updatedAt: DateTime.parse(json['updated_at']).toLocal(),
    );
  }

  // Columns sent back when an item is restored after an undo.
  Map<String, dynamic> toRestoreJson() {
    return {
      'id': id,
      'scan_id': scanId,
      'title': title,
      'subtitle': subtitle,
      'note': note.isEmpty ? null : note,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}
