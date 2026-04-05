import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'add.dart';

Future<String> exportProfile(Map<String, dynamic> profile) async {
  final db = await DBHelper.initDB();

  final notes = await db.query(
    'notes',
    where: 'profileId = ?',
    whereArgs: [profile['id']],
  );

  final data = {
    'profile': profile,
    'notes': notes,
  };

  return base64Encode(utf8.encode(jsonEncode(data)));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
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
                '${widget.profile['lastName']} ${widget.profile['firstName']}',
                style: const TextStyle(color: Colors.white, fontSize: 28),
              ),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: () async {
                  final code = await exportProfile(widget.profile);

                  await Clipboard.setData(ClipboardData(text: code));

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Код скопирован')),
                  );
                },
                icon: const Icon(Icons.share),
                label: const Text('ПОДЕЛИТЬСЯ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}