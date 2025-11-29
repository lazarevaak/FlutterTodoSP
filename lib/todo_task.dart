import 'package:flutter/material.dart';
import 'dart:async';

// ЗАДАНИЕ
// 1. Реализуйте интерфейс TodoRepository используя любую БД (на выбор – Shared Preferences, File System, Hive, Drift).
// 2. Реализуйте экран добавления задачи (AddTodoPage) и навигацию к нему.
// 3. Реализуйте удаление задачи с подтверждением (Dialog).

class TodoItem {
  final String id;
  final String title;
  final DateTime dueDate;
  final bool isCompleted;

  TodoItem({
    required this.id,
    required this.title,
    required this.dueDate,
    this.isCompleted = false,
  });
}

abstract class TodoRepository {
  Future<void> init();
  Stream<List<TodoItem>> getTodos();
  Future<void> addTodo(String title, DateTime dueDate);
  Future<void> deleteTodo(String id);
  Future<void> toggleTodo(String id);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Инициализируйте ваш репозиторий

  runApp(const TaskApp());
}

class TaskApp extends StatelessWidget {
  const TaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Persistence Task',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Tasks')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Навигация на ваш экран создания задачи
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Экран добавления не реализован!')),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<TodoItem>>(
        // TODO: Получать Todo's из репозитория
        stream: Stream.value([]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No tasks yet. Add one!'));
          }

          final todos = snapshot.data!;
          return ListView.builder(
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final todo = todos[index];
              return ListTile(
                leading: Checkbox(
                  value: todo.isCompleted,
                  onChanged: (_) {
                    // TODO: Реализовать переключение статуса задачи
                  },
                ),
                title: Text(
                  todo.title,
                  style: TextStyle(
                    decoration: todo.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                subtitle: Text('Due: ${todo.dueDate.toString().split(' ')[0]}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    // TODO: Реализовать удаление с подтверждением
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
