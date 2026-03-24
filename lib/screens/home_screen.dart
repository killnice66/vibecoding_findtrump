import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import '../providers/game_provider.dart';
import '../providers/progress_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final AudioPlayer _bgmPlayer = AudioPlayer();
  bool _bgmStarted = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _playBgm();
  }

  Future<void> _playBgm() async {
    final gs = ref.read(gameProvider);
    if (!gs.bgmEnabled) return;
    _bgmStarted = true;
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.setVolume(gs.bgmVolume);
    await _bgmPlayer.play(AssetSource('audio/hall_bgm.wav'));
  }

  void _onInteraction() {
    if (!_bgmStarted) _playBgm();
  }

  @override
  void dispose() {
    _bgmPlayer.dispose();
    super.dispose();
  }

  void _startLevel(int level) {
    ref.read(gameProvider.notifier).startLevel(level);
    _bgmPlayer.stop();
    Navigator.pop(context);
    Navigator.pushNamed(context, '/game');
  }

  void _showLevelPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _LevelPickerSheet(onSelect: _startLevel),
    );
  }

  void _showSettings() {
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
                ListTile(
                  leading: Icon(
                    bgmEnabled ? Icons.music_note : Icons.music_off,
                    color: const Color(0xFF4A90D9),
                  ),
                  title: const Text('背景音乐'),
                  trailing: Switch(
                    value: bgmEnabled,
                    activeColor: const Color(0xFF4A90D9),
                    onChanged: (_) {
                      ref.read(gameProvider.notifier).toggleBgm();
                      final nowEnabled = !bgmEnabled;
                      if (nowEnabled) {
                        _playBgm();
                      } else {
                        _bgmPlayer.stop();
                      }
                    },
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
                              ? (v) {
                                  ref.read(gameProvider.notifier).setBgmVolume(v);
                                  _bgmPlayer.setVolume(v);
                                }
                              : null,
                        ),
                      ),
                      const Icon(Icons.volume_up, size: 18, color: Colors.grey),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.close, color: Colors.grey),
                  title: const Text('关闭'),
                  onTap: () => Navigator.pop(ctx),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _onInteraction,
        child: Stack(
        fit: StackFit.expand,
        children: [
          // 背景图（最底层）
          Image.asset(
            'assets/images/background.png',
            fit: BoxFit.cover,
          ),
          SafeArea(
        child: Column(
          children: [
            // 顶部设置按钮
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16, top: 8),
                child: GestureDetector(
                  onTap: _showSettings,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 4)
                      ],
                    ),
                    child: const Icon(Icons.settings, size: 22, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const Text(
              'Find Trump',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
                letterSpacing: 1.2,
              ),
            ),
            const Text(
              '逻辑推理小游戏',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            // 全身图（跳舞动画）
            const Expanded(child: _FloatingTrump()),
            // 底部按钮区
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: Column(
                children: [
                  // 开始游戏（快捷进入第1关）
                  _PrimaryBtn(
                    label: '开始游戏',
                    onTap: () => _startLevel(1),
                  ),
                  const SizedBox(height: 14),
                  // 关卡选择小按钮
                  _SecondaryBtn(
                    icon: Icons.grid_view_rounded,
                    label: '选择关卡',
                    onTap: _showLevelPicker,
                  ),
                ],
              ),
            ),
          ],
        ),
          ),
        ],
        ),
      ),
    );
  }
}

// ── Level Picker Bottom Sheet ─────────────────────────────────────────────────

class _LevelPickerSheet extends StatelessWidget {
  final void Function(int) onSelect;

  const _LevelPickerSheet({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final progressAsync = ref.watch(progressProvider);
        final maxUnlocked =
            progressAsync.maybeWhen(data: (p) => p.maxUnlockedLevel, orElse: () => 1);
        final maxHeight = MediaQuery.of(context).size.height * 0.7;
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 把手
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '选择关卡',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 16),
                // 预留 100 关，超出部分可滚动
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1,
                    ),
                    itemCount: 100,
                    itemBuilder: (context, index) {
                      final level = index + 1;
                      // 当前只实现了前 10 关：1~10 可玩，其余灰度锁定
                      final isUnlocked = level <= 10;
                      return _LevelCell(
                        level: level,
                        isUnlocked: isUnlocked,
                        onTap: () => onSelect(level),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Floating Trump Animation ──────────────────────────────────────────────────

class _FloatingTrump extends StatefulWidget {
  const _FloatingTrump();

  @override
  State<_FloatingTrump> createState() => _FloatingTrumpState();
}

class _FloatingTrumpState extends State<_FloatingTrump>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 旋转：以脚底为轴，±8°
  late Animation<double> _rotateAnim;
  // 髋部横移：身体随旋转向同侧平移，更像真实跳舞
  late Animation<double> _shiftAnim;
  // 膝盖弹跳：每次左右切换时微微下蹲
  late Animation<double> _bounceAnim;
  // 阴影
  late Animation<double> _shadowAnim;

  @override
  void initState() {
    super.initState();
    // 600ms 一个来回，节奏轻快但不跳脱
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _rotateAnim  = Tween<double>(begin: -0.13, end: 0.13).animate(curved);
    _shiftAnim   = Tween<double>(begin: -10.0, end: 10.0).animate(curved);
    // 弹跳用抛物线感：中间最高（controller=0.5 时最低偏移=0，两端最大）
    _bounceAnim  = Tween<double>(begin: -6.0, end: -6.0).animate(
      CurvedAnimation(parent: _controller, curve: _ArchCurve()),
    );
    _shadowAnim  = Tween<double>(begin: 0.75, end: 1.05).animate(curved);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.translate(
              offset: Offset(_shiftAnim.value, _bounceAnim.value),
              child: Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.rotationZ(_rotateAnim.value),
                child: Image.asset(
                  'assets/images/trump_fullbody_transparent.png',
                  fit: BoxFit.contain,
                  height: 260,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Transform.translate(
              offset: Offset(_shiftAnim.value * 0.3, 0),
              child: Transform.scale(
                scaleX: _shadowAnim.value,
                child: Container(
                  width: 70,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// 抛物线曲线：两端值最大，中间为0 — 模拟膝盖在换脚时下蹲
class _ArchCurve extends Curve {
  @override
  double transform(double t) => 4 * t * (1 - t); // 0→1→0 抛物线
}

// ── Buttons ───────────────────────────────────────────────────────────────────

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6EB8D4), Color(0xFF4A90D9)],
          ),
          borderRadius: BorderRadius.circular(27),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A90D9).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SecondaryBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: const Color(0xFF6EB8D4), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF4A90D9)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF4A90D9),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Level Cell ────────────────────────────────────────────────────────────────

class _LevelCell extends StatelessWidget {
  final int level;
  final bool isUnlocked;
  final VoidCallback onTap;

  const _LevelCell({
    required this.level,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUnlocked ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: isUnlocked ? const Color(0xFF6EB8D4) : const Color(0xFFE8E8E8),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: const Color(0xFF6EB8D4).withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isUnlocked)
              Image.asset('assets/images/trump.png', width: 26, height: 26)
            else
              Icon(Icons.lock, size: 16, color: Colors.grey[400]),
            const SizedBox(height: 2),
            Text(
              '$level',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isUnlocked ? Colors.white : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
