
class Device {
  final int? id;
  final String name;
  final String address;
  final String notes;
  final bool authorized;
  final DateTime createdAt;

  const Device({
    this.id,
    required this.name,
    required this.address,
    this.notes = '',
    this.authorized = false,
    required this.createdAt,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'notes': notes,
      'authorized': authorized ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Device.fromMap(Map<String, Object?> map) {
    return Device(
      id: map['id'] as int?,
      name: map['name'] as String,
      address: map['address'] as String,
      notes: map['notes'] as String? ?? '',
      authorized: (map['authorized'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(
        map['createdAt'] as String,
      ),
    );
  }

  Device copyWith({
    int? id,
    String? name,
    String? address,
    String? notes,
    bool? authorized,
    DateTime? createdAt,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      authorized: authorized ?? this.authorized,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}