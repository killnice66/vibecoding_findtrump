import 'level_config.dart';


// Level 3 — 6x6 grid, based on the screenshot
const _level3Regions = [
  ['cyan',      'lightBlue', 'lightBlue', 'purple', 'purple', 'purple'],
  ['cyan',      'cyan',      'cyan',      'purple', 'purple', 'amber'],
  ['cyan',      'cyan',      'cyan',      'purple', 'purple', 'yellow'],
  ['cyan',      'cyan',      'cyan',      'cyan',   'cyan',   'yellow'],
  ['cyan',      'cyan',      'pink',      'pink',   'pink',   'yellow'],
  ['cyan',      'cyan',      'pink',      'pink',   'yellow', 'yellow'],
];

const level3Config = LevelConfig(
  id: 3,
  gridSize: 6,
  trumpCount: 6,
  regions: _level3Regions,
  fixedHints: [
    (1, 5), // 额外送的提示 Trump
  ],
  solution: [
    (0, 1), // lightBlue
    (1, 5), // amber（单格区域，开局直接确定）
    (2, 3), // purple
    (3, 0), // cyan
    (4, 2), // pink
    (5, 4), // yellow
  ],
);