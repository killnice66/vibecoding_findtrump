import 'level_config.dart';


// Level 5 — 6x6 grid, beginner-friendly
const _level5Regions = [
  ['pink',   'pink',   'blue',   'blue',   'blue',   'blue'],
  ['pink',   'pink',   'pink',   'blue',   'blue',   'blue'],
  ['pink',   'pink',   'pink',   'green',  'blue',   'blue'],
  ['yellow', 'pink',   'pink',   'green',  'green',  'cyan'],
  ['yellow', 'yellow', 'yellow', 'green',  'green',  'green'],
  ['yellow', 'yellow', 'indigo', 'green',  'green',  'green'],
];

const level5Config = LevelConfig(
  id: 5,
  gridSize: 6,
  trumpCount: 6,
  regions: _level5Regions,
  fixedHints: [
    (3, 5), // 额外送的提示 Trump
  ],
  solution: [
    (0, 4), // blue
    (1, 1), // pink
    (2, 3), // green
    (3, 5), // cyan（单格）
    (4, 0), // yellow
    (5, 2), // indigo（单格）
  ],
);

