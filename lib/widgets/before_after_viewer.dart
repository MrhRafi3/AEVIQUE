import 'package:flutter/material.dart';
import '../theme/luma_theme.dart';

class BeforeAfterViewer extends StatefulWidget {
  final Widget originalChild;
  final Widget editedChild;
  final bool showBadge;

  const BeforeAfterViewer({
    super.key,
    required this.originalChild,
    required this.editedChild,
    this.showBadge = true,
  });

  @override
  State<BeforeAfterViewer> createState() => _BeforeAfterViewerState();
}

class _BeforeAfterViewerState extends State<BeforeAfterViewer> {
  bool _showingOriginal = false;

  void _onPressDown() {
    setState(() => _showingOriginal = true);
  }

  void _onPressUp() {
    setState(() => _showingOriginal = false);
  }

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: LumaTheme.accent, width: 1),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.compare_rounded,
                      color: LumaTheme.accent,
                      size: 14,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'ORIGINAL',
                      style: TextStyle(
                        color: LumaTheme.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
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
}
