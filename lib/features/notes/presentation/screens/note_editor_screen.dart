import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../models/note_model.dart';
import '../../repositories/notes_repository.dart';

class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({super.key, this.note});

  final Note? note;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final NotesRepository _repository = NotesRepository();

  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  bool _isLoading = false;
  late bool _isPinned;

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );
    _isPinned = widget.note?.isPinned ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _showMessage('Your session has expired. Please sign in again.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isEditing) {
        await _repository.updateNote(
          userId: userId,
          noteId: widget.note!.id,
          title: _titleController.text,
          content: _contentController.text,
          isPinned: _isPinned,
        );
      } else {
        await _repository.addNote(
          userId: userId,
          title: _titleController.text,
          content: _contentController.text,
          isPinned: _isPinned,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) _showMessage('Could not save note: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteNote() async {
    final note = widget.note;
    if (note == null) return;

    final confirmed =
        await showDialog<bool>(
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
    if (!confirmed || !mounted) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _showMessage('Your session has expired. Please sign in again.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _repository.deleteNote(userId: userId, noteId: note.id);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) _showMessage('Could not delete note: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit note' : 'New note'),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: _isLoading ? null : () => Navigator.maybePop(context),
          icon: const Icon(LucideIcons.arrow_left),
        ),
        actions: [
          IconButton(
            tooltip: _isPinned ? 'Unpin note' : 'Pin to top',
            onPressed: _isLoading
                ? null
                : () {
                    setState(() => _isPinned = !_isPinned);
                    _showMessage(
                      _isPinned ? 'Note will be pinned to top' : 'Note unpinned',
                    );
                  },
            icon: Icon(
              _isPinned ? LucideIcons.pin_off : LucideIcons.pin,
              color: _isPinned ? const Color(0xFF315C4B) : null,
            ),
          ),
          if (_isEditing)
            IconButton(
              tooltip: 'Delete note',
              onPressed: _isLoading ? null : _deleteNote,
              icon: const Icon(LucideIcons.trash, color: Color(0xFF9C3D36)),
            ),
          IconButton(
            tooltip: 'Save note',
            onPressed: _isLoading ? null : _saveNote,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.check),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      maxLength: 120,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                      decoration: const InputDecoration(
                        hintText: 'Title',
                        counterText: '',
                        prefixIcon: Icon(LucideIcons.type),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Add a note title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _contentController,
                        expands: true,
                        maxLines: null,
                        maxLength: 20000,
                        textCapitalization: TextCapitalization.sentences,
                        textAlignVertical: TextAlignVertical.top,
                        style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(height: 1.6),
                        decoration: const InputDecoration(
                          hintText: 'Write your thoughts…',
                          counterText: '',
                          alignLabelWithHint: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isEditing
                          ? 'Changes will be saved to your private space.'
                          : 'Only you can see this note.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: const Color(0xFF92968F)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
