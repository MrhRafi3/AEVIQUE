import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'hsl_adjustments.dart';

enum MaskType {
  brush,
  subject,
  linearGradient,
  radialGradient,
}

/// Point with radius and feather in normalized coordinates [0.0 .. 1.0].
@immutable
class MaskPoint {
  final double x;
  final double y;
  final double radius; // e.g. 0.04 (4% of image width)
  final double feather; // 0.0 .. 1.0

  const MaskPoint({
    required this.x,
    required this.y,
    this.radius = 0.04,
    this.feather = 0.5,
  });

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'radius': radius,
    'feather': feather,
  };

  factory MaskPoint.fromJson(Map<String, dynamic> json) => MaskPoint(
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    radius: (json['radius'] as num?)?.toDouble() ?? 0.04,
    feather: (json['feather'] as num?)?.toDouble() ?? 0.5,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaskPoint &&
          runtimeType == other.runtimeType &&
          (x - other.x).abs() < 1e-4 &&
          (y - other.y).abs() < 1e-4 &&
          (radius - other.radius).abs() < 1e-4 &&
          (feather - other.feather).abs() < 1e-4;

  @override
  int get hashCode => Object.hash(
    (x * 1000).round(),
    (y * 1000).round(),
    (radius * 1000).round(),
    (feather * 1000).round(),
  );
}

/// Linear gradient mask parameters.
@immutable
class LinearGradientData {
  final double startX; // normalized [0 .. 1]
  final double startY;
  final double endX;
  final double endY;
  final double feather; // 0.0 .. 1.0

  const LinearGradientData({
    this.startX = 0.5,
    this.startY = 0.2,
    this.endX = 0.5,
    this.endY = 0.8,
    this.feather = 0.5,
  });

  LinearGradientData copyWith({
    double? startX,
    double? startY,
    double? endX,
    double? endY,
    double? feather,
  }) => LinearGradientData(
    startX: startX ?? this.startX,
    startY: startY ?? this.startY,
    endX: endX ?? this.endX,
    endY: endY ?? this.endY,
    feather: feather ?? this.feather,
  );

  Map<String, dynamic> toJson() => {
    'startX': startX,
    'startY': startY,
    'endX': endX,
    'endY': endY,
    'feather': feather,
  };

  factory LinearGradientData.fromJson(Map<String, dynamic> json) =>
      LinearGradientData(
        startX: (json['startX'] as num?)?.toDouble() ?? 0.5,
        startY: (json['startY'] as num?)?.toDouble() ?? 0.2,
        endX: (json['endX'] as num?)?.toDouble() ?? 0.5,
        endY: (json['endY'] as num?)?.toDouble() ?? 0.8,
        feather: (json['feather'] as num?)?.toDouble() ?? 0.5,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinearGradientData &&
          runtimeType == other.runtimeType &&
          (startX - other.startX).abs() < 1e-4 &&
          (startY - other.startY).abs() < 1e-4 &&
          (endX - other.endX).abs() < 1e-4 &&
          (endY - other.endY).abs() < 1e-4 &&
          (feather - other.feather).abs() < 1e-4;

  @override
  int get hashCode => Object.hash(
    (startX * 1000).round(),
    (startY * 1000).round(),
    (endX * 1000).round(),
    (endY * 1000).round(),
    (feather * 1000).round(),
  );
}

/// Radial gradient mask parameters.
@immutable
class RadialGradientData {
  final double centerX; // normalized [0 .. 1]
  final double centerY;
  final double radiusX; // normalized [0.01 .. 1.0]
  final double radiusY;
  final double rotation; // degrees
  final double feather; // 0.0 .. 1.0

  const RadialGradientData({
    this.centerX = 0.5,
    this.centerY = 0.5,
    this.radiusX = 0.25,
    this.radiusY = 0.25,
    this.rotation = 0.0,
    this.feather = 0.5,
  });

  RadialGradientData copyWith({
    double? centerX,
    double? centerY,
    double? radiusX,
    double? radiusY,
    double? rotation,
    double? feather,
  }) => RadialGradientData(
    centerX: centerX ?? this.centerX,
    centerY: centerY ?? this.centerY,
    radiusX: radiusX ?? this.radiusX,
    radiusY: radiusY ?? this.radiusY,
    rotation: rotation ?? this.rotation,
    feather: feather ?? this.feather,
  );

