
class Task {
  int? id;

  String title;
  String subject;
  DateTime dueDate;
  bool isCompleted;

  /// ID of the task group this task belongs to.
  /// Null means the task has not been assigned to a group yet.
  int? groupId;

  /// Supported values: 'routine' and 'project'.
  String taskType;

  /// When this task was created.
  DateTime? createdAt;

  /// Supported values: 'low', 'medium', and 'high'.
  String priority;

  Task({
    this.id,
    required this.title,
    required this.subject,
    required this.dueDate,
    this.isCompleted = false,
    this.groupId,
    this.taskType = 'project',
    this.createdAt,
    this.priority = 'medium',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
      'groupId': groupId,
      'taskType': taskType,
      'createdAt': createdAt?.toIso8601String(),
      'priority': priority,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      title: map['title'] as String,
      subject: map['subject'] as String,
      dueDate: DateTime.parse(map['dueDate'] as String),
      isCompleted: (map['isCompleted'] as int) == 1,
      groupId: map['groupId'] as int?,
      taskType: map['taskType'] as String? ?? 'project',
      createdAt: map['createdAt'] == null
          ? null
          : DateTime.tryParse(map['createdAt'] as String),
      priority: map['priority'] as String? ?? 'medium',
    );
  }
}
