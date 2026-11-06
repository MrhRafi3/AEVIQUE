import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/aevique_theme.dart';

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
    HapticFeedback.selectionClick();
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AeviqueTheme.accentAmber,
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AeviqueTheme.accentAmber.withValues(alpha: 0.25),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.compare_rounded, color: AeviqueTheme.accentAmberLight, size: 14),
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
}
