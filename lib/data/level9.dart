import 'level_config.dart';

// Level 9 — 6x6 grid

const _level9Regions = [
  ['blue',   'blue',   'blue',   'cyan',   'cyan',   'cyan'],
  ['blue',   'blue',   'green',  'purple', 'purple', 'cyan'],
  ['blue',   'blue',   'blue',   'purple', 'purple', 'cyan'],
  ['yellow', 'blue',   'pink',   'pink',   'pink',   'pink'],
  ['yellow', 'yellow', 'yellow', 'pink',   'pink',   'pink'],
  ['yellow', 'yellow', 'yellow', 'pink',   'pink',   'pink'],
];

const level9Config = LevelConfig(
  id: 9,
  gridSize: 6,
  trumpCount: 6,

  regions: _level9Regions,
  fixedHints: [
    (1,2),
  ],
  solution: [
    (0,5),
    (1,2),
    (2,4),
    (3,1),
    (4,3),
    (5,0),
  ],
);