import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import '../providers/game_provider.dart';
import '../providers/progress_provider.dart';
import '../widgets/grid_cell_widget.dart';
import '../data/level_data.dart';

// 所有可用关卡 BGM
const _gameBgmList = [
  'audio/bgm1_havana.wav',
  'audio/bgm2.mp4',
];

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

const _rightSfx = [
  'audio/right/huge_win.mp3',
  'audio/right/you_found_me.mp3',
  'audio/right/good2.wav',
  'audio/right/tremendous.mp3',
  'audio/right/unbelievable.wav',
];

const _wrongSfx = [
  'audio/wrong/fake_pick.mp3',
  'audio/wrong/not_me.mp3',
  'audio/wrong/wrong.mp3',
  'audio/wrong/aoh.wav',
];

class _GameScreenState extends ConsumerState<GameScreen> {
  final AudioPlayer _bgmPlayer = AudioPlayer();
  // 音效池：每个文件预加载一个 player，播放时直接 seek(0)+resume，消除延迟
  final Map<String, AudioPlayer> _sfxPool = {};
  bool _bgmStarted = false;

  static const double _sfxVolume = 1.0;

  @override
  void initState() {
    super.initState();
    _preloadSfx();
    if (!kIsWeb) _playRandomBgm();
  }

  Future<void> _preloadSfx() async {
    for (final path in [..._rightSfx, ..._wrongSfx]) {
      final player = AudioPlayer();
      await player.setVolume(_sfxVolume);
      await player.setSource(AssetSource(path));
      _sfxPool[path] = player;
    }
  }

  Future<void> _playRandomBgm() async {
    final gs = ref.read(gameProvider);
    if (!gs.bgmEnabled) return;
    _bgmStarted = true;
    final bgm = _gameBgmList[Random().nextInt(_gameBgmList.length)];
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.setVolume(gs.bgmVolume);
    await _bgmPlayer.play(AssetSource(bgm));
  }

  Future<void> _playSfx(String path) async {
    final player = _sfxPool[path];
    if (player == null) return;
    await player.seek(Duration.zero);
    await player.resume();
  }

  @override
  void dispose() {
    _bgmPlayer.dispose();
    for (final p in _sfxPool.values) {
      p.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    // Listen for win/lose to navigate to result screen
    ref.listen<GameState>(gameProvider, (prev, next) {
      // Sound effects — use placementEventId so consecutive same-result events still fire
      if (prev != null && next.placementEventId != prev.placementEventId) {
        if (next.lastPlacementCorrect == true) {
          _playSfx(_rightSfx[Random().nextInt(_rightSfx.length)]);
        } else if (next.lastPlacementCorrect == false) {
          _playSfx(_wrongSfx[Random().nextInt(_wrongSfx.length)]);
        }
      }
      // BGM toggle
      if (prev != null && prev.bgmEnabled != next.bgmEnabled) {
        if (next.bgmEnabled) {
          _playRandomBgm();
        } else {
          _bgmPlayer.stop();
        }
      }
      // BGM volume change
      if (prev != null && prev.bgmVolume != next.bgmVolume) {
        _bgmPlayer.setVolume(next.bgmVolume);
      }
      // Win / lose
      if ((next.isWon || next.isLost) &&
          prev != null &&
          !prev.isWon &&
          !prev.isLost) {
        _bgmPlayer.stop();
        if (next.isWon) {
          // 通关后记录进度，解锁下一关，等保存完再跳转
          ref.read(progressProvider.notifier).levelCompleted(next.level).then((_) {
            if (context.mounted) {
              Navigator.pushReplacementNamed(
                context,
                '/result',
                arguments: {
                  'isWon': next.isWon,
                  'timeLeft': next.timeLeft,
                  'level': next.level,
                },
              );
            }
          });
        } else {
          Navigator.pushReplacementNamed(
            context,
            '/result',
            arguments: {
              'isWon': next.isWon,
              'timeLeft': next.timeLeft,
              'level': next.level,
            },
          );
        }
      }
    });

    final gameState = ref.watch(gameProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () { if (!_bgmStarted) _playRandomBgm(); },
        child: SafeArea(
        child: Column(
          children: [
            _TopBar(
              gameState: gameState,
              onReset: () => ref.read(gameProvider.notifier).resetGame(),
            ),
            const SizedBox(height: 8),
            const _RulesPanel(),
            const SizedBox(height: 6),
            _RemainingCounter(remaining: gameState.remainingTrumps),
            const SizedBox(height: 8),
            // Tips on left, grid centered, right spacer balances tips width
            Expanded(
              child: Row(
                children: [
                  const _TipsPanel(),
                  Expanded(child: _GameGrid()),
                  const SizedBox(width: 60), // balances _TipsPanel width
                ],
              ),
            ),
            const SizedBox(height: 8),
            _BottomBar(gameState: gameState),
            const SizedBox(height: 12),
          ],
        ),
        ),
      ),
    );
  }
}

