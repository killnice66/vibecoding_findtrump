enum CellState { empty, mark, trump }

class Cell {
  final int row;
  final int col;
  final String region;
  final CellState state;
  final bool fixed; // 开局给定的 Trump（新手提示），不可被操作移除/覆盖

  const Cell({
    required this.row,
    required this.col,
    required this.region,
    this.state = CellState.empty,
    this.fixed = false,
  });

  Cell copyWith({CellState? state, bool? fixed}) => Cell(
        row: row,
        col: col,
        region: region,
        state: state ?? this.state,
        fixed: fixed ?? this.fixed,
      );
}
