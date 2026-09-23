import '../repositories/task_repository.dart';

class DeleteTask {
  const DeleteTask(this.repository);
  final TaskRepository repository;

  Future<Result<void>> call(String taskId) => repository.deleteTask(taskId);
}
