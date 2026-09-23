import '../entities/task.dart';
import '../repositories/task_repository.dart';

class CreateTask {
  const CreateTask(this.repository);
  final TaskRepository repository;

  Future<Result<Task>> call(Task task) => repository.createTask(task);
}