// ── Top Bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final GameState gameState;
  final VoidCallback onReset;

  const _TopBar({required this.gameState, required this.onReset});

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final gameState = ref.watch(gameProvider);
          final bgmEnabled = gameState.bgmEnabled;
          final bgmVolume = gameState.bgmVolume;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('设置', textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // BGM 开关
                ListTile(
                  leading: Icon(
                    bgmEnabled ? Icons.music_note : Icons.music_off,
                    color: const Color(0xFF4A90D9),
                  ),
                  title: const Text('背景音乐'),
                  trailing: Switch(
                    value: bgmEnabled,
                    activeColor: const Color(0xFF4A90D9),
                    onChanged: (_) =>
                        ref.read(gameProvider.notifier).toggleBgm(),
                  ),
                ),
                // 音量滑块
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.volume_down, size: 18, color: Colors.grey),
                      Expanded(
                        child: Slider(
                          value: bgmVolume,
                          min: 0,
                          max: 1,
                          divisions: 10,
                          activeColor: const Color(0xFF4A90D9),
                          onChanged: bgmEnabled
                              ? (v) => ref.read(gameProvider.notifier).setBgmVolume(v)
                              : null,
                        ),
                      ),
                      const Icon(Icons.volume_up, size: 18, color: Colors.grey),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.home_outlined, color: Color(0xFF4A90D9)),
                  title: const Text('退出到主页'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamedAndRemoveUntil(
                      context, '/', (route) => false,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.replay, color: Color(0xFF4A90D9)),
                  title: const Text('重新开始'),
                  onTap: () {
                    Navigator.pop(ctx);
                    onReset();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.close, color: Colors.grey),
                  title: const Text('继续游戏'),
                  onTap: () => Navigator.pop(ctx),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Settings button
          _IconBtn(
            icon: Icons.settings,
            onTap: () => _showSettingsDialog(context),
          ),
          const SizedBox(width: 8),
          // Gold coins (placeholder)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Row(
              children: [
                Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                SizedBox(width: 4),
                Text('0', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Spacer(),
          // Level
          Column(
            children: [
              Text(
                '第${gameState.level}关',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                _formatTime(gameState.timeLeft),
                style: TextStyle(
                  fontSize: 13,
                  color: gameState.timeLeft < 60 ? Colors.red : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Lives
          Row(
            children: List.generate(
              3,
              (i) => Icon(
                Icons.favorite,
                color: i < gameState.lives ? Colors.red : Colors.grey[300],
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Rules Panel ───────────────────────────────────────────────────────────────

class _RulesPanel extends StatelessWidget {
  const _RulesPanel();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: const [
            _RuleCard(text: '每种颜色\n恰好1个Trump'),
            _Divider(),
            _RuleCard(text: '每行每列\n恰好1个Trump'),
            _Divider(),
            _RuleCard(text: 'Trump\n不能相邻\n(含对角)'),
          ],
        ),
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final String text;

  const _RuleCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, height: 1.4, color: Color(0xFF444444)),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: Colors.grey[200]);
  }
}

// ── Remaining Counter ─────────────────────────────────────────────────────────

class _RemainingCounter extends StatelessWidget {
  final int remaining;

  const _RemainingCounter({required this.remaining});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/images/trump.png', width: 24, height: 24),
        const SizedBox(width: 6),
        Text(
          '剩余Trump：$remaining',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }
}

// ── Tips Panel ────────────────────────────────────────────────────────────────

class _TipsPanel extends StatelessWidget {
  const _TipsPanel();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          _TipItem(icon: Icons.touch_app_outlined, lines: ['单击', '画✕', '排除']),
          SizedBox(height: 20),
          _TipItem(icon: Icons.ads_click, lines: ['双击', '放置', 'Trump']),
          SizedBox(height: 20),
          _TipItem(icon: Icons.swipe, lines: ['滑动', '批量', '画✕']),
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final IconData icon;
  final List<String> lines;

  const _TipItem({required this.icon, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFE05555)),
        const SizedBox(height: 4),
        ...lines.map(
          (l) => Text(
            l,
            style: const TextStyle(fontSize: 10, color: Color(0xFFE05555), height: 1.4),
          ),
        ),
      ],
    );
  }
}

// ── Game Grid ─────────────────────────────────────────────────────────────────

class _GameGrid extends ConsumerStatefulWidget {
  const _GameGrid();

  @override
  ConsumerState<_GameGrid> createState() => _GameGridState();
}

class _GameGridState extends ConsumerState<_GameGrid> {
  Offset? _dragStart;

  void _handlePointerMove(PointerMoveEvent event, double gridSize) {
    if (_dragStart == null) return;
    if ((event.localPosition - _dragStart!).distance < 6) return;
    final board = ref.read(gameProvider).board;
    final n = board.length;
    final cellSize = gridSize / n;
    final col = (event.localPosition.dx / cellSize).floor().clamp(0, n - 1);
    final row = (event.localPosition.dy / cellSize).floor().clamp(0, n - 1);
    ref.read(gameProvider.notifier).dragMarkCell(row, col);
  }

  @override
  Widget build(BuildContext context, ) {
    final ref = this.ref;
    final showCoords = ref.watch(gameProvider).showCoordinates;
    const labelWidth = 28.0;
    const labelHeight = 28.0;

    // Always reserve label space — grid size is fixed regardless of showCoords.
    // Only the text color toggles between visible and transparent.
    return LayoutBuilder(
      builder: (context, constraints) {
        final board = ref.watch(gameProvider).board;
        final n = board.length;
        final gridSize = min(
          constraints.maxWidth - labelWidth - 24, // 12px padding each side
          constraints.maxHeight - labelHeight,
        );
        final cellSize = gridSize / n;

        final labelStyle = TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: showCoords ? Colors.black87 : Colors.transparent,
        );

        return Center(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left labels — always sized, color toggles
                SizedBox(
                  width: labelWidth,
                  height: gridSize,
                  child: Column(
                    children: List.generate(
                      n,
                      (row) => SizedBox(
                        height: cellSize,
                        child: Center(
                          child: Text('${n - row}', style: labelStyle),
                        ),
                      ),
                    ),
                  ),
                ),
                // Grid — fixed square, with drag-to-mark listener
                Listener(
                  onPointerDown: (e) => _dragStart = e.localPosition,
                  onPointerMove: (e) => _handlePointerMove(e, gridSize),
                  onPointerUp: (_) => _dragStart = null,
                  child: SizedBox.square(
                    dimension: gridSize,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!, width: 1.5),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: List.generate(
                          n,
                          (row) => Expanded(
                            child: Row(
                              children: List.generate(
                                n,
                                (col) => Expanded(
                                  child: GridCellWidget(row: row, col: col),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Bottom labels — always sized, color toggles
            SizedBox(
              height: labelHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: labelWidth),
                  ...List.generate(
                    n,
                    (col) => SizedBox(
                      width: cellSize,
                      child: Center(
                        child: Text('${col + 1}', style: labelStyle),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        );
      },
    );
  }
}

// ── Bottom Bar ────────────────────────────────────────────────────────────────

class _BottomBar extends ConsumerWidget {
  final GameState gameState;

  const _BottomBar({required this.gameState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Clear all marks
          _BottomBtn(
            icon: Icons.delete_outline,
            label: '清除',
            onTap: () => ref.read(gameProvider.notifier).clearAllMarks(),
          ),
          // Hint button
          _BottomBtnWithBadge(
            child: Icon(Icons.lightbulb_outline, size: 28,
                color: gameState.hintsLeft > 0 ? Colors.amber : Colors.grey[400]),
            label: '提示',
            badge: '${gameState.hintsLeft}',
            onTap: gameState.hintsLeft > 0
                ? () => ref.read(gameProvider.notifier).useHint()
                : null,
          ),
          // Coordinates toggle
          _BottomBtn(
            icon: Icons.grid_on,
            label: '坐标',
            onTap: () => ref.read(gameProvider.notifier).toggleCoordinates(),
            active: gameState.showCoordinates,
          ),
        ],
      ),
    );
  }
}

class _BottomBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  const _BottomBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF6EB8D4) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: active ? Colors.white : Colors.grey[700]),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: active ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple display button (no badge, no tap action)
class _BottomBtn2 extends StatelessWidget {
  final Widget child;
  final String label;

  const _BottomBtn2({required this.child, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 32, height: 32, child: Center(child: child)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
        ],
      ),
    );
  }
}

class _BottomBtnWithBadge extends StatelessWidget {
  final Widget child;
  final String label;
  final String badge;
  final VoidCallback? onTap;

  const _BottomBtnWithBadge({
    required this.child,
    required this.label,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(width: 32, height: 32, child: child),
                Positioned(
                  right: -6,
                  bottom: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90D9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 22, color: Colors.grey[700]),
      ),
    );
  }
}
