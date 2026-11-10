import 'crew_data.dart';

class EyeRig {
  final EyeDefinition definition;
  double px = 0.0;
  double py = 0.0;
  double vx = 0.0;
  double vy = 0.0;

  // Cached per-frame evaluated rendering properties
  double pupilRadius = 0.0;
  double lidHeight = 0.0;
  double normalEyeOpacity = 1.0;
  double happyOpacity = 0.0;
  double browOpacity = 0.0;
  double browTranslationY = 0.0;
  double browRotation = 0.0;
  double whiteRadius = 0.0;
  double clipRadius = 0.0;

  EyeRig(this.definition) {
    pupilRadius = definition.radius * 0.52;
    whiteRadius = definition.radius;
    clipRadius = definition.radius + 1.5;
  }

  double get x => definition.x;
  double get y => definition.y;
  double get r => definition.radius;

  void reset() {
    px = 0.0;
    py = 0.0;
    vx = 0.0;
    vy = 0.0;
  }
}
