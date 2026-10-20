import 'package:flutter/foundation.dart';

@immutable
class CurvePoint {
  final double x;
  final double y;

  const CurvePoint(this.x, this.y);

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  factory CurvePoint.fromJson(Map<String, dynamic> json) =>
      CurvePoint((json['x'] as num).toDouble(), (json['y'] as num).toDouble());

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurvePoint &&
          runtimeType == other.runtimeType &&
          (x - other.x).abs() < 1e-6 &&
          (y - other.y).abs() < 1e-6;

  @override
  int get hashCode => Object.hash(x.toStringAsFixed(4), y.toStringAsFixed(4));
}

@immutable
class ToneCurves {
  final List<CurvePoint> rgb;
  final List<CurvePoint> red;
  final List<CurvePoint> green;
  final List<CurvePoint> blue;

  const ToneCurves({
    this.rgb = const [CurvePoint(0.0, 0.0), CurvePoint(1.0, 1.0)],
    this.red = const [CurvePoint(0.0, 0.0), CurvePoint(1.0, 1.0)],
    this.green = const [CurvePoint(0.0, 0.0), CurvePoint(1.0, 1.0)],
    this.blue = const [CurvePoint(0.0, 0.0), CurvePoint(1.0, 1.0)],
  });

  bool get isIdentity =>
      _isChannelIdentity(rgb) &&
      _isChannelIdentity(red) &&
      _isChannelIdentity(green) &&
      _isChannelIdentity(blue);

  static bool _isChannelIdentity(List<CurvePoint> points) {
    if (points.length != 2) return false;
    return (points[0].x == 0.0 && points[0].y == 0.0) &&
        (points[1].x == 1.0 && points[1].y == 1.0);
  }

  ToneCurves copyWith({
    List<CurvePoint>? rgb,
    List<CurvePoint>? red,
    List<CurvePoint>? green,
    List<CurvePoint>? blue,
  }) => ToneCurves(
    rgb: rgb ?? this.rgb,
    red: red ?? this.red,
    green: green ?? this.green,
    blue: blue ?? this.blue,
  );

  Map<String, dynamic> toJson() => {
    'rgb': rgb.map((p) => p.toJson()).toList(),
    'red': red.map((p) => p.toJson()).toList(),
    'green': green.map((p) => p.toJson()).toList(),
    'blue': blue.map((p) => p.toJson()).toList(),
  };

