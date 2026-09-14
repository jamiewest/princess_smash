/// The educational goals a generated level is built around.
///
/// Every lesson has a *focus word* the princess spells by collecting letter
/// pickups along the road, plus quiz questions that lock the rose gates
/// blocking the path. Story lessons additionally show a short passage before
/// play so the gate questions exercise reading retention.
library;

/// The flavour of practice a lesson focuses on. It changes how the lesson is
/// framed on the picker and title screens, not how the level generator works.
enum LessonKind {
  /// New vocabulary: the focus word plus meaning questions.
  vocabulary,

  /// Sight-word practice: recognising and spelling common words.
  sightWords,

  /// A short passage to read, with comprehension questions at the gates.
  story,
}

/// One multiple-choice question asked at a rose gate.
class QuizQuestion {
  const QuizQuestion({
    required this.prompt,
    required this.choices,
    required this.answerIndex,
  });

  final String prompt;
  final List<String> choices;
  final int answerIndex;

  String get answer => choices[answerIndex];
}

/// A focused set of goals the level generator builds a road around.
class Lesson {
  const Lesson({
    required this.kind,
    required this.title,
    required this.word,
    required this.intro,
    this.story,
    this.questions = const [],
  });

  final LessonKind kind;

  /// Shown on the lesson picker and the title card, e.g. `Enormous!`.
  final String title;

  /// The focus word, lowercase a-z only: its letters become pickups placed in
  /// reading order along the level.
  final String word;

  /// One or two friendly sentences framing the goal on the title card.
  final String intro;

  /// For [LessonKind.story]: the passage shown before play begins.
  final String? story;

  /// Asked at the rose gates, in order of appearance along the road.
  final List<QuizQuestion> questions;
}
