import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../providers/progress_provider.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final isWon = args?['isWon'] as bool? ?? false;
    final timeLeft = args?['timeLeft'] as int? ?? 0;
    final level = args?['level'] as int? ?? 1;

    final progressAsync = ref.watch(progressProvider);
    final maxUnlocked =
        progressAsync.maybeWhen(data: (p) => p.maxUnlockedLevel, orElse: () => 1);
    final nextLevel = level + 1;
    final canGoNext = isWon && nextLevel <= maxUnlocked;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Result icon
                Image.asset(
                  'assets/images/trump.png',
                  width: 100,
                  height: 100,
                ),
                const SizedBox(height: 24),
                // Title
                Text(
                  isWon ? '🎉 通关！' : '💔 游戏结束',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isWon ? const Color(0xFF27AE60) : const Color(0xFFE74C3C),
                  ),
                ),
                const SizedBox(height: 12),
                if (isWon)
                  Text(
                    '剩余时间：${_formatTime(timeLeft)}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                if (!isWon)
                  const Text(
                    '再试一次，你一定可以的！',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                const SizedBox(height: 48),
                // Retry button
                _ResultBtn(
                  label: '重新开始',
                  color: const Color(0xFF6EB8D4),
                  onTap: () {
                    ref.read(gameProvider.notifier).startLevel(level);
                    Navigator.pushReplacementNamed(context, '/game');
                  },
                ),
                const SizedBox(height: 16),
                // Next level button
                _ResultBtn(
                  label: canGoNext ? '下一关' : '下一关（未解锁）',
                  color: const Color(0xFF6EB8D4),
                  onTap: canGoNext
                      ? () {
                          ref.read(gameProvider.notifier).startLevel(nextLevel);
                          Navigator.pushReplacementNamed(context, '/game');
                        }
                      : null,
                ),
                const SizedBox(height: 16),
                // Back to home
                TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                  child: const Text(
                    '返回首页',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ResultBtn({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: onTap != null ? color : Colors.grey[300],
          borderRadius: BorderRadius.circular(26),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: onTap != null ? Colors.white : Colors.grey[500],
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
