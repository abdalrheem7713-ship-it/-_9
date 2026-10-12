
class Job {
  final int? id;
  final String title;
  final String description;
  final String status;
  final DateTime createdAt;

  const Job({
    this.id,
    required this.title,
    this.description = '',
    this.status = 'pending',
    required this.createdAt,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Job.fromMap(Map<String, Object?> map) {
    return Job(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(
        map['createdAt'] as String,
      ),
    );
  }
}