  Map<String, dynamic> toJson() => {
    'centerX': centerX,
    'centerY': centerY,
    'radiusX': radiusX,
    'radiusY': radiusY,
    'rotation': rotation,
    'feather': feather,
  };

  factory RadialGradientData.fromJson(Map<String, dynamic> json) =>
      RadialGradientData(
        centerX: (json['centerX'] as num?)?.toDouble() ?? 0.5,
        centerY: (json['centerY'] as num?)?.toDouble() ?? 0.5,
        radiusX: (json['radiusX'] as num?)?.toDouble() ?? 0.25,
        radiusY: (json['radiusY'] as num?)?.toDouble() ?? 0.25,
        rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
        feather: (json['feather'] as num?)?.toDouble() ?? 0.5,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RadialGradientData &&
          runtimeType == other.runtimeType &&
          (centerX - other.centerX).abs() < 1e-4 &&
          (centerY - other.centerY).abs() < 1e-4 &&
          (radiusX - other.radiusX).abs() < 1e-4 &&
          (radiusY - other.radiusY).abs() < 1e-4 &&
          (rotation - other.rotation).abs() < 1e-4 &&
          (feather - other.feather).abs() < 1e-4;

  @override
  int get hashCode => Object.hash(
    (centerX * 1000).round(),
    (centerY * 1000).round(),
    (radiusX * 1000).round(),
    (radiusY * 1000).round(),
    (feather * 1000).round(),
  );
}

/// Tone adjustments applied specifically within a mask area.
@immutable
class MaskToneAdjustments {
  // Light
  final double exposure; // -100 .. 100
  final double brightness; // -100 .. 100
  final double contrast; // -100 .. 100
  final double highlights; // -100 .. 100
  final double shadows; // -100 .. 100
  final double whites; // -100 .. 100
  final double blacks; // -100 .. 100

  // Color
  final double warmth; // -100 .. 100
  final double tint; // -100 .. 100
  final double saturation; // -100 .. 100
  final double vibrance; // -100 .. 100

  // HSL Mixer
  final HslAdjustments hsl;

  // Effects / Details
  final double clarity; // -100 .. 100
  final double texture; // -100 .. 100
  final double dehaze; // -100 .. 100
  final double sharpness; // 0 .. 100

  const MaskToneAdjustments({
    this.exposure = 0.0,
    this.brightness = 0.0,
    this.contrast = 0.0,
    this.highlights = 0.0,
    this.shadows = 0.0,
    this.whites = 0.0,
    this.blacks = 0.0,
    this.warmth = 0.0,
    this.tint = 0.0,
    this.saturation = 0.0,
    this.vibrance = 0.0,
    this.hsl = const HslAdjustments(),
    this.clarity = 0.0,
    this.texture = 0.0,
    this.dehaze = 0.0,
    this.sharpness = 0.0,
  });

  bool get isIdentity =>
      exposure == 0.0 &&
      brightness == 0.0 &&
      contrast == 0.0 &&
      highlights == 0.0 &&
      shadows == 0.0 &&
      whites == 0.0 &&
      blacks == 0.0 &&
      warmth == 0.0 &&
      tint == 0.0 &&
      saturation == 0.0 &&
      vibrance == 0.0 &&
      hsl.isIdentity &&
      clarity == 0.0 &&
      texture == 0.0 &&
      dehaze == 0.0 &&
      sharpness == 0.0;

  MaskToneAdjustments copyWith({
    double? exposure,
    double? brightness,
    double? contrast,
    double? highlights,
    double? shadows,
    double? whites,
    double? blacks,
    double? warmth,
    double? tint,
    double? saturation,
    double? vibrance,
    HslAdjustments? hsl,
    double? clarity,
    double? texture,
    double? dehaze,
    double? sharpness,
  }) => MaskToneAdjustments(
    exposure: exposure ?? this.exposure,
    brightness: brightness ?? this.brightness,
    contrast: contrast ?? this.contrast,
    highlights: highlights ?? this.highlights,
    shadows: shadows ?? this.shadows,
    whites: whites ?? this.whites,
    blacks: blacks ?? this.blacks,
    warmth: warmth ?? this.warmth,
    tint: tint ?? this.tint,
    saturation: saturation ?? this.saturation,
    vibrance: vibrance ?? this.vibrance,
    hsl: hsl ?? this.hsl,
    clarity: clarity ?? this.clarity,
    texture: texture ?? this.texture,
    dehaze: dehaze ?? this.dehaze,
    sharpness: sharpness ?? this.sharpness,
  );

