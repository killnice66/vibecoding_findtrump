import 'level_config.dart';

// Level 10 — 8x8 grid

const _level10Regions = [
  ['red','cyan','cyan','cyan','cyan','purple','purple','purple'],
  ['red','cyan','cyan','cyan','cyan','cyan','cyan','cyan'],
  ['red','cyan','cyan','teal','cyan','cyan','cyan','cyan'],
  ['cyan','cyan','cyan','teal','teal','teal','cyan','cyan'],
  ['cyan','cyan','cyan','pink','pink','teal','cyan','cyan'],
  ['cyan','pink','pink','pink','blue','blue','cyan','yellow'],
  ['cyan','cyan','cyan','cyan','cyan','blue','cyan','yellow'],
  ['green','green','green','cyan','blue','blue','cyan','yellow'],
];

const level10Config = LevelConfig(
  id: 10,
  gridSize: 8,
  trumpCount: 8,
  regions: _level10Regions,
  fixedHints: [
    (6, 5), // 额外送的提示 Trump
  ],
  solution: [
    (0,6),
    (1,0),
    (2,3),
    (3,1),
    (4,4),
    (5,7),
    (6,5),
    (7,2),
  ],
);