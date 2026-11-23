# Form validation: acceptance criteria

1. Given no score is selected, when I tap Save entry, then the message
   "Choose a score from 1 to 10" appears and nothing is added to the history.

2. Given a score is selected and the note is exactly 2000 characters,
   when I tap Save entry, then the entry appears at the top of the history,
   the average updates, and no error message is shown.

3. Given a score is selected and the note is 2001 characters, when I tap
   Save entry, then the message "Note must be at most 2000 characters"
   appears, nothing is added to the history, and my note text is still
   in the field.

4. Given a score is selected and the note is empty, when I tap Save entry,
   then the entry is saved (the note is optional).

5. Given the "Choose a score" message is showing, when I select a score,
   then the message disappears.

6. Given an entry was saved successfully, then the form is cleared
   (no score selected, empty note) and no error message is visible.

7. Given a narrow phone screen (about 320 px wide), when either error
   message is shown, then it is fully readable and nothing overflows.