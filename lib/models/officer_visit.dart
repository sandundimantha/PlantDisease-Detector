// ─────────────────────────────────────────────────────────────────────────────
// OfficerVisit — a field visit planned by an officer or requested by a farmer
// (table: officer_visits, migration 015)
// ─────────────────────────────────────────────────────────────────────────────
class OfficerVisit {
  final String id;
  final String? officerId;
  final String? agriOfficerId; // officer the farmer picked on the map
  final String? farmerId;
  final String? consultationId;
  final String farmerName;
  final String? village;
  final String? reason;
  final DateTime? scheduledFor; // local time
  final String status; // requested | scheduled | completed | cancelled
  final DateTime createdAt;

  const OfficerVisit({
    required this.id,
    this.officerId,
    this.agriOfficerId,
    this.farmerId,
    this.consultationId,
    required this.farmerName,
    this.village,
    this.reason,
    this.scheduledFor,
    required this.status,
    required this.createdAt,
  });

  factory OfficerVisit.fromJson(Map<String, dynamic> json) {
    return OfficerVisit(
      id: json['id'] as String,
      officerId: json['officer_id'] as String?,
      agriOfficerId: json['agri_officer_id'] as String?,
      farmerId: json['farmer_id'] as String?,
      consultationId: json['consultation_id'] as String?,
      farmerName: json['farmer_name'] as String? ?? 'Farmer',
      village: json['village'] as String?,
      reason: json['reason'] as String?,
      scheduledFor: json['scheduled_for'] != null
          ? DateTime.parse(json['scheduled_for'] as String).toLocal()
          : null,
      status: json['status'] as String? ?? 'requested',
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  bool get isRequest => status == 'requested';
  bool get isScheduled => status == 'scheduled';
  bool get isCompleted => status == 'completed';
  bool get isOverdue =>
      isScheduled && scheduledFor != null && scheduledFor!.isBefore(DateTime.now());
}
