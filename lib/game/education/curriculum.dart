/// Built-in 2nd-grade lessons. Content lives here — away from any game or
/// generator code — so a grown-up can add words, questions and stories by
/// editing plain lists.
///
/// Authoring notes:
///  * Focus words must be lowercase a-z (they become in-level letter pickups).
///  * `answerIndex` points into `choices`; the quiz card shuffles the order
///    shown on screen, so authoring the answer first is fine.
///  * Keep prompts short and concrete — they are read by a 2nd grader.
library;

import 'lesson.dart';

/// Every built-in lesson, in picker order.
const List<Lesson> kCurriculum = [
  // ── Word Builder: new vocabulary ────────────────────────────────────────
  Lesson(
    kind: LessonKind.vocabulary,
    title: 'Enormous!',
    word: 'enormous',
    intro:
        'Today\'s big word is ENORMOUS — it means very, very big.\n'
        'Collect the letters along the road to spell it!',
    questions: [
      QuizQuestion(
        prompt: 'Which word means very, very big?',
        choices: ['enormous', 'tiny', 'sleepy'],
        answerIndex: 0,
      ),
      QuizQuestion(
        prompt: 'The whale was so big it was ___.',
        choices: ['enormous', 'quiet', 'cold'],
        answerIndex: 0,
      ),
      QuizQuestion(
        prompt: 'Which of these is enormous?',
        choices: ['a mountain', 'an ant', 'a button'],
        answerIndex: 0,
      ),
    ],
  ),
  Lesson(
    kind: LessonKind.vocabulary,
    title: 'Curious!',
    word: 'curious',
    intro:
        'Today\'s big word is CURIOUS — wanting to find out about things.\n'
        'Collect the letters along the road to spell it!',
    questions: [
      QuizQuestion(
        prompt: 'Which word means wanting to know more?',
        choices: ['curious', 'tired', 'loud'],
        answerIndex: 0,
      ),
      QuizQuestion(
        prompt: 'A curious kid asks lots of ___.',
        choices: ['questions', 'naps', 'shoes'],
        answerIndex: 0,
      ),
      QuizQuestion(
        prompt: 'Curious means you want to ___ about things.',
        choices: ['learn', 'forget', 'complain'],
        answerIndex: 0,
      ),
    ],
  ),
  Lesson(
    kind: LessonKind.vocabulary,
    title: 'Gentle!',
    word: 'gentle',
    intro:
        'Today\'s big word is GENTLE — soft, careful and kind.\n'
        'Collect the letters along the road to spell it!',
    questions: [
      QuizQuestion(
        prompt: 'Which word means soft and kind?',
        choices: ['gentle', 'rough', 'speedy'],
        answerIndex: 0,
      ),
      QuizQuestion(
        prompt: 'Be ___ when you hold a baby chick.',
        choices: ['gentle', 'loud', 'bouncy'],
        answerIndex: 0,
      ),
      QuizQuestion(
        prompt: 'A gentle breeze feels ___.',
        choices: ['soft', 'stormy', 'icy'],
        answerIndex: 0,
      ),
    ],
  ),

  // ── Sight Words ─────────────────────────────────────────────────────────
  Lesson(
    kind: LessonKind.sightWords,
    title: 'Because',
    word: 'because',
    intro:
        'Practice the sight word BECAUSE.\n'
        'Collect its letters in order along the road!',
    questions: [
      QuizQuestion(
        prompt: 'Which one is spelled right?',
        choices: ['because', 'becuase', 'becose'],
        answerIndex: 0,
      ),
      QuizQuestion(
        prompt: 'I wear my coat ___ it is cold outside.',
        choices: ['because', 'banana', 'blue'],
        answerIndex: 0,
      ),
    ],
  ),
  Lesson(
    kind: LessonKind.sightWords,
    title: 'Always',
    word: 'always',
    intro:
        'Practice the sight word ALWAYS.\n'
        'Collect its letters in order along the road!',
    questions: [
      QuizQuestion(
        prompt: 'Which one says "always"?',
        choices: ['always', 'away', 'almost'],
        answerIndex: 0,
      ),
      QuizQuestion(
        prompt: 'Emery ___ brushes her teeth at night.',
        choices: ['always', 'apple', 'angry'],
        answerIndex: 0,
      ),
    ],
  ),
  Lesson(
    kind: LessonKind.sightWords,
    title: 'Write',
    word: 'write',
    intro:
        'Practice the sight word WRITE.\n'
        'Collect its letters in order along the road!',
    questions: [
      QuizQuestion(
        prompt: 'Which word is "write"?',
        choices: ['write', 'white', 'wrote'],
        answerIndex: 0,
      ),
      QuizQuestion(
        prompt: 'I ___ my name at the top of my paper.',
        choices: ['write', 'run', 'sing'],
        answerIndex: 0,
      ),
    ],
  ),

  // ── Story Time: read, then remember ─────────────────────────────────────
  Lesson(
    kind: LessonKind.story,
    title: 'The Lost Kitten',
    word: 'kitten',
    intro: 'Read the story, then answer the gate questions along the road.',
    story:
        'Milo the kitten chased a red leaf into the tall grass. '
        'Soon he could not see his house anywhere. '
        'A girl named Ruby heard him mew and followed the sound. '
        'She scooped Milo up and carried him home for supper.',
    questions: [
      QuizQuestion(
        prompt: 'What was Milo chasing?',
        choices: ['a red leaf', 'a blue ball', 'a mouse'],
        answerIndex: 0,
      ),
      QuizQuestion(
        prompt: 'Where did Milo get lost?',
        choices: ['in the tall grass', 'at school', 'on a boat'],
        answerIndex: 0,
      ),
      QuizQuestion(
        prompt: 'Who carried Milo home?',
        choices: ['Ruby', 'a dog', 'his grandpa'],
        answerIndex: 0,
      ),
    ],
  ),
  Lesson(
    kind: LessonKind.story,
    title: 'The Tiny Seed',
    word: 'garden',
    intro: 'Read the story, then answer the gate questions along the road.',
    story:
        'Ben planted a tiny seed in his garden. '
        'He watered it every single day. '
        'One sunny morning a green sprout poked out of the dirt. '
        'By summer it had grown into a sunflower taller than Ben!',
    questions: [
      QuizQuestion(
        prompt: 'What did Ben plant?',
        choices: ['a tiny seed', 'a rock', 'a coin'],
        answerIndex: 0,
      ),
      QuizQuestion(
        prompt: 'What did Ben do every day?',
        choices: ['watered the seed', 'sang songs', 'built a fence'],
        answerIndex: 0,
      ),
      QuizQuestion(
        prompt: 'What did the seed grow into?',
        choices: ['a sunflower', 'an oak tree', 'a pumpkin'],
        answerIndex: 0,
      ),
    ],
  ),
  Lesson(
    kind: LessonKind.story,
    title: "Luna's Big Jump",
    word: 'brave',
    intro: 'Read the story, then answer the gate questions along the road.',
    story:
        'Luna the frog was scared of the high rock over the pond. '
        'Her friends cheered, "You can do it, Luna!" '
        'Luna took a deep breath and leapt off with a great splash. '
        'When she popped back up, she felt brave and proud.',
    questions: [
      QuizQuestion(
        prompt: 'What was Luna scared of?',
        choices: ['the high rock', 'the dark', 'a bee'],
        answerIndex: 0,
      ),
      QuizQuestion(
        prompt: 'Who cheered for Luna?',
        choices: ['her friends', 'her teacher', 'a duck'],
        answerIndex: 0,
      ),
      QuizQuestion(
        prompt: 'How did Luna feel at the end?',
        choices: ['brave and proud', 'grumpy', 'sleepy'],
        answerIndex: 0,
      ),
    ],
  ),
];
