import '../../core/errors/failures.dart';
import '../entities/task.dart';

abstract class TaskRepository {
  Future<Result<List<Task>>> getTasks(String userId);
  Stream<List<Task>> watchTasks(String userId);
  Future<Result<Task>> getTask(String taskId);
  Future<Result<Task>> createTask(Task task);
  Future<Result<Task>> updateTask(Task task);
  Future<Result<void>> deleteTask(String taskId);
  Future<Result<Task>> toggleTaskCompletion(String taskId, bool isCompleted);
}

sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

class FailureResult<T> extends Result<T> {
  const FailureResult(this.failure);
  final Failure failure;
}
