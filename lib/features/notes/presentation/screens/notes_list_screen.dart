import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';

import '../../models/note_model.dart';
import '../../repositories/notes_repository.dart';
import 'note_editor_screen.dart';

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  static const _noteColors = [
    Color(0xFFF0EBDD),
    Color(0xFFE7EEE8),
    Color(0xFFF2E8E3),
    Color(0xFFE9E9F0),
  ];

  final NotesRepository _repository = NotesRepository();
  final String _userId = FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController _searchController = TextEditingController();

  late final Stream<List<Note>> _notesStream = _repository.getNotesStream(
    _userId,
  );
  String _searchQuery = '';
  bool _isSearching = false;

  bool _isOffline = false;
  late final StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _updateConnectivityStatus,
    );
  }

  Future<void> _checkInitialConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _updateConnectivityStatus(results);
  }

  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    final offline = results.isEmpty || results.contains(ConnectivityResult.none);
    if (mounted && offline != _isOffline) {
      setState(() => _isOffline = offline);
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Are you sure you want to sign out of your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseAuth.instance.signOut();
    } catch (error) {
      if (mounted) _showMessage('Could not sign out: $error');
    }
  }

  Future<bool> _confirmDelete() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete note?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF9C3D36),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteNote(Note note) async {
    try {
      await _repository.deleteNote(userId: _userId, noteId: note.id);
      if (mounted) _showMessage('Note deleted');
    } catch (error) {
      if (mounted) _showMessage('Could not delete note: $error');
    }
  }

  Future<void> _togglePin(Note note) async {
    try {
      await _repository.togglePinStatus(
        userId: _userId,
        noteId: note.id,
        currentStatus: note.isPinned,
      );
      if (mounted) {
        _showMessage(note.isPinned ? 'Note unpinned' : 'Note pinned to top');
      }
    } catch (error) {
      if (mounted) _showMessage('Could not update pin status: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search notes',
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: (value) =>
                    setState(() => _searchQuery = value.trim().toLowerCase()),
              )
            : const Text('My notes'),
        actions: [
          IconButton(
            tooltip: _isSearching ? 'Close search' : 'Search',
            onPressed: _toggleSearch,
            icon: Icon(_isSearching ? LucideIcons.x : LucideIcons.search),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: _signOut,
            icon: const Icon(LucideIcons.log_out),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _isOffline ? 38 : 0,
              color: const Color(0xFFFFF3CD),
              child: _isOffline
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: const [
                          Icon(LucideIcons.cloud_off, size: 16, color: Color(0xFF856404)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Offline mode. Changes are saved locally and will sync later.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF856404),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            if (!_isSearching)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'A space for your thoughts',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(color: const Color(0xFF747A73)),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        email,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: const Color(0xFF92968F)),
                      ),
                    ],
                  ],
                ),
              ),
            Expanded(
              child: StreamBuilder<List<Note>>(
                stream: _notesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _MessageState(
                      icon: LucideIcons.cloud_off,
                      title: 'Could not load notes',
                      message: 'Check your connection and try again.',
                    );
                  }

                  final allNotes = snapshot.data ?? const <Note>[];
                  final notes = allNotes
                      .where((note) {
                        return note.title.toLowerCase().contains(
                              _searchQuery,
                            ) ||
                            note.content.toLowerCase().contains(_searchQuery);
                      })
                      .toList(growable: false);

                  if (notes.isEmpty) {
                    return _MessageState(
                      icon: _searchQuery.isEmpty
                          ? LucideIcons.sticky_note
                          : LucideIcons.search_x,
                      title: _searchQuery.isEmpty
                          ? 'Nothing here yet'
                          : 'No results found',
                      message: _searchQuery.isEmpty
                          ? 'Create your first note and keep your ideas close.'
                          : 'Try a different search term.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                    itemCount: notes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return Dismissible(
                        key: ValueKey(note.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) => _confirmDelete(),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5E7E4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            LucideIcons.trash,
                            color: Color(0xFF9C3D36),
                          ),
                        ),
                        onDismissed: (_) => _deleteNote(note),
                        child: _NoteCard(
                          note: note,
                          color: _noteColors[index % _noteColors.length],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => NoteEditorScreen(note: note),
                            ),
                          ),
                          onTogglePin: () => _togglePin(note),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const NoteEditorScreen()),
        ),
        icon: const Icon(LucideIcons.plus),
        label: const Text(
          'New note',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.color,
    required this.onTap,
    required this.onTogglePin,
  });

  final Note note;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onTogglePin;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: note.isPinned ? const Color(0xFF315C4B) : const Color(0xFFECE9E1),
          width: note.isPinned ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  note.isPinned ? LucideIcons.pin : LucideIcons.sticky_note,
                  color: const Color(0xFF315C4B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            note.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (note.isPinned)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              LucideIcons.pin,
                              size: 14,
                              color: const Color(0xFF315C4B),
                            ),
                          ),
                      ],
                    ),
                    if (note.content.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        note.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF747A73),
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          DateFormat('dd.MM.yyyy · HH:mm')
                              .format(note.updatedAt ?? note.createdAt),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: const Color(0xFF92968F)),
                        ),
                        if (note.isSyncPending) ...[
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                LucideIcons.cloud_upload,
                                size: 13,
                                color: Color(0xFFD97706),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Sync pending',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: note.isPinned ? 'Unpin note' : 'Pin note',
                onPressed: onTogglePin,
                icon: Icon(
                  note.isPinned ? LucideIcons.pin_off : LucideIcons.pin,
                  size: 18,
                  color: note.isPinned
                      ? const Color(0xFF315C4B)
                      : const Color(0xFF9A9E98),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(36, 24, 36, 72),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE8EFEA),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 34, color: const Color(0xFF315C4B)),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: const Color(0xFF747A73), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
