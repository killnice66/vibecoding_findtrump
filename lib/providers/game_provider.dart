import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cell.dart';
import '../data/level_data.dart';
import '../logic/rule_engine.dart';

class GameState {
  final List<List<Cell>> board;
  final int lives;
  final int timeLeft;
  final bool isWon;
  final bool isLost;
  final bool showCoordinates;
  final bool bgmEnabled;
  final double bgmVolume; // 0.0 ~ 1.0, default 0.1 (slider 1格)
  final bool? lastPlacementCorrect; // true=correct, false=wrong
  final int placementEventId; // increments every placement, forces listener to fire
  final int? errorRow;
  final int? errorCol;
  final String? errorMessage;
  final int hintsLeft; // max 2 per game
  final int level; // 当前关卡编号
  final int requiredTrumps; // 本关需要放置的 trump 数量
  final List<(int, int)> solution; // 本关正确解坐标列表

  const GameState({
    required this.board,
    this.lives = kInitialLives,
    this.timeLeft = kTimeLimitSeconds,
    this.isWon = false,
    this.isLost = false,
    this.showCoordinates = false,
    this.bgmEnabled = true,
    this.bgmVolume = 0.05,
    this.lastPlacementCorrect,
    this.placementEventId = 0,
    this.errorRow,
    this.errorCol,
    this.errorMessage,
    this.hintsLeft = 2,
    this.level = 1,
    required this.requiredTrumps,
    required this.solution,
  });

  int get trumpCount =>
      board.expand((r) => r).where((c) => c.state == CellState.trump).length;

  int get remainingTrumps => requiredTrumps - trumpCount;

  GameState copyWith({
    List<List<Cell>>? board,
    int? lives,
    int? timeLeft,
    bool? isWon,
    bool? isLost,
    bool? showCoordinates,
    bool? bgmEnabled,
    double? bgmVolume,
    bool? lastPlacementCorrect,
    int? placementEventId,
    int? errorRow,
    int? errorCol,
    String? errorMessage,
    bool clearError = false,
    int? hintsLeft,
    int? level,
    int? requiredTrumps,
    List<(int, int)>? solution,
  }) {
    return GameState(
      board: board ?? this.board,
      lives: lives ?? this.lives,
      timeLeft: timeLeft ?? this.timeLeft,
      isWon: isWon ?? this.isWon,
      isLost: isLost ?? this.isLost,
      showCoordinates: showCoordinates ?? this.showCoordinates,
      bgmEnabled: bgmEnabled ?? this.bgmEnabled,
      bgmVolume: bgmVolume ?? this.bgmVolume,
      lastPlacementCorrect: lastPlacementCorrect ?? this.lastPlacementCorrect,
      placementEventId: placementEventId ?? this.placementEventId,
      errorRow: clearError ? null : (errorRow ?? this.errorRow),
      errorCol: clearError ? null : (errorCol ?? this.errorCol),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hintsLeft: hintsLeft ?? this.hintsLeft,
      level: level ?? this.level,
      requiredTrumps: requiredTrumps ?? this.requiredTrumps,
      solution: solution ?? this.solution,
    );
  }
}

class GameNotifier extends Notifier<GameState> {
  Timer? _timer;

