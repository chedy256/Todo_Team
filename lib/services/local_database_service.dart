import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/task_model.dart';
import '../models/user_model.dart';

class LocalDatabaseService {
  static Database? _db;
  static final LocalDatabaseService instance =
      LocalDatabaseService._constructor();

  final String _tasksTableName = 'tasks';
  final String _tasksIdColumn = 'id';
  final String _tasksTitleColumn = 'title';
  final String _tasksDescriptionColumn = 'description';
  final String _tasksPriorityColumn = 'priority';
  final String _tasksOwnerIdColumn = 'ownerId';
  final String _tasksAssignedToColumn = 'assignedTo';
  final String _tasksDueDateColumn = 'dueDate';
  final String _tasksCreatedAtColumn = 'createdAt';
  final String _tasksUpdatedAtColumn = 'updatedAt';
  final String _tasksIsCompletedColumn = 'isCompleted';

  LocalDatabaseService._constructor();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await getDatabase();
    return _db!;
  }

  Future<Database> getDatabase() async {
    final dbDirPath = await getDatabasesPath();
    final databasePath = join(dbDirPath, 'master_db.db');
    final database = await openDatabase(
      databasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tasksTableName (
            $_tasksIdColumn INTEGER PRIMARY KEY,
            $_tasksTitleColumn TEXT NOT NULL,
            $_tasksDescriptionColumn TEXT NOT NULL,
            $_tasksPriorityColumn INTEGER DEFAULT 0 NOT NULL,
            $_tasksOwnerIdColumn INTEGER NOT NULL,
            $_tasksAssignedToColumn INTEGER DEFAULT NULL,
            $_tasksIsCompletedColumn INTEGER DEFAULT 0 NOT NULL,
            $_tasksDueDateColumn INTEGER NOT NULL,
            $_tasksCreatedAtColumn INTEGER DEFAULT (strftime('%s','now')),
            $_tasksUpdatedAtColumn INTEGER NOT NULL
          )
        ''');
      },
    );
    return database;
  }

  void addTask(Task task) async {
    final db = await database;
    await db.insert(_tasksTableName, {
      _tasksTitleColumn: task.title,
      _tasksDescriptionColumn: task.description,
      _tasksPriorityColumn: task.priority.index,
      _tasksOwnerIdColumn: task.ownerId,
      _tasksAssignedToColumn: task.assigned?.id,
      _tasksIsCompletedColumn: task.isCompleted ? 1 : 0,
      _tasksDueDateColumn: task.dueDate.millisecondsSinceEpoch,
      _tasksCreatedAtColumn: task.createdAt.millisecondsSinceEpoch,
      _tasksUpdatedAtColumn: task.updatedAt.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
  void updateTask(Task task) async {
    final db = await database;
    await db.update(
      _tasksTableName,
      {
        _tasksTitleColumn: task.title,
        _tasksDescriptionColumn: task.description,
        _tasksPriorityColumn: task.priority.index,
        _tasksOwnerIdColumn: task.ownerId,
        _tasksAssignedToColumn: task.assigned?.id,
        _tasksIsCompletedColumn: task.isCompleted ? 1 : 0,
        _tasksDueDateColumn: task.dueDate.millisecondsSinceEpoch,
        _tasksUpdatedAtColumn: DateTime.now().millisecondsSinceEpoch,
      },
      where: '$_tasksIdColumn = ?',
      whereArgs: [task.id],
    );
  }
  void deleteTask(int id) async {
    final db = await database;
    await db.delete(
      _tasksTableName,
      where: '$_tasksIdColumn = ?',
      whereArgs: [id],
    );
  }

  Future<List<Task>?> getTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_tasksTableName);

    return List.generate(maps.length, (i) {
      return Task(
        id: maps[i][_tasksIdColumn],
        title: maps[i][_tasksTitleColumn],
        description: maps[i][_tasksDescriptionColumn],
        priority: Priority.values[maps[i][_tasksPriorityColumn]],
        dueDate: DateTime.fromMillisecondsSinceEpoch(
          maps[i][_tasksDueDateColumn] ?? DateTime.now().millisecondsSinceEpoch,
        ),
        ownerId: maps[i][_tasksOwnerIdColumn] ?? 0,
        assigned: maps[i][_tasksAssignedToColumn] != null
            ? User(id: maps[i][_tasksAssignedToColumn], name: '', email: '')
            : null,
        isCompleted: (maps[i][_tasksIsCompletedColumn] ?? 0) == 1,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          maps[i][_tasksUpdatedAtColumn] ??
              DateTime.now().millisecondsSinceEpoch,
        ),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          maps[i][_tasksCreatedAtColumn] ??
              DateTime.now().millisecondsSinceEpoch,
        ),
      );
    });
  }
}
