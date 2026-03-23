import '../models/cell.dart';
import 'level_config.dart';
import 'level1.dart';
import 'level2.dart';
import 'level3.dart';
import 'level4.dart';
import 'level5.dart';
import 'level6.dart';
import 'level7.dart';
import 'level8.dart';
import 'level9.dart';
import 'level10.dart';

// 关卡总表
const List<LevelConfig> kAllLevels = [
  level1Config,
  level2Config,
  level3Config,
  level4Config,
  level5Config,
  level6Config,
  level7Config,
  level8Config,
  level9Config,
  level10Config,
];

LevelConfig getLevelConfig(int id) {
  return kAllLevels.firstWhere((l) => l.id == id, orElse: () => level1Config);
}

List<List<Cell>> buildBoard(LevelConfig level) {
  // 由关卡自身通过 fixedHints 显式声明开局提示格
  final Set<(int, int)> given = {};
  for (final hint in level.fixedHints) {
    given.add(hint);
  }

  return List.generate(
    level.gridSize,
    (row) => List.generate(
      level.gridSize,
      (col) {
        final isGiven = given.contains((row, col));
        return Cell(
          row: row,
          col: col,
          region: level.regions[row][col],
          state: isGiven ? CellState.trump : CellState.empty,
          fixed: isGiven,
        );
      },
    ),
  );
}

// 全局基础配置（生命/时间等）
const int kInitialLives = 3;
const int kTimeLimitSeconds = 300;

