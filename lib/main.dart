import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class SharedPrefsTodoRepository implements TodoRepository {
  final _controller = StreamController<List<TodoItem>>.broadcast();
  late SharedPreferences _prefs;

  static const _key = 'todos';

  @override
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _emit(); 
  }

  List<TodoItem> _decode() {
    final data = _prefs.getStringList(_key) ?? [];
    return data.map((e) {
      final jsonMap = jsonDecode(e);
      return TodoItem(
        id: jsonMap['id'],
        title: jsonMap['title'],
        dueDate: DateTime.parse(jsonMap['dueDate']),
        isCompleted: jsonMap['isCompleted'],
      );
    }).toList();
  }

  void _save(List<TodoItem> items) {
    final encoded = items.map((e) {
      return jsonEncode({
        'id': e.id,
        'title': e.title,
        'dueDate': e.dueDate.toIso8601String(),
        'isCompleted': e.isCompleted,
      });
    }).toList();
    _prefs.setStringList(_key, encoded);
    _emit();
  }

  void _emit() => _controller.add(_decode());

  @override
  Stream<List<TodoItem>> getTodos() async* {
    yield _decode();

    yield* _controller.stream;
  }

  @override
  Future<void> addTodo(String title, DateTime dueDate) async {
    final items = _decode();
    final newItem = TodoItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      dueDate: dueDate,
    );
    items.add(newItem);
    _save(items);
  }

  @override
  Future<void> deleteTodo(String id) async {
    final items = _decode()..removeWhere((t) => t.id == id);
    _save(items);
  }

  @override
  Future<void> toggleTodo(String id) async {
    final items = _decode();
    final index = items.indexWhere((t) => t.id == id);
    final old = items[index];

    items[index] = TodoItem(
      id: old.id,
      title: old.title,
      dueDate: old.dueDate,
      isCompleted: !old.isCompleted,
    );

    _save(items);
  }
}

late final TodoRepository repo;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  repo = SharedPrefsTodoRepository();
  await repo.init();

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
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTodoPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<TodoItem>>(
        stream: repo.getTodos(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final todos = snapshot.data!;
          if (todos.isEmpty) {
            return const Center(child: Text('No tasks yet. Add one!'));
          }

          return ListView.builder(
            itemCount: todos.length,
            itemBuilder: (context, i) {
              final todo = todos[i];
              return ListTile(
                leading: Checkbox(
                  value: todo.isCompleted,
                  onChanged: (_) => repo.toggleTodo(todo.id),
                ),
                title: Text(
                  todo.title,
                  style: TextStyle(
                    decoration: todo.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                subtitle:
                    Text("Due: ${todo.dueDate.toString().split(' ')[0]}"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Delete task?"),
                        content: Text(todo.title),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, false),
                            child: const Text("Cancel"),
                          ),
                          FilledButton(
                            onPressed: () =>
                                Navigator.pop(context, true),
                            child: const Text("Delete"),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await repo.deleteTodo(todo.id);
                    }
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

class AddTodoPage extends StatefulWidget {
  const AddTodoPage({super.key});

  @override
  State<AddTodoPage> createState() => _AddTodoPageState();
}

class _AddTodoPageState extends State<AddTodoPage> {
  final _controller = TextEditingController();
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Task")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: "Task title"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  initialDate: DateTime.now(),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
              child: Text(
                _selectedDate == null
                    ? "Choose due date"
                    : "Due: ${_selectedDate!.toString().split(' ')[0]}",
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () async {
                if (_controller.text.isEmpty || _selectedDate == null) return;

                await repo.addTodo(_controller.text, _selectedDate!);
                Navigator.pop(context);
              },
              child: const Text("Add task"),
            ),
          ],
        ),
      ),
    );
  }
}
