import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'add.dart';

String _escape(String s) => s.replaceAll('\n', '\\n').replaceAll('\r', '');

String encodeProfileToText({
  required String firstName,
  required String lastName,
  required String middleName,
  required String description,
  required List<String> notes,
  required String? imageBase64,
}) {
  final buffer = StringBuffer();
  buffer.writeln(_escape(firstName));
  buffer.writeln(_escape(lastName));
  buffer.writeln(_escape(middleName));
  buffer.writeln(_escape(description));
  buffer.writeln(imageBase64 ?? '');
  buffer.writeln(notes.length);
  for (final note in notes) {
    buffer.writeln(_escape(note));
  }
  return buffer.toString();
}

class DatabaseScreen extends StatefulWidget {
  const DatabaseScreen({super.key});

  @override
  State<DatabaseScreen> createState() => _DatabaseScreenState();
}

class _DatabaseScreenState extends State<DatabaseScreen> {
  List<Map<String, dynamic>> profiles = [];
  List<Map<String, dynamic>> filtered = [];
  String query = '';

  @override
  void initState() {
    super.initState();
    loadProfiles();
  }

  Future<void> loadProfiles() async {
    final db = await DBHelper.initDB();

    await db.execute(
      'ALTER TABLE profiles ADD COLUMN isFavorite INTEGER DEFAULT 0',
    ).catchError((_) {});

    final data = await db.rawQuery('''
      SELECT p.*, GROUP_CONCAT(n.text, ' ') as notesText
      FROM profiles p
      LEFT JOIN notes n ON p.id = n.profileId
      GROUP BY p.id
    ''');

    profiles = data;
    applySearch();
  }

  void applySearch() {
    filtered = profiles.where((profile) {
      final text = (
        (profile['firstName'] ?? '') +
        (profile['lastName'] ?? '') +
        (profile['middleName'] ?? '') +
        (profile['description'] ?? '') +
        (profile['notesText'] ?? '')
      ).toLowerCase();

      return text.contains(query);
    }).toList();

    filtered.sort(
      (a, b) => (b['isFavorite'] ?? 0).compareTo(a['isFavorite'] ?? 0),
    );

    setState(() {});
  }

  void search(String value) {
    query = value.toLowerCase();
    applySearch();
  }

  Future<void> toggleFavorite(Map<String, dynamic> profile) async {
    final db = await DBHelper.initDB();

    final newValue = (profile['isFavorite'] ?? 0) == 1 ? 0 : 1;

    await db.update(
      'profiles',
      {'isFavorite': newValue},
      where: 'id = ?',
      whereArgs: [profile['id']],
    );

    loadProfiles();
  }

