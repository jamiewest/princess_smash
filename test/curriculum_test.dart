import 'package:flutter_test/flutter_test.dart';
import 'package:princess_smash/game/education/curriculum.dart';
import 'package:princess_smash/game/education/lesson.dart';

/// Guards the authoring rules for lesson content, so adding a new word or
/// story can't quietly break the level generator or the quiz cards.
void main() {
  group('curriculum', () {
    test('has lessons of every kind', () {
      for (final kind in LessonKind.values) {
        expect(
          kCurriculum.where((lesson) => lesson.kind == kind),
          isNotEmpty,
          reason: 'no lessons of kind $kind',
        );
      }
    });

    for (final lesson in kCurriculum) {
      group('"${lesson.title}"', () {
        test('focus word is lowercase a-z and level-sized', () {
          expect(lesson.word, matches(RegExp(r'^[a-z]{3,12}$')));
        });

        test('questions are well formed', () {
          expect(lesson.questions, isNotEmpty);
          for (final question in lesson.questions) {
            expect(question.prompt.trim(), isNotEmpty);
            expect(question.choices.length, greaterThanOrEqualTo(2));
            expect(question.answerIndex, greaterThanOrEqualTo(0));
            expect(question.answerIndex, lessThan(question.choices.length));
            expect(
              question.choices.toSet().length,
              question.choices.length,
              reason: 'duplicate choices would make the answer ambiguous',
            );
          }
        });

        test('story lessons have a story; others have an intro', () {
          expect(lesson.intro.trim(), isNotEmpty);
          if (lesson.kind == LessonKind.story) {
            expect(lesson.story, isNotNull);
            expect(lesson.story!.trim(), isNotEmpty);
          }
        });
      });
    }
  });
}
