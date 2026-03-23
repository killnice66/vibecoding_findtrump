import '../models/cell.dart';

enum PlacementError {
  rowConflict,
  colConflict,
  regionConflict,
  adjacencyConflict,
}

class RuleEngine {
  /// Returns null if placement is valid, or a PlacementError if it violates a rule.
  /// Checks all other cells on the board (not (row,col) itself).
  static PlacementError? canPlaceTrump(
    int row,
    int col,
    List<List<Cell>> board,
  ) {
    final region = board[row][col].region;

    // Rule 2: each row has exactly 1 trump
    for (int c = 0; c < board[row].length; c++) {
      if (c != col && board[row][c].state == CellState.trump) {
        return PlacementError.rowConflict;
      }
    }

    // Rule 3: each column has exactly 1 trump
    for (int r = 0; r < board.length; r++) {
      if (r != row && board[r][col].state == CellState.trump) {
        return PlacementError.colConflict;
      }
    }

    // Rule 1: each region has exactly 1 trump
    for (int r = 0; r < board.length; r++) {
      for (int c = 0; c < board[r].length; c++) {
        if ((r != row || c != col) &&
            board[r][c].region == region &&
            board[r][c].state == CellState.trump) {
          return PlacementError.regionConflict;
        }
      }
    }

    // Rule 4: no adjacent trumps (8 directions)
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final nr = row + dr;
        final nc = col + dc;
        if (nr >= 0 &&
            nr < board.length &&
            nc >= 0 &&
            nc < board[nr].length &&
            board[nr][nc].state == CellState.trump) {
          return PlacementError.adjacencyConflict;
        }
      }
    }

    return null;
  }

  /// Returns true if all 6 trumps are placed and all rules are satisfied.
  static bool isWon(List<List<Cell>> board, int required) {
    final trumps =
        board.expand((r) => r).where((c) => c.state == CellState.trump).toList();
    if (trumps.length != required) return false;

    for (final cell in trumps) {
      if (canPlaceTrump(cell.row, cell.col, board) != null) return false;
    }
    return true;
  }

  static String errorMessage(PlacementError error) {
    switch (error) {
      case PlacementError.rowConflict:
        return '该行已有 Trump！';
      case PlacementError.colConflict:
        return '该列已有 Trump！';
      case PlacementError.regionConflict:
        return '该区域已有 Trump！';
      case PlacementError.adjacencyConflict:
        return 'Trump 不能相邻！';
    }
  }
}
