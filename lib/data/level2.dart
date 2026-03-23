import 'level_config.dart';

// Level 2 — 4x4 grid, based on the screenshot
const _level2Regions = [
  ['green',  'purple', 'pink', 'pink'],
  ['green',  'purple', 'pink', 'blue'],
  ['green',  'green',  'pink', 'pink'],
  ['green',  'green',  'pink', 'pink'],
];

const level2Config = LevelConfig(
  id: 2,
  gridSize: 4,
  trumpCount: 4,
  regions: _level2Regions,
  fixedHints: [
    (1, 3), // 额外送的提示 Trump
  ],
  solution: [
    (0, 1), // purple
    (1, 3), // blue
    (2, 0), // green
    (3, 2), // pink
  ],
);

