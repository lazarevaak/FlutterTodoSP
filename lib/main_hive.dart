import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  await Hive.initFlutter();
  await Hive.openBox<String>('historyBox');

  runApp(const HiveHistoryApp());
}

class HiveHistoryApp extends StatelessWidget {
  const HiveHistoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hive History',
      theme: ThemeData(colorSchemeSeed: Colors.orange, useMaterial3: true),
      home: const HistoryPage(),
    );
  }
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final Box<String> _historyBox = Hive.box<String>('historyBox');

  void _addEvent() {
    final timestamp = DateTime.now().toString();
    _historyBox.add("Button pressed at $timestamp");
  }

  void _clearHistory() {
    _historyBox.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event History Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _clearHistory,
            tooltip: 'Clear All',
          ),
        ],
      ),
      body: Center(
        child: ValueListenableBuilder(
          valueListenable: _historyBox.listenable(),
          builder: (context, Box<String> box, _) {
            if (box.isEmpty) {
              return const Text(
                'No events yet.\nPress the button!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              );
            }

            return ListView.builder(
              itemCount: box.length,
              itemBuilder: (context, index) {
                // Display latest first
                final reversedIndex = box.length - 1 - index;
                final event = box.getAt(reversedIndex);
                return ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text(event ?? ''),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addEvent,
        label: const Text("Log Event"),
        icon: const Icon(Icons.touch_app),
      ),
    );
  }
}