  @override
  GameState build() {
    ref.onDispose(() => _timer?.cancel());
    final level = getLevelConfig(1);
    _startTimer();
    return GameState(
      board: buildBoard(level),
      level: level.id,
      requiredTrumps: level.trumpCount,
      solution: level.solution,
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isWon || state.isLost) {
        _timer?.cancel();
        return;
      }
      final newTime = state.timeLeft - 1;
      if (newTime <= 0) {
        state = state.copyWith(timeLeft: 0, isLost: true);
        _timer?.cancel();
      } else {
        state = state.copyWith(timeLeft: newTime);
      }
    });
  }

  // Single tap: cycle empty ↔ mark
  void tapCell(int row, int col) {
    if (state.isWon || state.isLost) return;
    final cell = state.board[row][col];
    if (cell.fixed) return;
    if (cell.state == CellState.trump) return;
    final next = cell.state == CellState.empty ? CellState.mark : CellState.empty;
    _updateCell(row, col, next);
  }

  // Double tap: place trump — must match fixed solution, otherwise lose a life
  void doubleTapCell(int row, int col) {
    if (state.isWon || state.isLost) return;
    final cell = state.board[row][col];

    if (cell.state == CellState.trump) {
      if (cell.fixed) return;
      _updateCell(row, col, CellState.empty);
      return;
    }

    final inSolution =
        state.solution.any((pos) => pos.$1 == row && pos.$2 == col);
    if (!inSolution) {
      final newLives = state.lives - 1;
      state = state.copyWith(
        lives: newLives,
        errorRow: row,
        errorCol: col,
        errorMessage: '位置不对，再想想！',
        isLost: newLives <= 0,
        lastPlacementCorrect: false,
        placementEventId: state.placementEventId + 1,
      );
      Future.delayed(const Duration(milliseconds: 900), () {
        state = state.copyWith(clearError: true);
      });
      return;
    }

    _updateCell(row, col, CellState.trump);
    state = state.copyWith(
      lastPlacementCorrect: true,
      placementEventId: state.placementEventId + 1,
    );

    if (RuleEngine.isWon(state.board, state.requiredTrumps)) {
      _timer?.cancel();
      state = state.copyWith(isWon: true);
    }
  }

  // Bottom-bar clear: remove trump or mark from a specific cell
  void clearCell(int row, int col) {
    if (state.isWon || state.isLost) return;
    _updateCell(row, col, CellState.empty);
  }

  // Hint: place the next unplaced solution trump (does not remove existing placements)
  void useHint() {
    if (state.isWon || state.isLost) return;
    if (state.hintsLeft <= 0) return;

    for (final pos in state.solution) {
      final (r, c) = pos;
      if (state.board[r][c].state != CellState.trump) {
        _updateCell(r, c, CellState.trump);
        state = state.copyWith(hintsLeft: state.hintsLeft - 1);
        if (RuleEngine.isWon(state.board, state.requiredTrumps)) {
          _timer?.cancel();
          state = state.copyWith(isWon: true);
        }
        return;
      }
    }
  }

  // Clear all X marks from the board
  void clearAllMarks() {
    if (state.isWon || state.isLost) return;
    final newBoard = _copyBoard(state.board);
    for (int r = 0; r < newBoard.length; r++) {
      for (int c = 0; c < newBoard[r].length; c++) {
        if (newBoard[r][c].state == CellState.mark) {
          newBoard[r][c] = newBoard[r][c].copyWith(state: CellState.empty);
        }
      }
    }
    state = state.copyWith(board: newBoard);
  }

  // Drag over empty cell → mark it (no unmark, no rule check)
  void dragMarkCell(int row, int col) {
    if (state.isWon || state.isLost) return;
    if (state.board[row][col].state == CellState.empty) {
      _updateCell(row, col, CellState.mark);
    }
  }

  void toggleCoordinates() {
    state = state.copyWith(showCoordinates: !state.showCoordinates);
  }

  void toggleBgm() {
    state = state.copyWith(bgmEnabled: !state.bgmEnabled);
  }

  void setBgmVolume(double volume) {
    state = state.copyWith(bgmVolume: volume.clamp(0.0, 1.0));
  }

  void resetGame() {
    startLevel(state.level);
  }

  // 切换到指定关卡（从首页或结算页进入）
  void startLevel(int levelId) {
    _timer?.cancel();
    final keepBgm = state.bgmEnabled;
    final keepVol = state.bgmVolume;
    final level = getLevelConfig(levelId);
    state = GameState(
      board: buildBoard(level),
      bgmEnabled: keepBgm,
      bgmVolume: keepVol,
      level: level.id,
      requiredTrumps: level.trumpCount,
      solution: level.solution,
    );
    _startTimer();
  }

  void _updateCell(int row, int col, CellState newState) {
    final newBoard = _copyBoard(state.board);
    newBoard[row][col] = newBoard[row][col].copyWith(state: newState);
    state = state.copyWith(board: newBoard);
  }

  List<List<Cell>> _copyBoard(List<List<Cell>> board) {
    return List.generate(
      board.length,
      (r) => List.generate(board[r].length, (c) => board[r][c]),
    );
  }
}

final gameProvider = NotifierProvider<GameNotifier, GameState>(GameNotifier.new);
