import '../entities/task.dart';
import '../repositories/task_repository.dart';

class GetTasks {
  const GetTasks(this.repository);
  final TaskRepository repository;

  Future<Result<List<Task>>> call(String userId) => repository.getTasks(userId);
}
