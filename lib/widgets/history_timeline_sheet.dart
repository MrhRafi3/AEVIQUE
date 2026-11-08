import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/models/edit_state.dart';
import '../core/models/history_manager.dart';
import '../theme/aevique_theme.dart';
import 'aevique_glass.dart';

/// Modal bottom sheet displaying the non-destructive history timeline
/// with direct jump-to-step and clear history capabilities.
class HistoryTimelineSheet extends StatelessWidget {
  final HistoryManager history;
  final ValueChanged<int> onJumpToStep;
  final VoidCallback onClearHistory;

  const HistoryTimelineSheet({
    super.key,
    required this.history,
    required this.onJumpToStep,
    required this.onClearHistory,
  });

  String _describeState(EditState state, int index) {
    if (index == 0 && state.isIdentity) {
      return 'Original Image';
    }
    final parts = <String>[];
    if (state.filterId != null) parts.add('Filter: ${state.filterId}');
    if (state.presetName != null) parts.add('Preset: ${state.presetName}');

    final t = state.tune;
    if (t.exposure != 0) parts.add('Exp ${t.exposure > 0 ? '+' : ''}${t.exposure.toStringAsFixed(0)}');
    if (t.contrast != 0) parts.add('Con ${t.contrast > 0 ? '+' : ''}${t.contrast.toStringAsFixed(0)}');
    if (t.saturation != 0) parts.add('Sat ${t.saturation > 0 ? '+' : ''}${t.saturation.toStringAsFixed(0)}');
    if (t.warmth != 0) parts.add('Warmth');
    if (t.vibrance != 0) parts.add('Vibrance');
    if (t.clarity != 0) parts.add('Clarity');

    if (!state.curves.isIdentity) parts.add('Curves');
    if (!state.hsl.isIdentity) parts.add('HSL Mixer');
    if (state.effects.grain > 0) parts.add('Grain');
    if (state.effects.bloom > 0) parts.add('Bloom');
    if (state.effects.glow > 0) parts.add('Glow');
    if (state.effects.lensBlur > 0) parts.add('Lens Blur');
    if (state.effects.bwMode) parts.add('B&W');
    if (!state.vignette.isIdentity) parts.add('Vignette');
    if (!state.geometry.isIdentity) parts.add('Geometry');
    if (!state.portrait.isIdentity) parts.add('Portrait');
    if (state.masks.isNotEmpty) parts.add('Masks (${state.masks.length})');

    if (parts.isEmpty) return 'Step $index: Edits Applied';
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final list = history.history;
    final currentIdx = history.currentIndex;

    return AeviqueGlass(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.history_rounded, size: 20, color: AeviqueTheme.primaryBlueLight),
                  const SizedBox(width: 8),
                  const Text(
                    'Editing History',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0x331E1E2A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AeviqueTheme.borderSubtle, width: 0.8),
                    ),
                    child: Text(
                      '${list.length} steps',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (list.length > 1)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onClearHistory();
                        Navigator.of(context).pop();
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Text(
                          'Clear All',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AeviqueTheme.coralRedLight,
                          ),
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Colors.white60),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Timeline Steps List
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 340),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: list.length,
              separatorBuilder: (context, index) => const Divider(
                color: Color(0x1AFFFFFF),
                height: 1,
              ),
              itemBuilder: (context, index) {
                // Reverse display so newest is at the top
                final stepIdx = list.length - 1 - index;
                final state = list[stepIdx];
                final isCurrent = stepIdx == currentIdx;
                final isFuture = stepIdx > currentIdx;

                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onJumpToStep(stepIdx);
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: isCurrent
                        ? BoxDecoration(
                            color: AeviqueTheme.primaryBlue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AeviqueTheme.primaryBlueLight, width: 1.0),
                          )
                        : null,
                    child: Row(
                      children: [
                        // Timeline Dot / Icon
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCurrent
                                ? AeviqueTheme.primaryBlue
                                : (isFuture ? const Color(0x334B5563) : const Color(0x3310B981)),
                            border: Border.all(
                              color: isCurrent
                                  ? Colors.white
                                  : (isFuture ? Colors.white24 : const Color(0xFF10B981)),
                              width: 1.2,
                            ),
                          ),
                          child: Center(
                            child: isCurrent
                                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                                : Text(
                                    '$stepIdx',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isFuture ? Colors.white38 : Colors.white70,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Step Description
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _describeState(state, stepIdx),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                                  color: isCurrent
                                      ? Colors.white
                                      : (isFuture ? Colors.white38 : Colors.white70),
                                ),
                              ),
                              if (stepIdx == 0)
                                const Text(
                                  'Initial state',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    color: AeviqueTheme.textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AeviqueTheme.primaryBlue.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'CURRENT',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AeviqueTheme.primaryBlueLight,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
