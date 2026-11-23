import 'package:flutter/material.dart';

import '../models/mood_entry.dart';
import 'mood_score_selector.dart';

/// A form for recording a new mood entry.
///
/// Exercise 1, step 3, and Exercise 2, steps 1-3, plus Exercise 3 validation.
class MoodEntryForm extends StatefulWidget {
  const MoodEntryForm({super.key, required this.onSubmit});

  /// Called with the new entry when the user saves it.
  final ValueChanged<MoodEntry> onSubmit;

  @override
  State<MoodEntryForm> createState() => _MoodEntryFormState();
}

class _MoodEntryFormState extends State<MoodEntryForm> {
  int? _score;
  final TextEditingController _noteController = TextEditingController();

  /// Shown under the score chips when Save is tapped without a score.
  String? _scoreError;

  /// Shown under the note field when the note is too long.
  String? _noteError;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    final score = _score;
    final rawNote = _noteController.text;

    // Validate the raw text, so trailing spaces count towards the limit.
    final scoreError = score == null ? 'Choose a score from 1 to 10' : null;
    final noteError = rawNote.length > maxNoteLength
        ? 'Note must be at most $maxNoteLength characters'
        : null;

    if (score == null || noteError != null) {
      // Show the errors and stop. The note stays in the field.
      setState(() {
        _scoreError = scoreError;
        _noteError = noteError;
      });
      return;
    }

    final note = rawNote.trim();

    widget.onSubmit(
      MoodEntry(
        score: score,
        note: note.isEmpty ? null : note,
        createdAt: DateTime.now(),
      ),
    );

    // Clear the form: no score, no errors, empty note.
    setState(() {
      _score = null;
      _scoreError = null;
      _noteError = null;
    });
    _noteController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'How are you feeling?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            MoodScoreSelector(
              selectedScore: _score,
              onChanged: (score) {
                setState(() {
                  _score = score;
                  _scoreError = null; // the user corrected the problem
                });
              },
            ),
            if (_scoreError != null) ...[
              const SizedBox(height: 8),
              // A plain Text wraps onto more lines on narrow screens.
              Text(
                _scoreError!,
                style: TextStyle(color: colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              onChanged: (text) {
                // Clear the error once the note is short enough again.
                if (_noteError != null && text.length <= maxNoteLength) {
                  setState(() {
                    _noteError = null;
                  });
                }
              },
              decoration: InputDecoration(
                labelText: 'Note (optional)',
                border: const OutlineInputBorder(),
                errorText: _noteError,
                errorMaxLines: 3,
              ),
            ),
            const SizedBox(height: 16),
            // Always enabled, so tapping it without a score shows a message.
            FilledButton(
              onPressed: _save,
              child: const Text('Save entry'),
            ),
          ],
        ),
      ),
    );
  }
}
