import 'level_config.dart';

// Level 1 — 4x4 grid, 4 regions（原始示例关卡）
const _level1Regions = [
  ['blue', 'blue', 'blue', 'green'],
  ['red', 'blue', 'green', 'green'],
  ['yellow', 'yellow', 'green', 'green'],
  ['yellow', 'yellow', 'yellow', 'yellow'],
];

const level1Config = LevelConfig(
  id: 1,
  gridSize: 4,
  trumpCount: 4,
  regions: _level1Regions,
  fixedHints: [
    (1, 0), // 额外送的提示 Trump
  ],
  solution: [
    (0, 2), // blue
    (1, 0), // red
    (2, 3), // green
    (3, 1), // yellow
  ],
);


