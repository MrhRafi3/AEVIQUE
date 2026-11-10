import 'dart:ui';
import 'design_tokens.dart';
import 'organic_shapes.dart';

enum CharacterLayer { back, front }

class EyeDefinition {
  final double x;
  final double y;
  final double radius;

  const EyeDefinition(this.x, this.y, this.radius);

  Offset get offset => Offset(x, y);
}

class MouthDefinition {
  final double x;
  final double y;
  final double halfWidth;

  const MouthDefinition(this.x, this.y, this.halfWidth);

  Offset get offset => Offset(x, y);
}

class StarDefinition {
  final double x;
  final double y;
  final double radius;

  const StarDefinition(this.x, this.y, this.radius);

  Offset get offset => Offset(x, y);
}

class MemberDefinition {
  final String id;
  final CharacterLayer layer;
  final double x;
  final double y;
  final double rotation; // in degrees
  final Color color;
  final Path bodyPath;
  final List<EyeDefinition> eyes;
  final MouthDefinition mouth;
  final double delay;

  late final Offset sweatAt;
  late final Offset heartAt;
  late final Path blushPath;

  MemberDefinition({
    required this.id,
    required this.layer,
    required this.x,
    required this.y,
    required this.rotation,
    required this.color,
    required this.bodyPath,
    required this.eyes,
    required this.mouth,
    required this.delay,
  }) {
    final EyeDefinition rightEye = eyes.last;
    sweatAt = Offset(
      rightEye.x + rightEye.radius + 8.0,
      rightEye.y - rightEye.radius - 4.0,
    );
    heartAt = Offset(mouth.x + mouth.halfWidth + 16.0, mouth.y - 6.0);
    blushPath = OrganicShapes.blushPath(
      eyes.map((e) => e.offset).toList(growable: false),
      eyes.map((e) => e.radius).toList(growable: false),
    );
  }

  Offset get position => Offset(x, y);
}

abstract final class CrewData {
  static const List<StarDefinition> stars = [
    StarDefinition(110.0, 250.0, 9.0),
    StarDefinition(300.0, 268.0, 7.0),
    StarDefinition(372.0, 330.0, 8.0),
    StarDefinition(24.0, 420.0, 6.0),
    StarDefinition(384.0, 470.0, 7.0),
    StarDefinition(60.0, 600.0, 7.0),
  ];

  static final List<MemberDefinition> crew = [
    // 0: Cookie
    MemberDefinition(
      id: 'cookie',
      layer: CharacterLayer.back,
      x: 68.0,
      y: 150.0,
      rotation: 14.0,
      color: DesignTokens.cookie,
      bodyPath: OrganicShapes.cookieBody(),
      eyes: const [
        EyeDefinition(-18.0, -8.0, 9.5),
        EyeDefinition(18.0, -8.0, 9.5),
      ],
      mouth: const MouthDefinition(0.0, 16.0, 12.0),
      delay: 0.15,
    ),

    // 1: Sun
    MemberDefinition(
      id: 'sun',
      layer: CharacterLayer.back,
      x: 185.0,
      y: 110.0,
      rotation: -6.0,
      color: DesignTokens.sun,
      bodyPath: OrganicShapes.sunBody(),
      eyes: const [EyeDefinition(0.0, -2.0, 15.0)], // cyclops
      mouth: const MouthDefinition(0.0, 22.0, 11.0),
      delay: 0.45,
    ),

    // 2: Bean
    MemberDefinition(
      id: 'bean',
      layer: CharacterLayer.back,
      x: 320.0,
      y: 160.0,
      rotation: -10.0,
      color: DesignTokens.bean,
      bodyPath: OrganicShapes.beanBody(),
      eyes: const [
        EyeDefinition(-16.0, -42.0, 12.0),
        EyeDefinition(16.0, -42.0, 12.0),
      ],
      mouth: const MouthDefinition(0.0, -14.0, 13.0),
      delay: 0.30,
    ),

    // 3: Wobble
    MemberDefinition(
      id: 'wobble',
      layer: CharacterLayer.front,
      x: 22.0,
      y: 840.0,
      rotation: 8.0,
      color: DesignTokens.wobble,
      bodyPath: OrganicShapes.wobbleBody(),
      eyes: const [
        EyeDefinition(-15.0, -18.0, 8.5),
        EyeDefinition(15.0, -18.0, 8.5),
      ],
      mouth: const MouthDefinition(0.0, 4.0, 10.0),
      delay: 0.60,
    ),

    // 4: Pebble
    MemberDefinition(
      id: 'pebble',
      layer: CharacterLayer.front,
      x: 388.0,
      y: 830.0,
      rotation: -12.0,
      color: DesignTokens.pebble,
      bodyPath: OrganicShapes.pebbleBody(),
      eyes: const [
        EyeDefinition(-17.0, -26.0, 10.0),
        EyeDefinition(17.0, -26.0, 10.0),
      ],
      mouth: const MouthDefinition(0.0, -4.0, 12.0),
      delay: 0.75,
    ),
  ];
}
