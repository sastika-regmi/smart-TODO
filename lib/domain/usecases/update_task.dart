import '../entities/task.dart';
import '../repositories/task_repository.dart';

class UpdateTask {
  const UpdateTask(this.repository);
  final TaskRepository repository;

  Future<Result<Task>> call(Task task) => repository.updateTask(task);
}
