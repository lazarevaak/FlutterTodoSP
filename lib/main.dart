import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_page.dart';

// 1. Реализовала интерфейс TodoRepository, используя БД (Shared Preferences).
// 2. Реализовала экран добавления задачи и навигацию к нему (screens/add_todo_page.dart).
// 3. Реализовала удаление задачи с подтверждением (Dialog).

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
