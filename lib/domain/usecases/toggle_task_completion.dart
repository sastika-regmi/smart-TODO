import '../entities/task.dart';
import '../repositories/task_repository.dart';

class ToggleTaskCompletion {
  const ToggleTaskCompletion(this.repository);
  final TaskRepository repository;

  Future<Result<Task>> call(String taskId, bool isCompleted) =>
      repository.toggleTaskCompletion(taskId, isCompleted);
}
