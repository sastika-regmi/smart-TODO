import '../../core/errors/failures.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_remote_data_source.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  const TaskRepositoryImpl(this._dataSource);

  final TaskRemoteDataSource _dataSource;

  @override
  Future<Result<List<Task>>> getTasks(String userId) {
    return _guard(
      () async {
        final models = await _dataSource.getTasks(userId);
        return models.map((m) => m.toEntity()).toList();
      },
      'load your tasks',
    );
  }

  @override
  Stream<List<Task>> watchTasks(String userId) {
    return _dataSource.watchTasks(userId).map(
          (models) => models.map((m) => m.toEntity()).toList(),
        );
  }

  @override
  Future<Result<Task>> getTask(String taskId) {
    return _guard(
      () async => (await _dataSource.getTask(taskId)).toEntity(),
      'load that task',
    );
  }

  @override
  Future<Result<Task>> createTask(Task task) {
    return _guard(
      () async => (await _dataSource.createTask(TaskModel.fromEntity(task))).toEntity(),
      'create that task',
    );
  }

  @override
  Future<Result<Task>> updateTask(Task task) {
    return _guard(
      () async => (await _dataSource.updateTask(TaskModel.fromEntity(task))).toEntity(),
      'update that task',
    );
  }

  @override
  Future<Result<void>> deleteTask(String taskId) {
    return _guard<void>(
      () => _dataSource.deleteTask(taskId),
      'delete that task',
    );
  }

  @override
  Future<Result<Task>> toggleTaskCompletion(String taskId, bool isCompleted) {
    return _guard(
      () async =>
          (await _dataSource.toggleTaskCompletion(taskId, isCompleted)).toEntity(),
      'update that task',
    );
  }

  /// Runs [action] and converts any thrown error into a [FailureResult] whose
  /// message is safe to display. Raw exception text is never surfaced.
  Future<Result<T>> _guard<T>(
    Future<T> Function() action,
    String actionDescription,
  ) async {
    try {
      return Success(await action());
    } on Failure catch (failure) {
      return FailureResult(failure);
    } catch (_) {
      return FailureResult(
        ServerFailure('Could not $actionDescription. Please try again.'),
      );
    }
  }
}
