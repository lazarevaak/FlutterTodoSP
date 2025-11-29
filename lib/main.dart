import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const PersistenceApp());
}

class PersistenceApp extends StatelessWidget {
  const PersistenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Persistence Demo',
      theme: ThemeData(colorSchemeSeed: Colors.amber, useMaterial3: true),
      home: const PersistenceHomePage(),
    );
  }
}

class SharedPrefsStorage {
  Future<int> getCounter() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('counter') ?? 0;
  }

  Future<void> saveCounter(int counter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('counter', counter);
  }

  Future<String> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') ?? '';
  }

  Future<void> saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
  }
}

class FileSystemStorage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/my_notes.txt');
  }

  Future<void> writeToFile(String text) async {
    final file = await _localFile;
    await file.writeAsString(text);
  }

  Future<String> readFromFile() async {
    try {
      final file = await _localFile;
      return await file.readAsString();
    } catch (e) {
      return "Error reading file: $e";
    }
  }
}

class PersistenceHomePage extends StatefulWidget {
  const PersistenceHomePage({super.key});

  @override
  State<PersistenceHomePage> createState() => _PersistenceHomePageState();
}

class _PersistenceHomePageState extends State<PersistenceHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final SharedPrefsStorage _prefsStorage = SharedPrefsStorage();
  final FileSystemStorage _fileStorage = FileSystemStorage();

  int _counter = 0;
  final TextEditingController _usernameController = TextEditingController();

  final TextEditingController _fileInputController = TextEditingController();
  String _fileContents = "File is empty or not read yet.";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPreferences();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameController.dispose();
    _fileInputController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final counter = await _prefsStorage.getCounter();
    final username = await _prefsStorage.getUsername();

    if (mounted) {
      setState(() {
        _counter = counter;
        _usernameController.text = username;
      });
    }
  }

  Future<void> _incrementCounter() async {
    setState(() {
      _counter++;
    });
    await _prefsStorage.saveCounter(_counter);
  }

  Future<void> _saveUsername() async {
    await _prefsStorage.saveUsername(_usernameController.text);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username saved to SharedPrefs!')),
      );
    }
  }

  Future<void> _writeToFile() async {
    await _fileStorage.writeToFile(_fileInputController.text);

    if (mounted) {
      final path = await _fileStorage._localPath;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Saved to $path/my_notes.txt')));
      }
    }
  }

  Future<void> _readFromFile() async {
    final contents = await _fileStorage.readFromFile();
    setState(() {
      _fileContents = contents;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Persistence Demo'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.settings), text: "Shared Prefs"),
            Tab(icon: Icon(Icons.description), text: "File System"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSharedPrefsTab(), _buildFileSystemTab()],
      ),
    );
  }

  Widget _buildSharedPrefsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Counter (persists on restart):',
            style: TextStyle(fontSize: 18),
          ),
          Text('$_counter', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _incrementCounter,
            icon: const Icon(Icons.add),
            label: const Text("Increment & Save"),
          ),
          const Divider(height: 40),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(),
              helperText: 'Enter a name and click save',
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _saveUsername,
            child: const Text("Save Username"),
          ),
        ],
      ),
    );
  }

  Widget _buildFileSystemTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Write something to a local file:"),
          const SizedBox(height: 10),
          TextField(
            controller: _fileInputController,
            maxLines: 3,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Type your notes here...',
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _writeToFile,
            icon: const Icon(Icons.save),
            label: const Text("Write to 'my_notes.txt'"),
          ),
          const Divider(height: 30),
          const Text("Read from local file:"),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.grey[200],
            child: Text(_fileContents),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _readFromFile,
            icon: const Icon(Icons.download),
            label: const Text("Read from File"),
          ),
        ],
      ),
    );
  }
}
