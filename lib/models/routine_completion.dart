
class RoutineCompletion {
  int? id;
  int taskId;

  /// Local calendar date formatted as YYYY-MM-DD.
  String completionDate;

  bool isCompleted;

  RoutineCompletion({
    this.id,
    required this.taskId,
    required this.completionDate,
    this.isCompleted = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'completionDate': completionDate,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory RoutineCompletion.fromMap(Map<String, dynamic> map) {
    return RoutineCompletion(
      id: map['id'] as int?,
      taskId: map['taskId'] as int,
      completionDate: map['completionDate'] as String,
      isCompleted: (map['isCompleted'] as int) == 1,
    );
  }
}
