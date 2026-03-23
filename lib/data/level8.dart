import 'level_config.dart';

// Level 8 — 6x6 grid, medium difficulty

const _level8Regions = [
  ['blue',   'blue',   'purple', 'purple', 'pink',   'pink'],
  ['blue',   'blue',   'purple', 'purple', 'pink',   'pink'],
  ['blue',   'blue',   'purple', 'purple', 'pink',   'pink'],
  ['blue',   'blue',   'yellow', 'pink',   'pink',   'pink'],
  ['teal',   'teal',   'teal',   'teal',   'teal',   'pink'],
  ['amber',  'teal',   'teal',   'teal',   'teal',   'teal'],
];

const level8Config = LevelConfig(
  id: 8,
  gridSize: 6,
  trumpCount: 6,

  regions: _level8Regions,
  fixedHints: [
    (3, 2), // 额外送的提示 Trump
  ],
  solution: [
    (0,1), // blue
    (1,3), // purple
    (2,5), // pink
    (3,2), // yellow
    (4,4), // teal
    (5,0), // amber
  ],
);