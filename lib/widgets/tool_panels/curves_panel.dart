import 'package:flutter/material.dart';
import '../../core/models/edit_state.dart';
import '../curve_editor_widget.dart';

class CurvesPanel extends StatelessWidget {
  final ToneCurves curves;
  final ValueChanged<ToneCurves> onChanged;

  const CurvesPanel({super.key, required this.curves, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: CurveEditorWidget(curves: curves, onCurvesChanged: onChanged),
    );
  }
}
