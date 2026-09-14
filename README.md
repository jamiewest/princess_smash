# Princess Smash

A cute side-scrolling platformer built with [Flame](https://flame-engine.org)
and Flutter. Princess Emery took a wrong turn at the meadow; help her bounce her
way home, squashing friendly-looking blobs along the way.

It's also a sneaky school helper: alongside the classic meadow, a level
generator builds fresh levels around 2nd-grade learning goals — vocabulary,
sight words, and reading retention.

## Make Your Hero

The hero card on the front screen opens a dress-up studio. Two quick picks sit
at the top — **Princess Emery** in her pink dress and her twin, **Prince
Milo**, in a cornflower-blue tunic — plus full control over skin, hair colour
and style, eyes, outfit and name.

The whole game dresses to match whoever is playing: floating platforms, the
cottage roof, the home meter, the menu cards and every storybook button re-dye
themselves to the hero's outfit colour (the darker trims and lighter tints are
derived automatically, so any pastel keeps the two-tone look). The story text
follows too — "Poor Prince Milo took a wrong turn at the meadow. Help him
bounce his way home!" — and the title itself becomes *Prince Smash* or *Royal
Smash* to suit.

## Learning mode

The front screen offers **Free Play** (the original hand-made meadow) plus
three kinds of generated lessons:

* **Word Builder** — a big new word ("enormous") is the focus. Its letters are
  scattered along the road in reading order; catching one pauses play and the
  letter must be dragged into the right box of the word tracker at the top of
  the screen. Rose gates block the path and ask what the word means.
* **Sight Words** — the same, for Dolch-list words like *because* and
  *always*, with spot-the-spelling questions at the gates.
* **Story Time** — a four-sentence story is read on the title card, and the
  gate questions check what she remembers from it.

A rose gate physically blocks the road (it's far too tall to jump, even off a
bouncing enemy). Reaching it pauses play and pops a storybook question card
with shuffled answers; a wrong pick just disables that answer with a gentle
"try another one", so it's always solvable. Placing a caught letter works the
same way: a wrong box just wiggles and floats the letter back for another try.
Missed letters aren't punished — the victory card totals them up and nudges a
replay.

Every visit to a lesson generates a fresh road (new seed) around the same
goals, so replays stay interesting.

### Adding your own lessons

All content lives in `lib/game/education/curriculum.dart` as plain Dart lists —
no game knowledge needed. A lesson is a focus word (lowercase a–z, 3–12
letters), an intro or story, and a few multiple-choice questions. The tests in
`test/curriculum_test.dart` check any new content is well formed, and
`test/level_generator_test.dart` proves a playable level can be generated from
it (pits jumpable, letters reachable, one gate per question).

## Playing

```bash
flutter run -d chrome
```

Also runs on macOS with `flutter run -d macos`.

| Key | Action |
| --- | --- |
| `←` / `→` or `A` / `D` | Walk |
| `SPACE`, `↑`, `W` or `Z` | Jump (hold for a higher jump) |
| `SPACE` / `ENTER` | Start or restart from a menu |

Starting with `SPACE` carries the press through as Emery's first jump rather than
swallowing it, and a direction key still held when you restart keeps working.

Land on a blob from above to squash it. Touch one from the side and Emery loses a
heart. Fall in a pit and she loses a heart too, then reappears at the last spot
she was standing safely. Three hearts and it's back to the meadow.

## How it's put together

There are no image assets — every character, tile and cloud is drawn with
`Canvas` paths. That keeps the whole game in source form, makes the palette
swappable from one file, and lets the squash-and-stretch do the heavy lifting
on the "cute" front.

| File | Role |
| --- | --- |
| `lib/game/level.dart` | Levels as ASCII maps, plus the tile grid |
| `lib/game/level_generator.dart` | Builds a level around a lesson's goals |
| `lib/game/education/lesson.dart` | Lesson and quiz-question models |
| `lib/game/education/curriculum.dart` | The built-in 2nd-grade content |
| `lib/game/physics_entity.dart` | Gravity and swept AABB collision against tiles |
| `lib/game/appearance.dart` | The hero's look, the two presets, and the matching world colours |
| `lib/game/hero_painter.dart` | Draws the hero — shared by the game sprite and the maker preview |
| `lib/game/princess.dart` | Run/jump feel and the player sprite |
| `lib/game/enemy.dart` | Patrolling blobs, ledge detection, the stomp test |
| `lib/game/pickups.dart` | Gems, hearts and word letters |
| `lib/game/letter_drop.dart` | The drag-the-letter-into-its-box mini-game |
| `lib/game/quiz_gate.dart` | The rose gate a question unlocks |
| `lib/game/goal.dart` | The cottage at the end of the road |
| `lib/game/scenery.dart` | Sky, hills, clouds, and the tile renderer |
| `lib/game/hud.dart` | Hearts, gems, word tracker, distance-home meter |
| `lib/game/princess_smash_game.dart` | Game loop, camera, collisions, state |
| `lib/ui/hero_maker.dart` | The "Make Your Hero" dress-up screen |
| `lib/ui/overlay_panel.dart` | Title / game over / victory cards |
| `lib/ui/quiz_panel.dart` | The rose gate's question card |
| `lib/main.dart` | Lesson picker and screen wiring |

### Editing the level

`kLevelRows` in `lib/game/level.dart` is a 100 × 14 character map:

```
.  empty air          *  gem
=  floating platform  H  heart pickup
P  princess spawn     D  the door home
E  walking blob       F  hopping blob
```

The two solid ground layers are generated from `kGroundSpans` rather than typed
out, so the gaps between spans are the pits. Every row must stay exactly 100
characters — there's a test for that.

### Feel

The jump is tuned so a single jump clears three tiles: platforms sit exactly one
jump apart, so the high routes are reachable but need a step in between. Coyote
time, jump buffering and variable jump height all live in `Princess`; the stomp
bounce is higher while jump is held, which is most of what makes squashing a
blob satisfying.

Collision is resolved by hand against the tile grid rather than through Flame's
collision callbacks, so stomp resolution is deterministic within a frame.
Movement is sub-stepped to at most half a tile per step, which means a stalled
frame — a backgrounded browser tab handing back a nine-second `dt` — can't
tunnel anyone through the floor.

## Tests

```bash
flutter test
```

Covers the map's integrity (row widths, nothing spawned over a pit), the
collision solver (resting, tunnelling, walls, the kill plane) and the feel
(stomp detection at any frame rate, coyote time, jump buffering, variable jump
height, respawn).

Generated levels get the same treatment across every lesson and several seeds:
the focus word is spelled in reading order, each question gets exactly one
gate, gates are unjumpable but grounded, letters always hover over somewhere
to stand, every pit is clearable with a running jump (simulated with the real
physics), and generation is deterministic per seed. `curriculum_test.dart`
keeps the authored content well formed.
