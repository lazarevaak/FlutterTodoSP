import 'package:flutter/material.dart';

import '../main.dart';

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
