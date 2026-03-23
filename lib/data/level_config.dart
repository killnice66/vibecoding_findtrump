typedef Coord = (int, int);

/// 单个关卡配置
class LevelConfig {
  final int id;
  final int gridSize;
  final int trumpCount;
  final List<List<String>> regions;
  final List<Coord> solution; // 正确 trump 坐标列表
  final List<Coord> fixedHints; // 开局就固定展示的 Trump 坐标

  const LevelConfig({
    required this.id,
    required this.gridSize,
    required this.trumpCount,
    required this.regions,
    required this.solution,
    this.fixedHints = const [],
  });
}