  Map<String, dynamic> toJson() => {
    'exposure': exposure,
    'brightness': brightness,
    'contrast': contrast,
    'highlights': highlights,
    'shadows': shadows,
    'whites': whites,
    'blacks': blacks,
    'warmth': warmth,
    'tint': tint,
    'saturation': saturation,
    'vibrance': vibrance,
    'hsl': hsl.toJson(),
    'clarity': clarity,
    'texture': texture,
    'dehaze': dehaze,
    'sharpness': sharpness,
  };

  factory MaskToneAdjustments.fromJson(Map<String, dynamic> json) =>
      MaskToneAdjustments(
        exposure: (json['exposure'] as num?)?.toDouble() ?? 0.0,
        brightness: (json['brightness'] as num?)?.toDouble() ?? 0.0,
        contrast: (json['contrast'] as num?)?.toDouble() ?? 0.0,
        highlights: (json['highlights'] as num?)?.toDouble() ?? 0.0,
        shadows: (json['shadows'] as num?)?.toDouble() ?? 0.0,
        whites: (json['whites'] as num?)?.toDouble() ?? 0.0,
        blacks: (json['blacks'] as num?)?.toDouble() ?? 0.0,
        warmth: (json['warmth'] as num?)?.toDouble() ?? 0.0,
        tint: (json['tint'] as num?)?.toDouble() ?? 0.0,
        saturation: (json['saturation'] as num?)?.toDouble() ?? 0.0,
        vibrance: (json['vibrance'] as num?)?.toDouble() ?? 0.0,
        hsl: json['hsl'] != null
            ? HslAdjustments.fromJson(Map<String, dynamic>.from(json['hsl'] as Map))
            : const HslAdjustments(),
        clarity: (json['clarity'] as num?)?.toDouble() ?? 0.0,
        texture: (json['texture'] as num?)?.toDouble() ?? 0.0,
        dehaze: (json['dehaze'] as num?)?.toDouble() ?? 0.0,
        sharpness: (json['sharpness'] as num?)?.toDouble() ?? 0.0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaskToneAdjustments &&
          runtimeType == other.runtimeType &&
          exposure == other.exposure &&
          brightness == other.brightness &&
          contrast == other.contrast &&
          highlights == other.highlights &&
          shadows == other.shadows &&
          whites == other.whites &&
          blacks == other.blacks &&
          warmth == other.warmth &&
          tint == other.tint &&
          saturation == other.saturation &&
          vibrance == other.vibrance &&
          hsl == other.hsl &&
          clarity == other.clarity &&
          texture == other.texture &&
          dehaze == other.dehaze &&
          sharpness == other.sharpness;

  @override
  int get hashCode => Object.hashAll([
    exposure,
    brightness,
    contrast,
    highlights,
    shadows,
    whites,
    blacks,
    warmth,
    tint,
    saturation,
    vibrance,
    hsl,
    clarity,
    texture,
    dehaze,
    sharpness,
  ]);
}

/// A selective mask layer.
@immutable
class SelectiveMask {
  final String id;
  final String name;
  final MaskType type;
  final bool inverted;
  final double opacity; // 0.0 .. 1.0
  final double density; // 0.0 .. 1.0 (mask density scaling)
  final double feather; // 0.0 .. 1.0 (edge softness / feathering)
  final bool isVisible;
  final List<MaskPoint> brushPoints;
  final Uint8List? maskBytes; // 8-bit alpha buffer [0 .. 255]
  final int? maskWidth;
  final int? maskHeight;
  final LinearGradientData linearData;
  final RadialGradientData radialData;
  final MaskToneAdjustments adjustments;

  const SelectiveMask({
    required this.id,
    required this.name,
    required this.type,
    this.inverted = false,
    this.opacity = 1.0,
    this.density = 1.0,
    this.feather = 0.0,
    this.isVisible = true,
    this.brushPoints = const [],
    this.maskBytes,
    this.maskWidth,
    this.maskHeight,
    this.linearData = const LinearGradientData(),
    this.radialData = const RadialGradientData(),
    this.adjustments = const MaskToneAdjustments(),
  });

