import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 负责记录玩家最高解锁到第几关（持久化到本地）。
class ProgressState {
  final int maxUnlockedLevel;

  const ProgressState({required this.maxUnlockedLevel});

  ProgressState copyWith({int? maxUnlockedLevel}) =>
      ProgressState(maxUnlockedLevel: maxUnlockedLevel ?? this.maxUnlockedLevel);
}

class ProgressNotifier extends AsyncNotifier<ProgressState> {
  static const _prefsKey = 'max_unlocked_level';

  @override
  Future<ProgressState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_prefsKey);
    // 至少解锁第 1 关
    final maxLevel = (stored ?? 1).clamp(1, 999);
    return ProgressState(maxUnlockedLevel: maxLevel);
  }

  Future<void> _save(int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, level);
  }

  /// 当某一关通关时调用，自动解锁下一关。
  Future<void> levelCompleted(int levelId) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final next = levelId + 1;
    if (next <= current.maxUnlockedLevel) return;
    final newState = current.copyWith(maxUnlockedLevel: next);
    state = AsyncData(newState);
    await _save(newState.maxUnlockedLevel);
  }
}

final progressProvider =
    AsyncNotifierProvider<ProgressNotifier, ProgressState>(ProgressNotifier.new);

