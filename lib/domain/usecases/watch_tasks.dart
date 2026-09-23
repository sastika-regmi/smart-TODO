import '../entities/task.dart';
import '../repositories/task_repository.dart';

class WatchTasks {
  const WatchTasks(this.repository);
  final TaskRepository repository;

  Stream<List<Task>> call(String userId) => repository.watchTasks(userId);
}
