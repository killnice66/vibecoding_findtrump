import 'level_config.dart';

// Level 7 — 6x6 grid, medium difficulty
const _level7Regions = [
  ['blue',   'blue',   'blue',  'green',  'green',  'green'],
  ['blue',   'blue',   'blue',  'indigo', 'green',  'green'],
  ['blue',   'blue',   'blue',  'blue',   'purple', 'purple'],
  ['blue',   'blue',   'blue',  'blue',   'purple', 'purple'],
  ['red',    'red',    'red',   'red',    'purple', 'purple'],
  ['pink',   'red',    'red',   'red',    'purple', 'purple'],
];

const level7Config = LevelConfig(
  id: 7,
  gridSize: 6,
  trumpCount: 6,
  regions: _level7Regions,
  fixedHints: [
    (1, 3), // 额外送的提示 Trump
  ],
  solution: [
    (0, 5), // green
    (1, 3), // indigo
    (2, 1), // pink
    (3, 4), // purple
    (4, 2), // red
    (5, 0), // pink
  ],
);

