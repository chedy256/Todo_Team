import 'dart:convert';
import 'package:project/services/notif_service.dart';
import 'package:project/services/online_service.dart';
import 'package:project/services/local_database_service.dart';
import 'package:project/services/connectivity_service.dart';
import 'package:project/models/task_model.dart';

class ReconnexionService {
  static final ReconnexionService instance = ReconnexionService._constructor();
  ReconnexionService._constructor();

  /// Syncs all pending changes when connectivity is restored
  Future<void> syncPendingChangesOnReconnect() async {
    final isOnline = await ConnectivityService.instance.isOnline();
    if (!isOnline) return;

    final db = await LocalDatabaseService.instance.database;
    final pendingChanges = await db.query(
      LocalDatabaseService.instance.pendingChangesTableName,
      where: '${LocalDatabaseService.instance.pendingChangesSyncedColumn} = ?',
      whereArgs: [0],
    );

    for (final change in pendingChanges) {
      final taskId =
          change[LocalDatabaseService.instance.pendingChangesTaskIdColumn]
              as int?;
      final changeType =
          change[LocalDatabaseService.instance.pendingChangesChangeTypeColumn]
              as String?;
      final afterChange =
          change[LocalDatabaseService.instance.pendingChangesAfterChangeColumn]
              as String?;
      final changeId =
          change[LocalDatabaseService.instance.pendingChangesIdColumn] as int?;

      if (taskId == null ||
          changeType == null ||
          afterChange == null ||
          changeId == null) {
        continue;
      }

      // Get the latest task info
      final taskList = await db.query(
        LocalDatabaseService.instance.tasksTableName,
        where: '${LocalDatabaseService.instance.tasksIdColumn} = ?',
        whereArgs: [taskId],
      );
      if (taskList.isEmpty) continue;
      final task = Task.fromApiJson(taskList.first);
      if (task.isCompleted) {
        NotifService().showNotification(
          id: taskId,
          title: task.title,
          body:
              "La tâche n'est pas modifiée car elle est marquée comme terminée.",
        );
        continue;
      }

      bool success = false;
      try {
        if (changeType == 'update') {
          final updatedTask = Task.fromApiJson(
            jsonDecode(afterChange) as Map<String, dynamic>,
          );
          final result = await ApiService.updateTask(updatedTask);
          success = result.isSuccess;
        } else if (changeType == 'create') {
          final newTask = Task.fromApiJson(
            jsonDecode(afterChange) as Map<String, dynamic>,
          );
          final result = await ApiService.createTask(newTask);
          success = result.isSuccess;
        } else if (changeType == 'delete') {
          final result = await ApiService.deleteTask(taskId);
          success = result.isSuccess;
        }
      } catch (e) {
        success = false;
      }

      // Mark as synced if successful
      if (success) {
        await db.update(
          LocalDatabaseService.instance.pendingChangesTableName,
          {LocalDatabaseService.instance.pendingChangesSyncedColumn: 1},
          where: '${LocalDatabaseService.instance.pendingChangesIdColumn} = ?',
          whereArgs: [changeId],
        );
        await db.update(
          LocalDatabaseService.instance.tasksTableName,
          {LocalDatabaseService.instance.tasksIsPendingColumn: 0},
          where: '${LocalDatabaseService.instance.tasksIdColumn} = ?',
          whereArgs: [taskId],
        );
      }
    }
  }
}
