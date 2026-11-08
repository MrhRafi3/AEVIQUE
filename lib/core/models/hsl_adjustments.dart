import 'package:flutter/foundation.dart';

/// The 8 standard color ranges for professional HSL color mixing.
enum HslColorBand {
  red,
  orange,
  yellow,
  green,
  aqua,
  blue,
  purple,
  magenta,
}

/// Extension on [HslColorBand] providing center hue in degrees and display name.
extension HslColorBandExtension on HslColorBand {
  String get displayName {
    switch (this) {
      case HslColorBand.red:
        return 'Red';
      case HslColorBand.orange:
        return 'Orange';
      case HslColorBand.yellow:
        return 'Yellow';
      case HslColorBand.green:
        return 'Green';
      case HslColorBand.aqua:
        return 'Aqua';
      case HslColorBand.blue:
        return 'Blue';
      case HslColorBand.purple:
        return 'Purple';
      case HslColorBand.magenta:
        return 'Magenta';
    }
  }

  /// Center hue angle in degrees [0 .. 360).
  double get centerHueDegrees {
    switch (this) {
      case HslColorBand.red:
        return 0.0;
      case HslColorBand.orange:
        return 30.0;
      case HslColorBand.yellow:
        return 60.0;
      case HslColorBand.green:
        return 120.0;
      case HslColorBand.aqua:
        return 180.0;
      case HslColorBand.blue:
        return 240.0;
      case HslColorBand.purple:
        return 280.0;
      case HslColorBand.magenta:
        return 320.0;
    }
  }
}

/// Hue, Saturation, Luminance adjustment for an individual color range.
@immutable
class HslChannelAdjustment {
  final double hue; // -100.0 .. 100.0 (shifts hue towards adjacent colors)
  final double saturation; // -100.0 .. 100.0 (reduces or boosts saturation)
  final double luminance; // -100.0 .. 100.0 (darkens or brightens that color range)

  const HslChannelAdjustment({
    this.hue = 0.0,
    this.saturation = 0.0,
    this.luminance = 0.0,
  });

  bool get isIdentity =>
      hue.abs() < 1e-4 && saturation.abs() < 1e-4 && luminance.abs() < 1e-4;

  HslChannelAdjustment copyWith({
    double? hue,
    double? saturation,
    double? luminance,
  }) => HslChannelAdjustment(
    hue: hue ?? this.hue,
    saturation: saturation ?? this.saturation,
    luminance: luminance ?? this.luminance,
  );

  Map<String, dynamic> toJson() => {
    'hue': hue,
    'saturation': saturation,
    'luminance': luminance,
  };

  factory HslChannelAdjustment.fromJson(Map<String, dynamic> json) =>
      HslChannelAdjustment(
        hue: (json['hue'] as num?)?.toDouble() ?? 0.0,
        saturation: (json['saturation'] as num?)?.toDouble() ?? 0.0,
        luminance: (json['luminance'] as num?)?.toDouble() ?? 0.0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HslChannelAdjustment &&
          runtimeType == other.runtimeType &&
          (hue - other.hue).abs() < 1e-4 &&
          (saturation - other.saturation).abs() < 1e-4 &&
          (luminance - other.luminance).abs() < 1e-4;

  @override
  int get hashCode => Object.hash(
    (hue * 10).round(),
    (saturation * 10).round(),
    (luminance * 10).round(),
  );
}

/// Complete 8-channel HSL Color Mixer model.
@immutable
class HslAdjustments {
  final HslChannelAdjustment red;
  final HslChannelAdjustment orange;
  final HslChannelAdjustment yellow;
  final HslChannelAdjustment green;
  final HslChannelAdjustment aqua;
  final HslChannelAdjustment blue;
  final HslChannelAdjustment purple;
  final HslChannelAdjustment magenta;

  const HslAdjustments({
    this.red = const HslChannelAdjustment(),
    this.orange = const HslChannelAdjustment(),
    this.yellow = const HslChannelAdjustment(),
    this.green = const HslChannelAdjustment(),
    this.aqua = const HslChannelAdjustment(),
    this.blue = const HslChannelAdjustment(),
    this.purple = const HslChannelAdjustment(),
    this.magenta = const HslChannelAdjustment(),
  });

  bool get isIdentity =>
      red.isIdentity &&
      orange.isIdentity &&
      yellow.isIdentity &&
      green.isIdentity &&
      aqua.isIdentity &&
      blue.isIdentity &&
      purple.isIdentity &&
      magenta.isIdentity;

