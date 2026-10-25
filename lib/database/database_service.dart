
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/routine_completion.dart';
import '../models/task.dart';
import '../models/task_activity_log.dart';
import '../models/task_group.dart';

class DatabaseService {
  static Database? _database;

  static const String _databaseName = 'student_dashboard.db';
  static const int _databaseVersion = 4;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {

    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        subject TEXT NOT NULL,
        dueDate TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        groupId INTEGER,
        taskType TEXT NOT NULL DEFAULT 'project',
        createdAt TEXT,
        priority TEXT NOT NULL DEFAULT 'medium'
      )
    ''');

    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        teacherName TEXT NOT NULL,
        credits INTEGER NOT NULL
      )
    ''');

    await _createExtendedTables(db);
  }

  Future<void> _upgradeDatabase(
      Database db,
      int oldVersion,
      int newVersion,
      ) async {

    if (oldVersion < 4){
      await db.execute(
        "ALTER TABLE tasks "
            "ADD COLUMN priority TEXT NOT NULL DEFAULT 'medium'",
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        "ALTER TABLE task_groups "
            "ADD COLUMN description TEXT NOT NULL DEFAULT ''",
      );

      await db.execute(
        'ALTER TABLE task_groups ADD COLUMN deadline TEXT',
      );
    }

    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE tasks ADD COLUMN groupId INTEGER',
      );

      await db.execute('''
        ALTER TABLE tasks
        ADD COLUMN taskType TEXT NOT NULL DEFAULT 'project'
      ''');

      await db.execute(
        'ALTER TABLE tasks ADD COLUMN createdAt TEXT',
      );

      await _createExtendedTables(db);
    }
  }

  Future<void> _createExtendedTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS task_groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL CHECK (
          type IN ('routine', 'project')
        ),
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS routine_completions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        taskId INTEGER NOT NULL,
        completionDate TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 1,
        UNIQUE (taskId, completionDate)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS task_activity_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        taskId INTEGER NOT NULL,
        accomplished TEXT NOT NULL,
        nextSteps TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL DEFAULT 'inProgress',
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
        CREATE TABLE IF NOT EXISTS task_groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL CHECK (
          type IN ('routine', 'project')
        ),
        description TEXT NOT NULL DEFAULT '',
        deadline TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
  }
  // ---------------------------------------------------------------------------
  // TASKS
  // ---------------------------------------------------------------------------

  Future<int> insertTask(Task task) async {
    final db = await database;

    final taskToSave = Task(
        id: task.id,
        title: task.title,
        subject: task.subject,
        dueDate: task.dueDate,
        isCompleted: task.isCompleted,
        groupId: task.groupId,
        taskType: task.taskType,
        createdAt: task.createdAt ?? DateTime.now(),
        priority: task.priority
    );

    final id = await db.insert('tasks', taskToSave.toMap());
    task.id = id;
    task.createdAt ??= taskToSave.createdAt;

    return id;
  }

  Future<List<Task>> getTasks() async {
    final db = await database;
    final result = await db.query(
      'tasks',
      orderBy: 'dueDate ASC',
    );

    return result.map(Task.fromMap).toList();
  }

  Future<List<Task>> getTasksByGroup(int groupId) async {
    final db = await database;
    final result = await db.query(
      'tasks',
      where: 'groupId = ?',
      whereArgs: [groupId],
      orderBy: 'dueDate ASC',
    );

    return result.map(Task.fromMap).toList();
  }

  Future<int> updateTask(Task task) async {
    if (task.id == null) {
      return 0;
    }

    final db = await database;

    return db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await database;

    await db.delete(
      'routine_completions',
      where: 'taskId = ?',
      whereArgs: [id],
    );

    await db.delete(
      'task_activity_logs',
      where: 'taskId = ?',
      whereArgs: [id],
    );

    return db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------------------------------------------------------------------------
  // TASK GROUPS
  // ---------------------------------------------------------------------------

  Future<int> insertTaskGroup(TaskGroup group) async {
    if (group.type != 'routine' && group.type != 'project') {
      throw ArgumentError(
        "Group type must be either 'routine' or 'project'.",
      );
    }

    final db = await database;
    final id = await db.insert('task_groups', group.toMap());

    group.id = id;
    return id;
  }

  Future<List<TaskGroup>> getTaskGroups({String? type}) async {
    final db = await database;

    if (type != null && type != 'routine' && type != 'project') {
      throw ArgumentError(
        "Group type must be either 'routine' or 'project'.",
      );
    }

    final result = await db.query(
      'task_groups',
      where: type == null ? null : 'type = ?',
      whereArgs: type == null ? null : [type],
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return result.map(TaskGroup.fromMap).toList();
  }

  Future<int> updateTaskGroup(TaskGroup group) async {
    if (group.id == null) {
      return 0;
    }

    if (group.type != 'routine' && group.type != 'project') {
      throw ArgumentError(
        "Group type must be either 'routine' or 'project'.",
      );
    }

    final db = await database;

    return db.update(
      'task_groups',
      group.toMap(),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  /// Deletes a group and all tasks belonging to it, including their
  /// routine-completion history and progress-log entries, as one transaction.
  /// The UI must ask for confirmation before calling this method.
  Future<int> deleteTaskGroup(int groupId) async {
    final db = await database;

    return db.transaction<int>((txn) async {
      final taskRows = await txn.query(
        'tasks',
        columns: ['id'],
        where: 'groupId = ?',
        whereArgs: [groupId],
      );
      final taskIds = taskRows
          .map((row) => row['id'] as int)
          .toList(growable: false);

      for (final taskId in taskIds) {
        await txn.delete(
          'routine_completions',
          where: 'taskId = ?',
          whereArgs: [taskId],
        );
        await txn.delete(
          'task_activity_logs',
          where: 'taskId = ?',
          whereArgs: [taskId],
        );
      }

      await txn.delete(
        'tasks',
        where: 'groupId = ?',
        whereArgs: [groupId],
      );

      return txn.delete(
        'task_groups',
        where: 'id = ?',
        whereArgs: [groupId],
      );
    });
  }

  // ---------------------------------------------------------------------------
  // DAILY ROUTINE COMPLETIONS
  // ---------------------------------------------------------------------------

  /// Converts a date to a local-calendar key in YYYY-MM-DD format.
  String dateKey(DateTime date) {
    final localDate = DateTime(date.year, date.month, date.day);
    final year = localDate.year.toString().padLeft(4, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final day = localDate.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  Future<void> saveRoutineCompletion(
      RoutineCompletion completion,
      ) async {
    final db = await database;

    final values = completion.toMap()
      ..remove('id');

    await db.insert(
      'routine_completions',
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> setRoutineCompletion({
    required int taskId,
    required DateTime date,
    required bool isCompleted,
  }) async {
    await saveRoutineCompletion(
      RoutineCompletion(
        taskId: taskId,
        completionDate: dateKey(date),
        isCompleted: isCompleted,
      ),
    );
  }

  Future<List<RoutineCompletion>> getRoutineCompletionsForDate(
      DateTime date,
      ) async {
    final db = await database;

    final result = await db.query(
      'routine_completions',
      where: 'completionDate = ?',
      whereArgs: [dateKey(date)],
      orderBy: 'taskId ASC',
    );

    return result.map(RoutineCompletion.fromMap).toList();
  }

  Future<RoutineCompletion?> getRoutineCompletion({
    required int taskId,
    required DateTime date,
  }) async {
    final db = await database;

    final result = await db.query(
      'routine_completions',
      where: 'taskId = ? AND completionDate = ?',
      whereArgs: [taskId, dateKey(date)],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return RoutineCompletion.fromMap(result.first);
  }

  Future<List<RoutineCompletion>> getRoutineCompletionHistory({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database;

    final result = await db.query(
      'routine_completions',
      where: 'completionDate >= ? AND completionDate <= ?',
      whereArgs: [dateKey(startDate), dateKey(endDate)],
      orderBy: 'completionDate ASC, taskId ASC',
    );

    return result.map(RoutineCompletion.fromMap).toList();
  }

  // ---------------------------------------------------------------------------
  // PROJECT TASK ACTIVITY LOGS
  // ---------------------------------------------------------------------------

  Future<int> insertTaskActivityLog(TaskActivityLog log) async {
    final db = await database;

    final logToSave = TaskActivityLog(
      id: log.id,
      taskId: log.taskId,
      accomplished: log.accomplished,
      nextSteps: log.nextSteps,
      notes: log.notes,
      status: log.status,
      createdAt: log.createdAt,
    );

    final id = await db.insert('task_activity_logs', logToSave.toMap());
    log.id = id;

    return id;
  }

  Future<List<TaskActivityLog>> getTaskActivityLogs(int taskId) async {
    final db = await database;

    final result = await db.query(
      'task_activity_logs',
      where: 'taskId = ?',
      whereArgs: [taskId],
      orderBy: 'createdAt DESC, id DESC',
    );

    return result.map(TaskActivityLog.fromMap).toList();
  }

  Future<int> updateTaskActivityLog(TaskActivityLog log) async {
    if (log.id == null) {
      return 0;
    }

    final db = await database;

    return db.update(
      'task_activity_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  Future<int> deleteTaskActivityLog(int logId) async {
    final db = await database;

    return db.delete(
      'task_activity_logs',
      where: 'id = ?',
      whereArgs: [logId],
    );
  }

}
