import 'level_config.dart';


// Level 4 — 6x6 grid, based on the screenshot
const _level4Regions = [
  ['blue', 'red', 'red',  'green', 'green', 'green'],
  ['blue', 'red', 'red',  'green', 'green', 'yellow'],
  ['blue', 'blue', 'cyan',  'green', 'green', 'yellow'],
  ['blue', 'green','green', 'green', 'yellow','yellow'],
  ['pink', 'pink', 'green', 'green', 'green', 'yellow'],
  ['pink', 'pink', 'pink',  'pink',  'yellow','yellow'],
];

const level4Config = LevelConfig(
  id: 4,
  gridSize: 6,
  trumpCount: 6,
  regions: _level4Regions,
  fixedHints: [
    (2, 2), // 额外送的提示 Trump
  ],
  solution: [
    (0, 1), // red
    (1, 4), // green
    (2, 2), // cyan（单格区域）
    (3, 0), // blue
    (4, 5), // yellow
    (5, 3), // pink（下方粉色区域中的唯一解位置）
  ],
);