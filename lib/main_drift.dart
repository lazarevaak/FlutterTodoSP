import 'dart:io';
import 'package:drift/drift.dart' hide Column;
import 'package:drift/native.dart';
import 'package:flutter/material.dart' hide Table;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'main_drift.g.dart';

class Contacts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get phone => text()();
}

@DriftDatabase(tables: [Contacts])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Stream<List<Contact>> watchAllContacts() {
    return (select(contacts)).watch();
  }

  Future<int> addContact(String name, String phone) {
    return into(
      contacts,
    ).insert(ContactsCompanion(name: Value(name), phone: Value(phone)));
  }

  Future<void> deleteContact(int id) {
    return (delete(contacts)..where((t) => t.id.equals(id))).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'contacts.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

void main() {
  final database = AppDatabase();
  runApp(ContactsApp(database: database));
}

class ContactsApp extends StatelessWidget {
  final AppDatabase database;

  const ContactsApp({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drift Contacts',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: ContactsPage(database: database),
    );
  }
}

class ContactsPage extends StatefulWidget {
  final AppDatabase database;

  const ContactsPage({super.key, required this.database});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  void _add() {
    if (_nameController.text.isNotEmpty && _phoneController.text.isNotEmpty) {
      widget.database.addContact(_nameController.text, _phoneController.text);
      _nameController.clear();
      _phoneController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contacts List (SQL)')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _add,
                  child: const Text('Save Contact'),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<List<Contact>>(
              stream: widget.database.watchAllContacts(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();

                final contacts = snapshot.data!;
                return ListView.builder(
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(contact.name[0].toUpperCase()),
                      ),
                      title: Text(contact.name),
                      subtitle: Text(contact.phone),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () =>
                            widget.database.deleteContact(contact.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
