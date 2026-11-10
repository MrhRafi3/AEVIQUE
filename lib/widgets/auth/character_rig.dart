import 'dart:ui';
import 'animation_constants.dart';
import 'crew_data.dart';
import 'eye_rig.dart';
import 'spring.dart';

class CharacterRig {
  final MemberDefinition member;
  final int index;
  final List<EyeRig> eyes;

  final Spring hop = Spring(
    k: AnimationConstants.springHop.$1,
    c: AnimationConstants.springHop.$2,
  );
  final Spring lean = Spring(
    k: AnimationConstants.springLean.$1,
    c: AnimationConstants.springLean.$2,
  );
  final Spring shake = Spring(
    k: AnimationConstants.springShake.$1,
    c: AnimationConstants.springShake.$2,
  );
  final Spring sq = Spring(
    k: AnimationConstants.springSquash.$1,
    c: AnimationConstants.springSquash.$2,
  );
  final Spring turnX = Spring(
    k: AnimationConstants.springTurn.$1,
    c: AnimationConstants.springTurn.$2,
  );
  final Spring turnY = Spring(
    k: AnimationConstants.springTurn.$1,
    c: AnimationConstants.springTurn.$2,
  );

  // Per-frame evaluation cached fields
  Offset rootTranslation = Offset.zero;
  double rootRotationDeg = 0.0;
  double scaleX = 1.0;
  double scaleY = 1.0;

  Offset faceTranslation = Offset.zero;

  Path? mouthPath;
  double mouthFillOpacity = 0.0;

  Offset tongueCenter = Offset.zero;
  double tongueRadiusX = 0.0;
  double tongueRadiusY = 0.0;
  double tongueOpacity = 0.0;

  Offset sweatTranslation = Offset.zero;
  double sweatOpacity = 0.0;

  double blushOpacity = 0.0;

  Offset heartTranslation = Offset.zero;
  double heartScale = 1.0;
  double heartOpacity = 0.0;

  CharacterRig(this.member, this.index)
    : eyes = member.eyes.map((e) => EyeRig(e)).toList(growable: false);

  void reset() {
    hop.reset();
    lean.reset();
    shake.reset();
    sq.reset();
    turnX.reset();
    turnY.reset();
    for (final eye in eyes) {
      eye.reset();
    }
  }
}