  HslChannelAdjustment getBand(HslColorBand band) {
    switch (band) {
      case HslColorBand.red:
        return red;
      case HslColorBand.orange:
        return orange;
      case HslColorBand.yellow:
        return yellow;
      case HslColorBand.green:
        return green;
      case HslColorBand.aqua:
        return aqua;
      case HslColorBand.blue:
        return blue;
      case HslColorBand.purple:
        return purple;
      case HslColorBand.magenta:
        return magenta;
    }
  }

  HslAdjustments updateBand(
    HslColorBand band, {
    double? hue,
    double? saturation,
    double? luminance,
  }) {
    final current = getBand(band);
    final updated = current.copyWith(
      hue: hue,
      saturation: saturation,
      luminance: luminance,
    );
    switch (band) {
      case HslColorBand.red:
        return copyWith(red: updated);
      case HslColorBand.orange:
        return copyWith(orange: updated);
      case HslColorBand.yellow:
        return copyWith(yellow: updated);
      case HslColorBand.green:
        return copyWith(green: updated);
      case HslColorBand.aqua:
        return copyWith(aqua: updated);
      case HslColorBand.blue:
        return copyWith(blue: updated);
      case HslColorBand.purple:
        return copyWith(purple: updated);
      case HslColorBand.magenta:
        return copyWith(magenta: updated);
    }
  }

  HslAdjustments resetBand(HslColorBand band) {
    return updateBand(band, hue: 0.0, saturation: 0.0, luminance: 0.0);
  }

  HslAdjustments copyWith({
    HslChannelAdjustment? red,
    HslChannelAdjustment? orange,
    HslChannelAdjustment? yellow,
    HslChannelAdjustment? green,
    HslChannelAdjustment? aqua,
    HslChannelAdjustment? blue,
    HslChannelAdjustment? purple,
    HslChannelAdjustment? magenta,
  }) => HslAdjustments(
    red: red ?? this.red,
    orange: orange ?? this.orange,
    yellow: yellow ?? this.yellow,
    green: green ?? this.green,
    aqua: aqua ?? this.aqua,
    blue: blue ?? this.blue,
    purple: purple ?? this.purple,
    magenta: magenta ?? this.magenta,
  );

  Map<String, dynamic> toJson() => {
    'red': red.toJson(),
    'orange': orange.toJson(),
    'yellow': yellow.toJson(),
    'green': green.toJson(),
    'aqua': aqua.toJson(),
    'blue': blue.toJson(),
    'purple': purple.toJson(),
    'magenta': magenta.toJson(),
  };

  factory HslAdjustments.fromJson(Map<String, dynamic> json) => HslAdjustments(
    red: json['red'] != null
        ? HslChannelAdjustment.fromJson(Map<String, dynamic>.from(json['red'] as Map))
        : const HslChannelAdjustment(),
    orange: json['orange'] != null
        ? HslChannelAdjustment.fromJson(Map<String, dynamic>.from(json['orange'] as Map))
        : const HslChannelAdjustment(),
    yellow: json['yellow'] != null
        ? HslChannelAdjustment.fromJson(Map<String, dynamic>.from(json['yellow'] as Map))
        : const HslChannelAdjustment(),
    green: json['green'] != null
        ? HslChannelAdjustment.fromJson(Map<String, dynamic>.from(json['green'] as Map))
        : const HslChannelAdjustment(),
    aqua: json['aqua'] != null
        ? HslChannelAdjustment.fromJson(Map<String, dynamic>.from(json['aqua'] as Map))
        : const HslChannelAdjustment(),
    blue: json['blue'] != null
        ? HslChannelAdjustment.fromJson(Map<String, dynamic>.from(json['blue'] as Map))
        : const HslChannelAdjustment(),
    purple: json['purple'] != null
        ? HslChannelAdjustment.fromJson(Map<String, dynamic>.from(json['purple'] as Map))
        : const HslChannelAdjustment(),
    magenta: json['magenta'] != null
        ? HslChannelAdjustment.fromJson(Map<String, dynamic>.from(json['magenta'] as Map))
        : const HslChannelAdjustment(),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HslAdjustments &&
          runtimeType == other.runtimeType &&
          red == other.red &&
          orange == other.orange &&
          yellow == other.yellow &&
          green == other.green &&
          aqua == other.aqua &&
          blue == other.blue &&
          purple == other.purple &&
          magenta == other.magenta;

  @override
  int get hashCode => Object.hash(
    red,
    orange,
    yellow,
    green,
    aqua,
    blue,
    purple,
    magenta,
  );
}
