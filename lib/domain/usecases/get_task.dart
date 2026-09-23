import '../entities/task.dart';
import '../repositories/task_repository.dart';

class GetTask {
  const GetTask(this.repository);
  final TaskRepository repository;

  Future<Result<Task>> call(String taskId) => repository.getTask(taskId);
}
