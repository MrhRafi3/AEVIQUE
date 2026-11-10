import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/luma_theme.dart';

enum ComparisonMode {
  pressAndHold,
  splitSlider,
}

/// Professional Before / After comparison viewer supporting Press-and-Hold
/// and interactive draggable split-screen slider.
class BeforeAfterViewer extends StatefulWidget {
  final Widget originalChild;
  final Widget editedChild;
  final bool showBadge;
  final ComparisonMode initialMode;

  const BeforeAfterViewer({
    super.key,
    required this.originalChild,
    required this.editedChild,
    this.showBadge = true,
    this.initialMode = ComparisonMode.pressAndHold,
  });

  @override
  State<BeforeAfterViewer> createState() => _BeforeAfterViewerState();
}

class _BeforeAfterViewerState extends State<BeforeAfterViewer> {
  bool _showingOriginal = false;
  late ComparisonMode _mode;
  double _splitPosition = 0.5; // 0.0 .. 1.0 (50% split)

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  void _onPressDown() {
    if (_mode == ComparisonMode.pressAndHold) {
      HapticFeedback.selectionClick();
      setState(() => _showingOriginal = true);
    }
  }

  void _onPressUp() {
    if (_mode == ComparisonMode.pressAndHold && _showingOriginal) {
      setState(() => _showingOriginal = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_mode == ComparisonMode.pressAndHold) {
      return Listener(
        onPointerDown: (_) => _onPressDown(),
        onPointerUp: (_) => _onPressUp(),
        onPointerCancel: (_) => _onPressUp(),
        child: Stack(
          alignment: Alignment.center,
          children: [
            _showingOriginal ? widget.originalChild : widget.editedChild,
            if (widget.showBadge && _showingOriginal)
              Positioned(
                top: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: LumaTheme.accentAmber, width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: LumaTheme.accentAmber.withValues(alpha: 0.25),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.compare_rounded, color: LumaTheme.accentAmberLight, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'ORIGINAL',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Split-screen draggable slider mode
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final splitX = (width * _splitPosition).clamp(0.0, width);

        return Stack(
          alignment: Alignment.center,
          children: [
            // Background: Full edited child
            Positioned.fill(child: widget.editedChild),

            // Foreground: Clipped original child on left side
            Positioned.fill(
              child: ClipRect(
                clipper: _LeftSplitClipper(splitX: splitX),
                child: widget.originalChild,
              ),
            ),

            // Vertical dividing line
            Positioned(
              left: splitX - 1.0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 2.0,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),

            // Draggable Pill Handle
            Positioned(
              left: splitX - 20.0,
              top: (height / 2) - 20.0,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _splitPosition = (_splitPosition + (details.primaryDelta ?? 0.0) / width).clamp(0.05, 0.95);
                  });
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xCC14141C),
                    border: Border.all(color: LumaTheme.primaryBlueLight, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.compare_arrows_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),

            // Badges indicating BEFORE | AFTER
            if (widget.showBadge) ...[
              Positioned(
                left: 16,
                top: 16,
                child: _buildLabelBadge('BEFORE'),
              ),
              Positioned(
                right: 16,
                top: 16,
                child: _buildLabelBadge('AFTER'),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildLabelBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x33FFFFFF), width: 0.8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Inter',
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _LeftSplitClipper extends CustomClipper<Rect> {
  final double splitX;
  const _LeftSplitClipper({required this.splitX});

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, splitX, size.height);
  }

  @override
  bool shouldReclip(_LeftSplitClipper oldClipper) => oldClipper.splitX != splitX;
}