  bool get isEmpty {
    switch (type) {
      case MaskType.brush:
        return brushPoints.isEmpty && (maskBytes == null || maskBytes!.isEmpty);
      case MaskType.subject:
        return maskBytes == null || maskBytes!.isEmpty;
      case MaskType.linearGradient:
      case MaskType.radialGradient:
        return false;
    }
  }

  SelectiveMask copyWith({
    String? id,
    String? name,
    MaskType? type,
    bool? inverted,
    double? opacity,
    double? density,
    double? feather,
    bool? isVisible,
    List<MaskPoint>? brushPoints,
    Uint8List? maskBytes,
    int? maskWidth,
    int? maskHeight,
    LinearGradientData? linearData,
    RadialGradientData? radialData,
    MaskToneAdjustments? adjustments,
  }) => SelectiveMask(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    inverted: inverted ?? this.inverted,
    opacity: opacity ?? this.opacity,
    density: density ?? this.density,
    feather: feather ?? this.feather,
    isVisible: isVisible ?? this.isVisible,
    brushPoints: brushPoints ?? this.brushPoints,
    maskBytes: maskBytes ?? this.maskBytes,
    maskWidth: maskWidth ?? this.maskWidth,
    maskHeight: maskHeight ?? this.maskHeight,
    linearData: linearData ?? this.linearData,
    radialData: radialData ?? this.radialData,
    adjustments: adjustments ?? this.adjustments,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'inverted': inverted,
    'opacity': opacity,
    'density': density,
    'feather': feather,
    'isVisible': isVisible,
    'brushPoints': brushPoints.map((p) => p.toJson()).toList(),
    'maskBytes': maskBytes != null ? base64Encode(maskBytes!) : null,
    'maskWidth': maskWidth,
    'maskHeight': maskHeight,
    'linearData': linearData.toJson(),
    'radialData': radialData.toJson(),
    'adjustments': adjustments.toJson(),
  };

  factory SelectiveMask.fromJson(Map<String, dynamic> json) => SelectiveMask(
    id: json['id'] as String,
    name: json['name'] as String? ?? 'Mask',
    type: MaskType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => MaskType.brush,
    ),
    inverted: json['inverted'] as bool? ?? false,
    opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
    density: (json['density'] as num?)?.toDouble() ?? 1.0,
    feather: (json['feather'] as num?)?.toDouble() ?? 0.0,
    isVisible: json['isVisible'] as bool? ?? true,
    brushPoints:
        (json['brushPoints'] as List?)
            ?.map((e) => MaskPoint.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        const [],
    maskBytes: json['maskBytes'] != null
        ? Uint8List.fromList(base64Decode(json['maskBytes'] as String))
        : null,
    maskWidth: (json['maskWidth'] as num?)?.toInt(),
    maskHeight: (json['maskHeight'] as num?)?.toInt(),
    linearData: json['linearData'] != null
        ? LinearGradientData.fromJson(Map<String, dynamic>.from(json['linearData'] as Map))
        : const LinearGradientData(),
    radialData: json['radialData'] != null
        ? RadialGradientData.fromJson(Map<String, dynamic>.from(json['radialData'] as Map))
        : const RadialGradientData(),
    adjustments: json['adjustments'] != null
        ? MaskToneAdjustments.fromJson(Map<String, dynamic>.from(json['adjustments'] as Map))
        : const MaskToneAdjustments(),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectiveMask &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          type == other.type &&
          inverted == other.inverted &&
          (opacity - other.opacity).abs() < 1e-4 &&
          (density - other.density).abs() < 1e-4 &&
          (feather - other.feather).abs() < 1e-4 &&
          isVisible == other.isVisible &&
          listEquals(brushPoints, other.brushPoints) &&
          maskWidth == other.maskWidth &&
          maskHeight == other.maskHeight &&
          (maskBytes == null && other.maskBytes == null ||
              maskBytes != null &&
                  other.maskBytes != null &&
                  listEquals(maskBytes, other.maskBytes)) &&
          linearData == other.linearData &&
          radialData == other.radialData &&
          adjustments == other.adjustments;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    inverted,
    (opacity * 100).round(),
    (density * 100).round(),
    (feather * 100).round(),
    isVisible,
    Object.hashAll(brushPoints),
    linearData,
    radialData,
    adjustments,
  );
}
