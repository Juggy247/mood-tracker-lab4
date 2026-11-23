import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/data/sample_entries.dart';
import 'package:mood_tracker/main.dart';
import 'package:mood_tracker/models/mood_entry.dart';
import 'package:mood_tracker/widgets/mood_card.dart';
import 'package:mood_tracker/widgets/mood_summary.dart';

// Self-check for Lab 4. Run it with: flutter test
//
// Exercise 3 changed what the Save button does: it is always enabled and
// shows validation messages instead of being disabled. The tests below check
// the acceptance criteria in ACCEPTANCE.md.

const scoreError = 'Choose a score from 1 to 10';
final noteError = 'Note must be at most $maxNoteLength characters';

/// Renders the app in a window tall enough for every card to be built.
Future<void> pumpApp(WidgetTester tester, {double width = 400}) async {
  tester.view.physicalSize = Size(width, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MoodTrackerApp());
}

Finder get saveButton => find.widgetWithText(FilledButton, 'Save entry');

Future<void> chooseScore(WidgetTester tester, int score) async {
  await tester.tap(find.widgetWithText(ChoiceChip, '$score'));
  await tester.pump();
}

Future<void> tapSave(WidgetTester tester) async {
  await tester.tap(saveButton);
  await tester.pump();
}

int get cardCount => find.byType(MoodCard).evaluate().length;

String get noteText => noteField.controller!.text;

TextField get noteField =>
    find.byType(TextField).evaluate().single.widget as TextField;

void main() {
  // Criterion 1 (this replaces the old "Save is disabled until a score is
  // chosen" test, whose requirement changed).
  testWidgets('Save is enabled, and saving without a score shows an error',
      (tester) async {
    await pumpApp(tester);

    expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);
    expect(find.text(scoreError), findsNothing);

    await tapSave(tester);

    expect(find.text(scoreError), findsOneWidget);
    expect(cardCount, sampleEntries.length);
  });

  testWidgets('saving an entry puts it at the top of the history',
      (tester) async {
    await pumpApp(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, '3'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Rainy walk home');
    await tester.tap(saveButton);
    await tester.pump();

    expect(find.byType(MoodCard), findsNWidgets(sampleEntries.length + 1));
    expect(
      find.descendant(
        of: find.byType(MoodCard).first,
        matching: find.text('Rainy walk home'),
      ),
      findsOneWidget,
    );
  });

  // Criterion 2
  testWidgets('a note of exactly maxNoteLength characters is saved',
      (tester) async {
    await pumpApp(tester);
    final note = 'a' * maxNoteLength;

    await chooseScore(tester, 5);
    await tester.enterText(find.byType(TextField), note);
    await tapSave(tester);

    expect(cardCount, sampleEntries.length + 1);
    expect(
      find.descendant(
        of: find.byType(MoodCard).first,
        matching: find.text(note),
      ),
      findsOneWidget,
    );
    final newAverage = averageScore([
      MoodEntry(score: 5, createdAt: DateTime.now()),
      ...sampleEntries,
    ])!;
    // Look only inside the summary card, because other widgets show numbers.
    expect(
      find.descendant(
        of: find.byType(MoodSummary),
        matching: find.text('${sampleEntries.length + 1}'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(MoodSummary),
        matching: find.text(newAverage.toStringAsFixed(1)),
      ),
      findsOneWidget,
    );
    expect(find.text(scoreError), findsNothing);
    expect(find.text(noteError), findsNothing);
  });

  // Criterion 3
  testWidgets('a note over maxNoteLength is rejected and kept',
      (tester) async {
    await pumpApp(tester);
    final note = 'a' * (maxNoteLength + 1);

    await chooseScore(tester, 5);
    await tester.enterText(find.byType(TextField), note);
    await tapSave(tester);

    expect(find.text(noteError), findsOneWidget);
    expect(cardCount, sampleEntries.length);
    expect(noteText, note);
  });

  testWidgets('trailing spaces count towards the note limit', (tester) async {
    await pumpApp(tester);

    await chooseScore(tester, 5);
    await tester.enterText(
      find.byType(TextField),
      '${'a' * maxNoteLength} ',
    );
    await tapSave(tester);

    expect(find.text(noteError), findsOneWidget);
    expect(cardCount, sampleEntries.length);
  });

  // Criterion 4
  testWidgets('an empty note is saved', (tester) async {
    await pumpApp(tester);

    await chooseScore(tester, 7);
    await tapSave(tester);

    expect(cardCount, sampleEntries.length + 1);
    expect(find.text(scoreError), findsNothing);
    expect(find.text(noteError), findsNothing);
  });

  testWidgets('a whitespace-only note is saved as an optional note',
      (tester) async {
    await pumpApp(tester);

    await chooseScore(tester, 7);
    await tester.enterText(find.byType(TextField), '   ');
    await tapSave(tester);

    expect(cardCount, sampleEntries.length + 1);
    expect(
      find.descendant(
        of: find.byType(MoodCard).first,
        matching: find.text('No note'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a note is trimmed before it is saved', (tester) async {
    await pumpApp(tester);

    await chooseScore(tester, 7);
    await tester.enterText(find.byType(TextField), '  Calm and rested  ');
    await tapSave(tester);

    expect(
      find.descendant(
        of: find.byType(MoodCard).first,
        matching: find.text('Calm and rested'),
      ),
      findsOneWidget,
    );
  });

  // Criterion 5
  testWidgets('choosing a score clears the score error', (tester) async {
    await pumpApp(tester);

    await tapSave(tester);
    expect(find.text(scoreError), findsOneWidget);

    await chooseScore(tester, 4);
    expect(find.text(scoreError), findsNothing);
  });

  testWidgets('shortening the note clears the note error', (tester) async {
    await pumpApp(tester);

    await chooseScore(tester, 5);
    await tester.enterText(find.byType(TextField), 'a' * (maxNoteLength + 1));
    await tapSave(tester);
    expect(find.text(noteError), findsOneWidget);

    // Still too long: the error stays.
    await tester.enterText(find.byType(TextField), 'a' * (maxNoteLength + 1));
    await tester.pump();
    expect(find.text(noteError), findsOneWidget);

    // Back within the limit: the error goes away.
    await tester.enterText(find.byType(TextField), 'a' * maxNoteLength);
    await tester.pump();
    expect(find.text(noteError), findsNothing);
  });

  // Criterion 6
  testWidgets('the form is cleared after a successful save', (tester) async {
    await pumpApp(tester);

    await chooseScore(tester, 6);
    await tester.enterText(find.byType(TextField), 'Good day');
    await tapSave(tester);

    expect(cardCount, sampleEntries.length + 1);
    expect(noteText, isEmpty);
    for (var score = 1; score <= 10; score++) {
      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, '$score'),
      );
      expect(chip.selected, isFalse, reason: 'chip $score still selected');
    }
    expect(find.text(scoreError), findsNothing);
    expect(find.text(noteError), findsNothing);
  });

  // Criterion 7
  testWidgets('the score error fits on a 320 px screen', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpApp(tester, width: 320);

    await tapSave(tester);

    expect(find.text(scoreError), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the note error fits on a 320 px screen', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpApp(tester, width: 320);

    await chooseScore(tester, 5);
    await tester.enterText(find.byType(TextField), 'a' * (maxNoteLength + 1));
    await tapSave(tester);

    expect(find.text(noteError), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
