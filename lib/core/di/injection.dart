import 'package:cloud_firestore/cloud_firestore.dart';
// `hide AuthProvider` avoids a collision with this project's own AuthProvider.
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/auth_service.dart';
import '../../core/utils/prefs_helper.dart';
import '../../data/datasources/task_remote_data_source.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/usecases/create_task.dart';
import '../../domain/usecases/delete_task.dart';
import '../../domain/usecases/toggle_task_completion.dart';
import '../../domain/usecases/update_task.dart';
import '../../domain/usecases/watch_tasks.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/task_provider.dart';
import '../../presentation/providers/theme_provider.dart';

/// Builds the object graph once, before the first frame.
///
/// Kept as plain constructor calls rather than a service locator: the whole
/// graph is seven objects, and reading it top to bottom is faster than learning
/// a DI framework.
Future<List<SingleChildWidget>> initializeDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  final authService = AuthService(auth, firestore);

  final taskDataSource = TaskRemoteDataSourceImpl(firestore, auth);
  final TaskRepository taskRepository = TaskRepositoryImpl(taskDataSource);

  final themeProvider = ThemeProvider(PrefsHelper(prefs));
  final authProvider = AuthProvider(authService);

  return <SingleChildWidget>[
    ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
    ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
    // Created lazily rather than with `.value`: it only needs to exist once a
    // screen actually reads tasks, and provider then disposes it for us.
    ChangeNotifierProvider<TaskProvider>(
      create: (_) => TaskProvider(
        watchTasks: WatchTasks(taskRepository),
        createTask: CreateTask(taskRepository),
        updateTask: UpdateTask(taskRepository),
        deleteTask: DeleteTask(taskRepository),
        toggleTaskCompletion: ToggleTaskCompletion(taskRepository),
        authProvider: authProvider,
      ),
    ),
  ];
}
