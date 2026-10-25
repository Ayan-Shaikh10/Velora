class TaskGroup {
  int? id;
  String name;
  String type;
  String description;
  DateTime? deadline;
  DateTime createdAt;

  TaskGroup({
    this.id,
    required this.name,
    required this.type,
    this.description = '',
    this.deadline,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isRoutine => type == 'routine';
  bool get isProject => type == 'project';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'description': description,
      'deadline': deadline?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TaskGroup.fromMap(Map<String, dynamic> map) {
    return TaskGroup(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      description: (map['description'] as String?) ?? '',
      deadline: map['deadline'] == null
          ? null
          : DateTime.tryParse(map['deadline'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
