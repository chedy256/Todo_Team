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

  final String _usersTableName = 'users';
  final String _usersIdColumn = 'id';
  final String _usersNameColumn = 'name';
  final String _usersEmailColumn = 'email';

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
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_usersTableName (
            $_usersIdColumn INTEGER PRIMARY KEY AUTOINCREMENT,
            $_usersNameColumn TEXT NOT NULL,
            $_usersEmailColumn TEXT NOT NULL UNIQUE
          )
        ''');

        await db.execute('''
          CREATE TABLE $_tasksTableName (
            $_tasksIdColumn INTEGER PRIMARY KEY AUTOINCREMENT,
            $_tasksTitleColumn TEXT NOT NULL,
            $_tasksDescriptionColumn TEXT NOT NULL,
            $_tasksPriorityColumn INTEGER DEFAULT 0 NOT NULL,
            $_tasksOwnerIdColumn INTEGER NOT NULL,
            $_tasksAssignedToColumn INTEGER DEFAULT NULL,
            $_tasksIsCompletedColumn INTEGER DEFAULT 0 NOT NULL,
            $_tasksDueDateColumn INTEGER NOT NULL,
            $_tasksCreatedAtColumn INTEGER DEFAULT (strftime('%s','now')),
            $_tasksUpdatedAtColumn INTEGER NOT NULL,
            FOREIGN KEY ($_tasksAssignedToColumn) REFERENCES $_usersTableName ($_usersIdColumn)
          )
        ''');

        await _insertDefaultUsers(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE $_usersTableName (
              $_usersIdColumn INTEGER PRIMARY KEY AUTOINCREMENT,
              $_usersNameColumn TEXT NOT NULL,
              $_usersEmailColumn TEXT NOT NULL UNIQUE
            )
          ''');
          
          await _insertDefaultUsers(db);
        }
      },
    );
    return database;
  }

  Future<void> _insertDefaultUsers(Database db) async {
    final defaultUsers = [
      {'name': 'Bilel', 'email': 'bilel@email.com'},
      {'name': 'Yacine', 'email': 'yacine@email.com'},
      {'name': 'Mohamed', 'email': 'mohamed@email.com'},
      {'name': 'Samira', 'email': 'samira@email.com'},
      {'name': 'Marwa', 'email': 'marwa@email.com'},
      {'name': 'Ferdaous', 'email': 'ferdous@email.com'},
      {'name': 'Samir', 'email': 'samir@email.com'},
      {'name': 'admin', 'email': 'admin@email.com'},
    ];

    for (final user in defaultUsers) {
      await db.insert(_usersTableName, user);
    }
  }

  Future<int> addTask(Task task) async {
    final db = await database;
    final id = await db.insert(_tasksTableName, {
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
        _tasksAssignedToColumn: task.assigned?.id,
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

  Future<List<Task>> getTasks() async {
    final db = await database;
    
    if (_userCache == null) {
      await refreshUserCache();
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      _tasksTableName,
      orderBy: '$_tasksCreatedAtColumn DESC',
    );

    return List.generate(maps.length, (i) {
      User? assignedUser;
      if (maps[i]['assignedTo'] != null) {
        assignedUser = _getUserFromCacheById(maps[i]['assignedTo']);

        assignedUser ??= User(
          id: maps[i]['assignedTo'],
          name: 'Unknown User',
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
        assigned: assignedUser,
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
        name: maps[i]['name'],
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
        name: maps[0]['name'],
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
}
