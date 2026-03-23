import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cell.dart';
import '../providers/game_provider.dart';

class _XPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 15.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, 0), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

const Map<String, Color> kRegionColors = {
  // 15 区域色，避免极纯色，中等饱和度且带灰色调，观感更柔和
  'blue':     Color(0xFF6A8CAF), // muted blue
  'green':    Color(0xFF7BAF7E), // soft green
  'red':      Color(0xFFD97A73), // muted red
  'yellow':   Color(0xFFF9E18C), // soft yellow
  'purple':   Color(0xFFA090B7), // greyed purple
  'orange':   Color(0xFFFFBC7E), // gentle orange
  'cyan':     Color(0xFF7BC8CE), // light cyan
  'lime':     Color(0xFFE2EAA7), // pale lime
  'teal':     Color(0xFF6AB1A4), // teal softened
  'pink':     Color(0xFFFFADC5), // light pink
  'indigo':   Color(0xFF9EA8D6), // muted indigo
  'brown':    Color(0xFFD0B098), // soft brown
  'amber':    Color(0xFFFFECB3), // pale amber
  'black':    Color(0xFF545454), // dark grey (not pure black)
  'lightBlue':Color(0xFFAED4EC), // pale blue
};

class GridCellWidget extends ConsumerStatefulWidget {
  final int row;
  final int col;

  const GridCellWidget({super.key, required this.row, required this.col});

  @override
  ConsumerState<GridCellWidget> createState() => _GridCellWidgetState();
}

class _GridCellWidgetState extends ConsumerState<GridCellWidget>
    with TickerProviderStateMixin {
  // Error flash
  late AnimationController _errorAnim;
  late Animation<Color?> _colorAnim;

  // Jelly pop when trump is placed
  late AnimationController _jellyAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _rotateAnim;

  CellState _prevState = CellState.empty;

  @override
  void initState() {
    super.initState();

    _errorAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _colorAnim = ColorTween(
      begin: Colors.red[400],
      end: Colors.transparent,
    ).animate(_errorAnim);

    // Jelly: scale springs from 0 → overshoot → settle at 1
    _jellyAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _jellyAnim, curve: Curves.elasticOut),
    );
    // Slight wobble rotation: quick ±8° then settle
    _rotateAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.14), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.14, end: -0.10), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -0.10, end: 0.06), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.06, end: 0.0), weight: 45),
    ]).animate(CurvedAnimation(parent: _jellyAnim, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _errorAnim.dispose();
    _jellyAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final cell = gameState.board[widget.row][widget.col];
    final isError =
        gameState.errorRow == widget.row && gameState.errorCol == widget.col;

    // Trigger animations on state change
    if (isError) {
      _errorAnim.forward(from: 0);
    }
    if (cell.state == CellState.trump && _prevState != CellState.trump) {
      _jellyAnim.forward(from: 0);
    }
    _prevState = cell.state;

    final baseColor = kRegionColors[cell.region] ?? Colors.grey[300]!;

    return GestureDetector(
      onTap: () => ref.read(gameProvider.notifier).tapCell(widget.row, widget.col),
      onDoubleTap: () =>
          ref.read(gameProvider.notifier).doubleTapCell(widget.row, widget.col),
      child: AnimatedBuilder(
        animation: Listenable.merge([_errorAnim, _jellyAnim]),
        builder: (context, child) {
          final overlay = isError ? _colorAnim.value : Colors.transparent;
          return Container(
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                overlay ?? Colors.transparent,
                baseColor,
              ),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: child,
          );
        },
        child: Center(child: _buildContent(cell)),
      ),
    );
  }

  Widget _buildContent(Cell cell) {
    switch (cell.state) {
      case CellState.trump:
        return AnimatedBuilder(
          animation: _jellyAnim,
          builder: (context, child) => Transform.rotate(
            angle: _rotateAnim.value,
            child: Transform.scale(
              scale: _scaleAnim.value,
              child: child,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Image.asset('assets/images/trump.png', fit: BoxFit.contain),
          ),
        );
      case CellState.mark:
        return Padding(
          padding: const EdgeInsets.all(4),
          child: CustomPaint(
            painter: _XPainter(),
            size: const Size(32, 32),
          ),
        );
      case CellState.empty:
        return const SizedBox.shrink();
    }
  }
}
