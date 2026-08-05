# Princess Smash

A cute side-scrolling platformer built with [Flame](https://flame-engine.org)
and Flutter. Princess Pip took a wrong turn at the meadow; help her bounce her
way home, squashing friendly-looking blobs along the way.

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

Starting with `SPACE` carries the press through as Pip's first jump rather than
swallowing it, and a direction key still held when you restart keeps working.

Land on a blob from above to squash it. Touch one from the side and Pip loses a
heart. Fall in a pit and she loses a heart too, then reappears at the last spot
she was standing safely. Three hearts and it's back to the meadow.

## How it's put together

There are no image assets — every character, tile and cloud is drawn with
`Canvas` paths. That keeps the whole game in source form, makes the palette
swappable from one file, and lets the squash-and-stretch do the heavy lifting
on the "cute" front.

| File | Role |
| --- | --- |
| `lib/game/level.dart` | The level as an ASCII map, plus the tile grid |
| `lib/game/physics_entity.dart` | Gravity and swept AABB collision against tiles |
| `lib/game/princess.dart` | Run/jump feel and the princess drawing |
| `lib/game/enemy.dart` | Patrolling blobs, ledge detection, the stomp test |
| `lib/game/pickups.dart` | Gems and hearts |
| `lib/game/goal.dart` | The cottage at the end of the road |
| `lib/game/scenery.dart` | Sky, hills, clouds, and the tile renderer |
| `lib/game/hud.dart` | Hearts, gem tally, distance-home meter |
| `lib/game/princess_smash_game.dart` | Game loop, camera, collisions, state |
| `lib/ui/overlay_panel.dart` | Title / game over / victory cards |

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
