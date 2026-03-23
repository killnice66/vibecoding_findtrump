import 'level_config.dart';

// Level 6 — 6x6 grid, clean playable version
const _level6Regions = [
  ['lime', 'lime', 'lime', 'lime', 'yellow', 'yellow'],
  ['lime', 'lime', 'lime', 'lime', 'yellow', 'yellow'],
  ['lime', 'lime', 'lime', 'pink',  'lightBlue', 'yellow'],
  ['lime', 'lime',  'cyan',  'pink',  'lightBlue',   'lightBlue'],
  ['blue',   'pink',   'pink',   'pink',   'lightBlue',  'lightBlue'],
  ['blue',   'blue',   'blue',   'pink',   'lightBlue',   'lightBlue'],
];

const level6Config = LevelConfig(
  id: 6,
  gridSize: 6,
  trumpCount: 6,
  regions: _level6Regions,
  fixedHints: [
    (3, 2), // 额外送的提示 Trump
  ],
  solution: [
    (0, 5), // yellow
    (1, 1), // lime
    (5, 3), // pink
    (3, 2), // cyan
    (4, 0), // blue
    (2, 4), // lightBlue
  ],
);

