
class TaskActivityLog {
  int? id;
  int taskId;

  String accomplished;
  String nextSteps;
  String notes;

  /// Supported values: 'notStarted', 'inProgress', 'completed'.
  String status;

  DateTime createdAt;

  TaskActivityLog({
    this.id,
    required this.taskId,
    required this.accomplished,
    this.nextSteps = '',
    this.notes = '',
    this.status = 'inProgress',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'accomplished': accomplished,
      'nextSteps': nextSteps,
      'notes': notes,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TaskActivityLog.fromMap(Map<String, dynamic> map) {
    return TaskActivityLog(
      id: map['id'] as int?,
      taskId: map['taskId'] as int,
      accomplished: map['accomplished'] as String,
      nextSteps: map['nextSteps'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      status: map['status'] as String? ?? 'inProgress',
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
