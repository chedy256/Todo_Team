import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/task_filter.dart';
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

  final String _usersTableName = 'users';
  final String _usersIdColumn = 'id';
  final String _usersNameColumn = 'name';
  final String _usersEmailColumn = 'email';

  final String _pendingChangesTableName = 'pending_changes';
  final String _pendingChangesIdColumn = 'id';
  final String _pendingChangesTaskIdColumn = 'task_id';
  final String _pendingChangesChangeTypeColumn = 'change_type';
  final String _pendingChangesBeforeChangeColumn = 'before_change';
  final String _pendingChangesAfterChangeColumn = 'after_change';
  final String _pendingChangesTimestampColumn = 'timestamp';
  final String _pendingChangesSyncedColumn = 'synced';

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
        // Create users table first
        await db.execute('''
          CREATE TABLE $_usersTableName (
            $_usersIdColumn INTEGER PRIMARY KEY,
            $_usersNameColumn TEXT NOT NULL,
            $_usersEmailColumn TEXT NOT NULL UNIQUE
          )
        ''');

        // Create tasks table
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
            $_tasksCreatedAtColumn INTEGER DEFAULT (trimester('%s','now')),
            $_tasksUpdatedAtColumn INTEGER NOT NULL,
            FOREIGN KEY ($_tasksAssignedToColumn) REFERENCES $_usersTableName ($_usersIdColumn)
          )
        ''');

        // Create pending_changes table
        await db.execute('''
          CREATE TABLE $_pendingChangesTableName (
            $_pendingChangesIdColumn INTEGER PRIMARY KEY AUTOINCREMENT,
            $_pendingChangesTaskIdColumn INTEGER,
            $_pendingChangesChangeTypeColumn TEXT,
            $_pendingChangesBeforeChangeColumn TEXT,
            $_pendingChangesAfterChangeColumn TEXT,
            $_pendingChangesTimestampColumn INTEGER,
            $_pendingChangesSyncedColumn INTEGER DEFAULT 0
          )
        ''');

        // Create trigger to auto-remove synced pending changes
        await db.execute('''
          CREATE TRIGGER delete_synced_pending_changes
          AFTER UPDATE OF $_pendingChangesSyncedColumn ON $_pendingChangesTableName
          WHEN NEW.$_pendingChangesSyncedColumn = 1
          BEGIN
            DELETE FROM $_pendingChangesTableName WHERE $_pendingChangesIdColumn = NEW.$_pendingChangesIdColumn;
          END
        ''');
      },
    );
    return database;
  }

  Future<int> addTask(Task task) async {
    final db = await database;
    final id = await db.insert(_tasksTableName, {
      _tasksTitleColumn: task.title,
      _tasksDescriptionColumn: task.description,
      _tasksPriorityColumn: task.priority.index,
      _tasksOwnerIdColumn: task.ownerId,
      _tasksAssignedToColumn: task.assignedId?.id,
      _tasksIsCompletedColumn: task.isCompleted ? 1 : 0,
      _tasksDueDateColumn: task.dueDate.millisecondsSinceEpoch,
      _tasksCreatedAtColumn: task.createdAt.millisecondsSinceEpoch,
      _tasksUpdatedAtColumn: task.updatedAt.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    return id;
  }

  Future<void> updateTask(Task task) async {
    final db = await database;
    await db.update(
      _tasksTableName,
      {
        _tasksTitleColumn: task.title,
        _tasksDescriptionColumn: task.description,
        _tasksPriorityColumn: task.priority.index,
        _tasksOwnerIdColumn: task.ownerId,
        _tasksAssignedToColumn: task.assignedId?.id,
        _tasksIsCompletedColumn: task.isCompleted ? 1 : 0,
        _tasksDueDateColumn: task.dueDate.millisecondsSinceEpoch,
        _tasksUpdatedAtColumn: DateTime.now().millisecondsSinceEpoch,
      },
      where: '$_tasksIdColumn = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(int id) async {
    final db = await database;
    await db.delete(
      _tasksTableName,
      where: '$_tasksIdColumn = ?',
      whereArgs: [id],
    );
  }

  Future<List<Task>> getTasks({
    TaskStatus? status,
    SortType sortType = SortType.dueDate,
  }) async {
    final db = await database;

    if (_userCache == null) {
      await refreshUserCache();
    }

    String? whereClause;
    List<dynamic> whereArgs = [];

    if (status != null && status != TaskStatus.all) {
      switch (status) {
        case TaskStatus.pending:
          whereClause =
              '$_tasksIsCompletedColumn = ? AND $_tasksAssignedToColumn IS NULL';
          whereArgs = [0];
          break;
        case TaskStatus.inProgress:
          whereClause =
              '$_tasksIsCompletedColumn = ? AND $_tasksAssignedToColumn IS NOT NULL';
          whereArgs = [0];
          break;
        case TaskStatus.completed:
          whereClause = '$_tasksIsCompletedColumn = ?';
          whereArgs = [1];
          break;
        case TaskStatus.all:
          // No filter needed
          break;
      }
    }

    String orderByClause = _buildOrderByClause(sortType);

    final List<Map<String, dynamic>> maps = await db.query(
      _tasksTableName,
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: orderByClause,
    );

    return _mapToTaskList(maps);
  }

  String _buildOrderByClause(SortType sortType) {
    String column;
    switch (sortType) {
      case SortType.createdDate:
        column = _tasksCreatedAtColumn;
        break;
      case SortType.dueDate:
        column = _tasksDueDateColumn;
        break;
      case SortType.priority:
        column = _tasksPriorityColumn;
        break;
    }
    String order = 'DESC';

    return '$column $order';
  }

  List<Task> _mapToTaskList(List<Map<String, dynamic>> maps) {
    return List.generate(maps.length, (i) {
      User? assignedUser;
      if (maps[i]['assignedTo'] != null) {
        assignedUser =
            _getUserFromCacheById(maps[i]['assignedTo']) ??
            User(
              id: maps[i]['assignedTo'],
              username: 'Unknown User',
              email: 'unknown@email.com',
            );
      }

      return Task(
        id: maps[i]['id'],
        title: maps[i]['title'],
        description: maps[i]['description'],
        priority: Priority.values[maps[i]['priority']],
        dueDate: DateTime.fromMillisecondsSinceEpoch(maps[i]['dueDate']),
        ownerId: maps[i]['ownerId'],
        assignedId: assignedUser,
        isCompleted: (maps[i]['isCompleted'] ?? 0) == 1,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(maps[i]['updatedAt']),
        createdAt: DateTime.fromMillisecondsSinceEpoch(maps[i]['createdAt']),
      );
    });
  }

  Future<List<User>> getUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _usersTableName,
      orderBy: '$_usersNameColumn ASC',
    );

    return List.generate(maps.length, (i) {
      return User(
        id: maps[i]['id'],
        username: maps[i]['name'],
        email: maps[i]['email'],
      );
    });
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _usersTableName,
      where: '$_usersIdColumn = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return User(
        id: maps[0]['id'],
        username: maps[0]['name'],
        email: maps[0]['email'],
      );
    }
    return null;
  }

  static List<User>? _userCache;

  User? _getUserFromCacheById(int id) {
    if (_userCache != null) {
      try {
        return _userCache!.firstWhere((user) => user.id == id);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> refreshUserCache() async {
    _userCache = await getUsers();
  }

  // Add methods for user synchronization with API
  Future<void> syncUsersFromApi(List<User> apiUsers) async {
    final db = await database;

    // Clear existing users (except default ones if needed)
    await db.delete(_usersTableName);

    // Insert users from API
    for (final user in apiUsers) {
      await db.insert(
        _usersTableName,
        {
          _usersIdColumn: user.id,
          _usersNameColumn: user.username,
          _usersEmailColumn: user.email,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // Refresh the cache after sync
    await refreshUserCache();
  }

  Future<void> addOrUpdateUser(User user) async {
    final db = await database;
    await db.insert(
      _usersTableName,
      {
        _usersIdColumn: user.id,
        _usersNameColumn: user.username,
        _usersEmailColumn: user.email,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Refresh the cache after adding/updating
    await refreshUserCache();
  }

  Future<bool> hasUsers() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_usersTableName');
    final count = result.first['count'] as int;
    return count > 0;
  }
}