  Future<void> deleteProfile(int id) async {
    final db = await DBHelper.initDB();

    await db.delete('profiles', where: 'id = ?', whereArgs: [id]);
    await db.delete('notes', where: 'profileId = ?', whereArgs: [id]);

    loadProfiles();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            onChanged: search,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Поиск...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        Expanded(
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final p = filtered[index];
              final imagePath = p['imagePath'] as String?;

              return ListTile(
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => toggleFavorite(p),
                      child: Icon(
                        Icons.star,
                        color: (p['isFavorite'] ?? 0) == 1
                            ? Colors.yellow
                            : Colors.white24,
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundImage: imagePath != null
                          ? FileImage(File(imagePath))
                          : null,
                      backgroundColor: Colors.white10,
                      child: imagePath == null
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
                title: Text(
                  '${p['lastName'] ?? ''} ${p['firstName'] ?? ''}',
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditProfileScreen(profile: p),
                          ),
                        );
                        loadProfiles();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: Colors.black,
                            title: const Text('Удалить?',
                                style: TextStyle(color: Colors.white)),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text('Нет'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                child: const Text('Да'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          deleteProfile(p['id']);
                        }
                      },
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileDetailScreen(profile: p),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class ProfileDetailScreen extends StatefulWidget {
  final Map<String, dynamic> profile;

  const ProfileDetailScreen({super.key, required this.profile});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  List<String> notes = [];
  String? imagePath;

  @override
  void initState() {
    super.initState();
    imagePath = widget.profile['imagePath'] as String?;
    loadNotes();
  }

  Future<void> loadNotes() async {
    final db = await DBHelper.initDB();

    final data = await db.query(
      'notes',
      where: 'profileId = ?',
      whereArgs: [widget.profile['id']],
    );

    setState(() {
      notes = data.map((e) => e['text'] as String? ?? '').toList();
    });
  }

  Future<void> _shareProfile() async {
    final firstName = widget.profile['firstName'] ?? '';
    final lastName = widget.profile['lastName'] ?? '';
    final middleName = widget.profile['middleName'] ?? '';
    final description = widget.profile['description'] ?? '';

    String? imageBase64;
    if (imagePath != null && File(imagePath!).existsSync()) {
      try {
        final bytes = await File(imagePath!).readAsBytes();
        imageBase64 = base64Encode(bytes);
      } catch (e) {
      }
    }

    final plainText = encodeProfileToText(
      firstName: firstName,
      lastName: lastName,
      middleName: middleName,
      description: description,
      notes: notes,
      imageBase64: imageBase64,
    );

    final encoded = base64Encode(utf8.encode(plainText));

    await Clipboard.setData(ClipboardData(text: encoded));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Код профиля скопирован в буфер обмена')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _shareProfile,
            tooltip: 'Поделиться',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 70,
                backgroundColor: Colors.white10,
                backgroundImage:
                    imagePath != null ? FileImage(File(imagePath!)) : null,
                child: imagePath == null
                    ? const Icon(Icons.person, color: Colors.white, size: 70)
                    : null,
              ),
              const SizedBox(height: 30),

              Text(
                '${widget.profile['lastName'] ?? ''} ${widget.profile['firstName'] ?? ''}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              Text(
                widget.profile['description'] ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 30),

              if (notes.isNotEmpty) ...[
                const Text(
                  'Заметки',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                ...notes.map(
                  (note) => Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      note,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController firstName;
  late TextEditingController lastName;
  late TextEditingController middleName;
  late TextEditingController description;

  List<Map<String, dynamic>> notes = [];
  String? imagePath;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;

    firstName = TextEditingController(text: p['firstName']);
    lastName = TextEditingController(text: p['lastName']);
    middleName = TextEditingController(text: p['middleName']);
    description = TextEditingController(text: p['description']);
    imagePath = p['imagePath'] as String?;

    loadNotes();
  }

  Future<void> loadNotes() async {
    final db = await DBHelper.initDB();

    final data = await db.query(
      'notes',
      where: 'profileId = ?',
      whereArgs: [widget.profile['id']],
    );

    setState(() {
      notes = data.map((e) {
        return {
          'id': e['id'],
          'controller': TextEditingController(text: e['text'] as String? ?? ''),
        };
      }).toList();
    });
  }

  Future<void> pickImage() async {
    final path = await pickAndSaveImage();
    if (path != null) {
      setState(() {
        imagePath = path;
      });
    }
  }

  void addNote() {
    setState(() {
      notes.add({
        'id': null,
        'controller': TextEditingController(),
      });
    });
  }

  Future<void> deleteNote(int index) async {
    final db = await DBHelper.initDB();
    final note = notes[index];

    if (note['id'] != null) {
      await db.delete('notes', where: 'id = ?', whereArgs: [note['id']]);
    }

    setState(() {
      notes.removeAt(index);
    });
  }

  Future<void> save() async {
    final db = await DBHelper.initDB();

    await db.update(
      'profiles',
      {
        'firstName': firstName.text,
        'lastName': lastName.text,
        'middleName': middleName.text,
        'description': description.text,
        'imagePath': imagePath,
      },
      where: 'id = ?',
      whereArgs: [widget.profile['id']],
    );

    for (var note in notes) {
      if (note['id'] == null) {
        await db.insert('notes', {
          'profileId': widget.profile['id'],
          'text': note['controller'].text,
        });
      } else {
        await db.update(
          'notes',
          {'text': note['controller'].text},
          where: 'id = ?',
          whereArgs: [note['id']],
        );
      }
    }

    Navigator.pop(context);
  }

  @override
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    middleName.dispose();
    description.dispose();

    for (var n in notes) {
      n['controller'].dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Редактирование'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white10,
                backgroundImage: imagePath != null
                    ? FileImage(File(imagePath!))
                    : null,
                child: imagePath == null
                    ? const Icon(Icons.add_a_photo, color: Colors.white)
                    : null,
              ),
            ),

            const SizedBox(height: 20),

            _input(lastName, 'Фамилия'),
            _input(firstName, 'Имя'),
            _input(middleName, 'Отчество'),
            _input(description, 'Описание'),

            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Заметки',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            ),

            const SizedBox(height: 10),

            ...notes.asMap().entries.map((entry) {
              int i = entry.key;
              var note = entry.value;

              return Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextField(
                        controller: note['controller'],
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Заметка',
                          hintStyle:
                              const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white10,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Color.fromARGB(255, 255, 255, 255)),
                    onPressed: () => deleteNote(i),
                  )
                ],
              );
            }),

            TextButton(
              onPressed: addNote,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('Добавить заметку'),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: save,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white10,
              ),
              child: const Text('СОХРАНИТЬ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.white10,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}