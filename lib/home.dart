import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const HomeScreen(),
    );
  }
}

class Note {
  String title;
  String content;

  Note({required this.title, required this.content});

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
      };

  static Note fromJson(Map<String, dynamic> json) => Note(
        title: json['title'],
        content: json['content'],
      );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Note> _notes = [];
  String _search = '';

  List<Note> get _filteredNotes {
    if (_search.isEmpty) return _notes;
    return _notes.where((note) {
      return note.title.toLowerCase().contains(_search.toLowerCase()) ||
          note.content.toLowerCase().contains(_search.toLowerCase());
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('notes');

    if (data != null) {
      final List decoded = json.decode(data);
      setState(() {
        _notes = decoded.map((e) => Note.fromJson(e)).toList();
      });
    }
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final data = json.encode(_notes.map((e) => e.toJson()).toList());
    await prefs.setString('notes', data);
  }

  void _openEditor({Note? note, int? index}) async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => NoteEditorScreen(note: note),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween(begin: 0.95, end: 1.0).animate(animation),
              child: child,
            ),
          );
        },
      ),
    );

    if (result != null && result is Note) {
      setState(() {
        if (index == null) {
          _notes.add(result);
        } else {
          _notes[index] = result;
        }
      });
      _saveNotes();
    }
  }

  void _delete(int index) {
    setState(() {
      _notes.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          onChanged: (value) {
            setState(() => _search = value);
          },
          decoration: const InputDecoration(
            hintText: 'Search...',
            border: InputBorder.none,
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _filteredNotes.isEmpty
            ? const Center(
                key: ValueKey('empty'),
                child: Text('EMPTY',
                    style: TextStyle(color: Colors.white54)),
              )
            : ListView.builder(
                key: const ValueKey('list'),
                itemCount: _filteredNotes.length,
                itemBuilder: (context, index) {
                  final note = _filteredNotes[index];
                  final realIndex = _notes.indexOf(note);

                  return TweenAnimationBuilder(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 400),
                    builder: (context, double value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Dismissible(
                      key: Key(note.title + index.toString()),
                      onDismissed: (_) => _delete(realIndex),
                      background: Container(color: Colors.redAccent),
                      child: ListTile(
                        title: Text(note.title),
                        subtitle: Text(
                          note.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.white54),
                          onPressed: () => _delete(realIndex),
                        ),
                        onTap: () =>
                            _openEditor(note: note, index: realIndex),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}

class NoteEditorScreen extends StatefulWidget {
  final Note? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController titleController;
  late TextEditingController contentController;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.note?.title);
    contentController =
        TextEditingController(text: widget.note?.content);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  void _save() {
    final note = Note(
      title: titleController.text,
      content: contentController.text,
    );

    Navigator.pop(context, note);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NOTE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
          )
        ],
      ),
      body: FadeTransition(
        opacity: _controller,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(hintText: 'TITLE'),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: TextField(
                  controller: contentController,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(hintText: 'TEXT'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}