
class Incident {
  final int? id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final DateTime createdAt;

  const Incident({
    this.id,
    required this.title,
    this.description = '',
    this.status = 'open',
    this.priority = 'normal',
    required this.createdAt,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Incident.fromMap(Map<String, Object?> map) {
    return Incident(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      status: map['status'] as String? ?? 'open',
      priority: map['priority'] as String? ?? 'normal',
      createdAt: DateTime.parse(
        map['createdAt'] as String,
      ),
    );
  }
}