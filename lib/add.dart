import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Future<Database> initDB() async {
    final path = join(await getDatabasesPath(), 'profiles.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE profiles(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            firstName TEXT,
            lastName TEXT,
            middleName TEXT,
            description TEXT,
            imagePath TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE notes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            profileId INTEGER,
            text TEXT
          )
        ''');
      },
    );
  }
}

Future<String?> pickAndSaveImage() async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(source: ImageSource.gallery);

  if (picked == null) return null;

  final dir = await getApplicationDocumentsDirectory();
  final fileName = DateTime.now().millisecondsSinceEpoch.toString();

  final savedImage = await File(picked.path).copy('${dir.path}/$fileName.jpg');

  return savedImage.path;
}

Future<String?> saveBase64Image(String base64String) async {
  try {
    final bytes = base64Decode(base64String);
    final dir = await getApplicationDocumentsDirectory();
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final file = File('${dir.path}/$fileName.jpg');
    await file.writeAsBytes(bytes);
    return file.path;
  } catch (e) {
    return null;
  }
}

class AddScreen extends StatefulWidget {
  const AddScreen({super.key});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> with TickerProviderStateMixin {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final middleNameController = TextEditingController();
  final descriptionController = TextEditingController();

  List<TextEditingController> notes = [];
  String? imagePath;

  late final AnimationController _imageController;
  late final Animation<double> _imageScale;

  @override
  void initState() {
    super.initState();
    _imageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _imageScale = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _imageController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    middleNameController.dispose();
    descriptionController.dispose();

    for (var n in notes) {
      n.dispose();
    }

    _imageController.dispose();

    super.dispose();
  }

  void addNote() {
    setState(() {
      notes.add(TextEditingController());
    });
  }

  Future<void> pickImage() async {
    final path = await pickAndSaveImage();
    if (path != null) {
      setState(() {
        imagePath = path;
      });
      _imageController.forward(from: 0);
    }
  }

  Future<void> saveProfile() async {
    final db = await DBHelper.initDB();

    final id = await db.insert('profiles', {
      'firstName': firstNameController.text,
      'lastName': lastNameController.text,
      'middleName': middleNameController.text,
      'description': descriptionController.text,
      'imagePath': imagePath,
    });

    for (var note in notes) {
      await db.insert('notes', {
        'profileId': id,
        'text': note.text,
      });
    }

    firstNameController.clear();
    lastNameController.clear();
    middleNameController.clear();
    descriptionController.clear();

    for (var note in notes) {
      note.dispose();
    }
    notes.clear();

    setState(() {
      imagePath = null;
    });
  }

  Future<void> importProfile() async {
    final clipboardData = await Clipboard.getData('text/plain');
    if (clipboardData == null || clipboardData.text == null) return;

    final jsonString = clipboardData.text!;
    Map<String, dynamic> data;
    try {
      data = jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return;
    }

    final firstName = data['firstName'] ?? '';
    final lastName = data['lastName'] ?? '';
    if (firstName.isEmpty && lastName.isEmpty) return;

    for (var c in notes) {
      c.dispose();
    }
    notes.clear();

    firstNameController.text = firstName;
    lastNameController.text = lastName;
    middleNameController.text = data['middleName'] ?? '';
    descriptionController.text = data['description'] ?? '';

    final notesList = data['notes'] as List? ?? [];
    for (var noteText in notesList) {
      notes.add(TextEditingController(text: noteText));
    }

    String? newImagePath;
    if (data['imageBase64'] != null && data['imageBase64'].toString().isNotEmpty) {
      newImagePath = await saveBase64Image(data['imageBase64']);
    }

    setState(() {
      imagePath = newImagePath;
      if (newImagePath != null) {
        _imageController.forward(from: 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: StaticGridPainter(),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: pickImage,
                  child: AnimatedBuilder(
                    animation: _imageController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _imageScale.value,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[900],
                          backgroundImage: imagePath != null
                              ? FileImage(File(imagePath!))
                              : null,
                          child: imagePath == null
                              ? const Icon(Icons.add_a_photo,
                                  size: 40, color: Colors.white70)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                _animatedInput(lastNameController, 'Фамилия'),
                _animatedInput(firstNameController, 'Имя'),
                _animatedInput(middleNameController, 'Отчество'),
                _animatedInput(descriptionController, 'Описание'),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Заметки',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ...notes.asMap().entries.map((entry) {
                  int index = entry.key;
                  TextEditingController controller = entry.value;
                  return AnimatedNote(
                    key: ValueKey(controller),
                    controller: controller,
                    index: index,
                    onDelete: () {
                      setState(() {
                        controller.dispose();
                        notes.removeAt(index);
                      });
                    },
                  );
                }),
                TextButton.icon(
                  onPressed: addNote,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Добавить заметку',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      onPressed: saveProfile,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'СОХРАНИТЬ',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.5),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: importProfile,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'ИМПОРТ',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _animatedInput(TextEditingController controller, String label) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 20),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Colors.grey[900],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedNote extends StatefulWidget {
  final TextEditingController controller;
  final int index;
  final VoidCallback onDelete;

  const AnimatedNote({
    super.key,
    required this.controller,
    required this.index,
    required this.onDelete,
  });

  @override
  State<AnimatedNote> createState() => _AnimatedNoteState();
}

class _AnimatedNoteState extends State<AnimatedNote>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _deleteNote() {
    _controller.reverse().then((_) {
      widget.onDelete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _opacityAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Заметка ${widget.index + 1}',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white54),
                onPressed: _deleteNote,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StaticGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final columns = 30;
    final rows = 50;
    final cellWidth = size.width / columns;
    final cellHeight = size.height / rows;

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= columns; i++) {
      if (i % 5 == 0) {
        canvas.drawLine(
          Offset(i * cellWidth, 0),
          Offset(i * cellWidth, size.height),
          gridPaint,
        );
      }
    }

    for (int i = 0; i <= rows; i++) {
      if (i % 5 == 0) {
        canvas.drawLine(
          Offset(0, i * cellHeight),
          Offset(size.width, i * cellHeight),
          gridPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}