  factory ToneCurves.fromJson(Map<String, dynamic> json) => ToneCurves(
    rgb:
        (json['rgb'] as List?)
            ?.map(
              (e) => CurvePoint.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList() ??
        const [CurvePoint(0.0, 0.0), CurvePoint(1.0, 1.0)],
    red:
        (json['red'] as List?)
            ?.map(
              (e) => CurvePoint.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList() ??
        const [CurvePoint(0.0, 0.0), CurvePoint(1.0, 1.0)],
    green:
        (json['green'] as List?)
            ?.map(
              (e) => CurvePoint.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList() ??
        const [CurvePoint(0.0, 0.0), CurvePoint(1.0, 1.0)],
    blue:
        (json['blue'] as List?)
            ?.map(
              (e) => CurvePoint.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList() ??
        const [CurvePoint(0.0, 0.0), CurvePoint(1.0, 1.0)],
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToneCurves &&
          runtimeType == other.runtimeType &&
          listEquals(rgb, other.rgb) &&
          listEquals(red, other.red) &&
          listEquals(green, other.green) &&
          listEquals(blue, other.blue);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(rgb),
    Object.hashAll(red),
    Object.hashAll(green),
    Object.hashAll(blue),
  );
}

@immutable
class TuneAdjustments {
  final double brightness; // -100 .. 100
  final double contrast; // -100 .. 100
  final double saturation; // -100 .. 100
  final double ambiance; // -100 .. 100
  final double highlights; // -100 .. 100
  final double shadows; // -100 .. 100
  final double warmth; // -100 .. 100
  final double tint; // -100 .. 100

  const TuneAdjustments({
    this.brightness = 0.0,
    this.contrast = 0.0,
    this.saturation = 0.0,
    this.ambiance = 0.0,
    this.highlights = 0.0,
    this.shadows = 0.0,
    this.warmth = 0.0,
    this.tint = 0.0,
  });

  bool get isIdentity =>
      brightness == 0.0 &&
      contrast == 0.0 &&
      saturation == 0.0 &&
      ambiance == 0.0 &&
      highlights == 0.0 &&
      shadows == 0.0 &&
      warmth == 0.0 &&
      tint == 0.0;

  TuneAdjustments copyWith({
    double? brightness,
    double? contrast,
    double? saturation,
    double? ambiance,
    double? highlights,
    double? shadows,
    double? warmth,
    double? tint,
  }) => TuneAdjustments(
    brightness: brightness ?? this.brightness,
    contrast: contrast ?? this.contrast,
    saturation: saturation ?? this.saturation,
    ambiance: ambiance ?? this.ambiance,
    highlights: highlights ?? this.highlights,
    shadows: shadows ?? this.shadows,
    warmth: warmth ?? this.warmth,
    tint: tint ?? this.tint,
  );

  Map<String, dynamic> toJson() => {
    'brightness': brightness,
    'contrast': contrast,
    'saturation': saturation,
    'ambiance': ambiance,
    'highlights': highlights,
    'shadows': shadows,
    'warmth': warmth,
    'tint': tint,
  };

  factory TuneAdjustments.fromJson(Map<String, dynamic> json) =>
      TuneAdjustments(
        brightness: (json['brightness'] as num?)?.toDouble() ?? 0.0,
        contrast: (json['contrast'] as num?)?.toDouble() ?? 0.0,
        saturation: (json['saturation'] as num?)?.toDouble() ?? 0.0,
        ambiance: (json['ambiance'] as num?)?.toDouble() ?? 0.0,
        highlights: (json['highlights'] as num?)?.toDouble() ?? 0.0,
        shadows: (json['shadows'] as num?)?.toDouble() ?? 0.0,
        warmth: (json['warmth'] as num?)?.toDouble() ?? 0.0,
        tint: (json['tint'] as num?)?.toDouble() ?? 0.0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TuneAdjustments &&
          runtimeType == other.runtimeType &&
          brightness == other.brightness &&
          contrast == other.contrast &&
          saturation == other.saturation &&
          ambiance == other.ambiance &&
          highlights == other.highlights &&
          shadows == other.shadows &&
          warmth == other.warmth &&
          tint == other.tint;

  @override
  int get hashCode => Object.hash(
    brightness,
    contrast,
    saturation,
    ambiance,
    highlights,
    shadows,
    warmth,
    tint,
  );
}

@immutable
class DetailsAdjustments {
  final double sharpening; // 0 .. 100
  final double structure; // 0 .. 100

  const DetailsAdjustments({this.sharpening = 0.0, this.structure = 0.0});

  bool get isIdentity => sharpening == 0.0 && structure == 0.0;

  DetailsAdjustments copyWith({double? sharpening, double? structure}) =>
      DetailsAdjustments(
        sharpening: sharpening ?? this.sharpening,
        structure: structure ?? this.structure,
      );

  Map<String, dynamic> toJson() => {
    'sharpening': sharpening,
    'structure': structure,
  };

  factory DetailsAdjustments.fromJson(Map<String, dynamic> json) =>
      DetailsAdjustments(
        sharpening: (json['sharpening'] as num?)?.toDouble() ?? 0.0,
        structure: (json['structure'] as num?)?.toDouble() ?? 0.0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DetailsAdjustments &&
          runtimeType == other.runtimeType &&
          sharpening == other.sharpening &&
          structure == other.structure;

  @override
  int get hashCode => Object.hash(sharpening, structure);
}

@immutable
class VignetteAdjustments {
  final double amount; // -100 .. 100 (negative darkens edge, positive lightens)
  final double radius; // 10 .. 100
  final double feather; // 10 .. 100
  final double centerX; // 0.0 .. 1.0
  final double centerY; // 0.0 .. 1.0

  const VignetteAdjustments({
    this.amount = 0.0,
    this.radius = 50.0,
    this.feather = 50.0,
    this.centerX = 0.5,
    this.centerY = 0.5,
  });

  bool get isIdentity => amount == 0.0;

  VignetteAdjustments copyWith({
    double? amount,
    double? radius,
    double? feather,
    double? centerX,
    double? centerY,
  }) => VignetteAdjustments(
    amount: amount ?? this.amount,
    radius: radius ?? this.radius,
    feather: feather ?? this.feather,
    centerX: centerX ?? this.centerX,
    centerY: centerY ?? this.centerY,
  );

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'radius': radius,
    'feather': feather,
    'centerX': centerX,
    'centerY': centerY,
  };

  factory VignetteAdjustments.fromJson(Map<String, dynamic> json) =>
      VignetteAdjustments(
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        radius: (json['radius'] as num?)?.toDouble() ?? 50.0,
        feather: (json['feather'] as num?)?.toDouble() ?? 50.0,
        centerX: (json['centerX'] as num?)?.toDouble() ?? 0.5,
        centerY: (json['centerY'] as num?)?.toDouble() ?? 0.5,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VignetteAdjustments &&
          runtimeType == other.runtimeType &&
          amount == other.amount &&
          radius == other.radius &&
          feather == other.feather &&
          centerX == other.centerX &&
          centerY == other.centerY;

  @override
  int get hashCode => Object.hash(amount, radius, feather, centerX, centerY);
}

@immutable
class GeometryAdjustments {
  final double cropLeft; // 0.0 .. 1.0
  final double cropTop; // 0.0 .. 1.0
  final double cropRight; // 0.0 .. 1.0
  final double cropBottom; // 0.0 .. 1.0
  final int rotationQuarterTurns; // 0, 1, 2, 3 (each is 90 deg clockwise)
  final bool flipHorizontal;
  final bool flipVertical;

  const GeometryAdjustments({
    this.cropLeft = 0.0,
    this.cropTop = 0.0,
    this.cropRight = 1.0,
    this.cropBottom = 1.0,
    this.rotationQuarterTurns = 0,
    this.flipHorizontal = false,
    this.flipVertical = false,
  });

  bool get isIdentity =>
      cropLeft == 0.0 &&
      cropTop == 0.0 &&
      cropRight == 1.0 &&
      cropBottom == 1.0 &&
      (rotationQuarterTurns % 4 == 0) &&
      !flipHorizontal &&
      !flipVertical;

  bool get hasCrop =>
      cropLeft > 0.001 ||
      cropTop > 0.001 ||
      cropRight < 0.999 ||
      cropBottom < 0.999;

  GeometryAdjustments copyWith({
    double? cropLeft,
    double? cropTop,
    double? cropRight,
    double? cropBottom,
    int? rotationQuarterTurns,
    bool? flipHorizontal,
    bool? flipVertical,
  }) => GeometryAdjustments(
    cropLeft: cropLeft ?? this.cropLeft,
    cropTop: cropTop ?? this.cropTop,
    cropRight: cropRight ?? this.cropRight,
    cropBottom: cropBottom ?? this.cropBottom,
    rotationQuarterTurns:
        (rotationQuarterTurns ?? this.rotationQuarterTurns) % 4,
    flipHorizontal: flipHorizontal ?? this.flipHorizontal,
    flipVertical: flipVertical ?? this.flipVertical,
  );

  Map<String, dynamic> toJson() => {
    'cropLeft': cropLeft,
    'cropTop': cropTop,
    'cropRight': cropRight,
    'cropBottom': cropBottom,
    'rotationQuarterTurns': rotationQuarterTurns,
    'flipHorizontal': flipHorizontal,
    'flipVertical': flipVertical,
  };

  factory GeometryAdjustments.fromJson(Map<String, dynamic> json) =>
      GeometryAdjustments(
        cropLeft: (json['cropLeft'] as num?)?.toDouble() ?? 0.0,
        cropTop: (json['cropTop'] as num?)?.toDouble() ?? 0.0,
        cropRight: (json['cropRight'] as num?)?.toDouble() ?? 1.0,
        cropBottom: (json['cropBottom'] as num?)?.toDouble() ?? 1.0,
        rotationQuarterTurns:
            (json['rotationQuarterTurns'] as num?)?.toInt() ?? 0,
        flipHorizontal: json['flipHorizontal'] as bool? ?? false,
        flipVertical: json['flipVertical'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeometryAdjustments &&
          runtimeType == other.runtimeType &&
          cropLeft == other.cropLeft &&
          cropTop == other.cropTop &&
          cropRight == other.cropRight &&
          cropBottom == other.cropBottom &&
          rotationQuarterTurns == other.rotationQuarterTurns &&
          flipHorizontal == other.flipHorizontal &&
          flipVertical == other.flipVertical;

  @override
  int get hashCode => Object.hash(
    cropLeft,
    cropTop,
    cropRight,
    cropBottom,
    rotationQuarterTurns,
    flipHorizontal,
    flipVertical,
  );
}

@immutable
class EffectsAdjustments {
  final bool bwMode;
  final double grain; // 0 .. 100
  final double bloom; // 0 .. 100
  final double vintage; // 0 .. 100
  final double drama; // 0 .. 100
  final double chromaticAberration; // 0 .. 100

  const EffectsAdjustments({
    this.bwMode = false,
    this.grain = 0.0,
    this.bloom = 0.0,
    this.vintage = 0.0,
    this.drama = 0.0,
    this.chromaticAberration = 0.0,
  });

  bool get isIdentity =>
      !bwMode &&
      grain == 0.0 &&
      bloom == 0.0 &&
      vintage == 0.0 &&
      drama == 0.0 &&
      chromaticAberration == 0.0;

  EffectsAdjustments copyWith({
    bool? bwMode,
    double? grain,
    double? bloom,
    double? vintage,
    double? drama,
    double? chromaticAberration,
  }) => EffectsAdjustments(
    bwMode: bwMode ?? this.bwMode,
    grain: grain ?? this.grain,
    bloom: bloom ?? this.bloom,
    vintage: vintage ?? this.vintage,
    drama: drama ?? this.drama,
    chromaticAberration: chromaticAberration ?? this.chromaticAberration,
  );

  Map<String, dynamic> toJson() => {
    'bwMode': bwMode,
    'grain': grain,
    'bloom': bloom,
    'vintage': vintage,
    'drama': drama,
    'chromaticAberration': chromaticAberration,
  };

  factory EffectsAdjustments.fromJson(Map<String, dynamic> json) =>
      EffectsAdjustments(
        bwMode: json['bwMode'] as bool? ?? false,
        grain: (json['grain'] as num?)?.toDouble() ?? 0.0,
        bloom: (json['bloom'] as num?)?.toDouble() ?? 0.0,
        vintage: (json['vintage'] as num?)?.toDouble() ?? 0.0,
        drama: (json['drama'] as num?)?.toDouble() ?? 0.0,
        chromaticAberration:
            (json['chromaticAberration'] as num?)?.toDouble() ?? 0.0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EffectsAdjustments &&
          runtimeType == other.runtimeType &&
          bwMode == other.bwMode &&
          grain == other.grain &&
          bloom == other.bloom &&
          vintage == other.vintage &&
          drama == other.drama &&
          chromaticAberration == other.chromaticAberration;

  @override
  int get hashCode =>
      Object.hash(bwMode, grain, bloom, vintage, drama, chromaticAberration);
}

@immutable
class EditState {
  final TuneAdjustments tune;
  final DetailsAdjustments details;
  final ToneCurves curves;
  final VignetteAdjustments vignette;
  final GeometryAdjustments geometry;
  final EffectsAdjustments effects;
  final String? presetName;

  const EditState({
    this.tune = const TuneAdjustments(),
    this.details = const DetailsAdjustments(),
    this.curves = const ToneCurves(),
    this.vignette = const VignetteAdjustments(),
    this.geometry = const GeometryAdjustments(),
    this.effects = const EffectsAdjustments(),
    this.presetName,
  });

  factory EditState.identity() => const EditState();

  bool get isIdentity =>
      tune.isIdentity &&
      details.isIdentity &&
      curves.isIdentity &&
      vignette.isIdentity &&
      geometry.isIdentity &&
      effects.isIdentity &&
      presetName == null;

  EditState copyWith({
    TuneAdjustments? tune,
    DetailsAdjustments? details,
    ToneCurves? curves,
    VignetteAdjustments? vignette,
    GeometryAdjustments? geometry,
    EffectsAdjustments? effects,
    String? presetName,
    bool clearPreset = false,
  }) => EditState(
    tune: tune ?? this.tune,
    details: details ?? this.details,
    curves: curves ?? this.curves,
    vignette: vignette ?? this.vignette,
    geometry: geometry ?? this.geometry,
    effects: effects ?? this.effects,
    presetName: clearPreset ? null : (presetName ?? this.presetName),
  );

  Map<String, dynamic> toJson() => {
    'tune': tune.toJson(),
    'details': details.toJson(),
    'curves': curves.toJson(),
    'vignette': vignette.toJson(),
    'geometry': geometry.toJson(),
    'effects': effects.toJson(),
    'presetName': presetName,
  };

  factory EditState.fromJson(Map<String, dynamic> json) => EditState(
    tune: json['tune'] != null
        ? TuneAdjustments.fromJson(
            Map<String, dynamic>.from(json['tune'] as Map),
          )
        : const TuneAdjustments(),
    details: json['details'] != null
        ? DetailsAdjustments.fromJson(
            Map<String, dynamic>.from(json['details'] as Map),
          )
        : const DetailsAdjustments(),
    curves: json['curves'] != null
        ? ToneCurves.fromJson(Map<String, dynamic>.from(json['curves'] as Map))
        : const ToneCurves(),
    vignette: json['vignette'] != null
        ? VignetteAdjustments.fromJson(
            Map<String, dynamic>.from(json['vignette'] as Map),
          )
        : const VignetteAdjustments(),
    geometry: json['geometry'] != null
        ? GeometryAdjustments.fromJson(
            Map<String, dynamic>.from(json['geometry'] as Map),
          )
        : const GeometryAdjustments(),
    effects: json['effects'] != null
        ? EffectsAdjustments.fromJson(
            Map<String, dynamic>.from(json['effects'] as Map),
          )
        : const EffectsAdjustments(),
    presetName: json['presetName'] as String?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditState &&
          runtimeType == other.runtimeType &&
          tune == other.tune &&
          details == other.details &&
          curves == other.curves &&
          vignette == other.vignette &&
          geometry == other.geometry &&
          effects == other.effects &&
          presetName == other.presetName;

  @override
  int get hashCode => Object.hash(
    tune,
    details,
    curves,
    vignette,
    geometry,
    effects,
    presetName,
  );
}
