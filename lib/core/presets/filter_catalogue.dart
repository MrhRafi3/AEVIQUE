import '../models/edit_state.dart';

enum FilterCategory {
  all,
  vivid,
  dramatic,
  bw,
  // Backwards compatibility aliases
  signature,
  portrait,
  nature,
}

class LumaFilter {
  final String id;
  final String name;
  final FilterCategory category;
  final String description;
  final EditState state;

  const LumaFilter({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.state,
  });

  /// Blends this filter's parameters with the neutral state according to [intensity] (0.0 .. 100.0).
  /// At 0% intensity, the state is completely neutral (identity).
  /// At 100% intensity, the full filter state is returned.
  EditState blendWithNeutral(double intensity) {
    final t = (intensity / 100.0).clamp(0.0, 1.0);
    if (t <= 0.001) {
      return EditState.identity();
    }

    final sTune = state.tune;
    final isMonochromeFilter = state.effects.bwMode || sTune.saturation <= -99.0;
    final blendedTune = TuneAdjustments(
      exposure: sTune.exposure * t,
      brightness: sTune.brightness * t,
      contrast: sTune.contrast * t,
      saturation: isMonochromeFilter ? (-100.0 * t) : (sTune.saturation * t),
      vibrance: sTune.vibrance * t,
      ambiance: sTune.ambiance * t,
      highlights: sTune.highlights * t,
      shadows: sTune.shadows * t,
      whites: sTune.whites * t,
      blacks: sTune.blacks * t,
      warmth: sTune.warmth * t,
      tint: sTune.tint * t,
      clarity: sTune.clarity * t,
    );

    final sDetails = state.details;
    final blendedDetails = DetailsAdjustments(
      sharpening: sDetails.sharpening * t,
      structure: sDetails.structure * t,
    );

    final sEffects = state.effects;
    final blendedEffects = EffectsAdjustments(
      bwMode: (sEffects.bwMode && t >= 0.999),
      grain: sEffects.grain * t,
      bloom: sEffects.bloom * t,
      vintage: sEffects.vintage * t,
      drama: sEffects.drama * t,
      chromaticAberration: sEffects.chromaticAberration * t,
    );

    final sVig = state.vignette;
    final blendedVig = VignetteAdjustments(
      amount: sVig.amount * t,
      radius: sVig.radius,
      feather: sVig.feather,
      centerX: sVig.centerX,
      centerY: sVig.centerY,
    );

    final sPortrait = state.portrait;
    final blendedPortrait = PortraitAdjustments(
      skinSmooth: sPortrait.skinSmooth * t,
      skinBrighten: sPortrait.skinBrighten * t,
      blemishes: sPortrait.blemishes,
    );

    return EditState(
      filterId: id,
      filterIntensity: intensity,
      presetName: name,
      tune: blendedTune,
      details: blendedDetails,
      effects: blendedEffects,
      vignette: blendedVig,
      curves: state.curves,
      geometry: state.geometry,
      portrait: blendedPortrait,
    );
  }
}

class FilterCatalogue {
  /// The 10 iPhone-inspired core filters:
  /// 1. Original (Neutral)
  /// 2. Vivid
  /// 3. Vivid Warm
  /// 4. Vivid Cool
  /// 5. Dramatic
  /// 6. Dramatic Warm
  /// 7. Dramatic Cool
  /// 8. Mono
  /// 9. Silvertone
  /// 10. Noir
  static const List<LumaFilter> allFilters = [
    // 1. Original (Identity)
    LumaFilter(
      id: 'original',
      name: 'Original',
      category: FilterCategory.all,
      description: 'Original neutral capture without grading or filters',
      state: EditState(),
    ),

    // 2. Vivid (Pure iPhone-Style Vivid - Rich Color, Zero Orange Tint, Skin Tone Protection)
    LumaFilter(
      id: 'vivid',
      name: 'Vivid',
      category: FilterCategory.vivid,
      description:
          'Crisp vibrance, punchy contrast and pure, natural skin tones without warm cast',
      state: EditState(
        presetName: 'Vivid',
        tune: TuneAdjustments(
          exposure: 2.5,
          contrast: 10.0,
          highlights: -18.0,
          shadows: 12.0,
          whites: 5.0,
          blacks: 5.0,
          saturation: 14.0,
          vibrance: 24.0,
          warmth: 0.0,
          tint: 0.0,
          clarity: 12.0,
        ),
        details: DetailsAdjustments(sharpening: 8.0),
      ),
    ),

    // 3. Vivid Warm
    LumaFilter(
      id: 'vivid_warm',
      name: 'Vivid Warm',
      category: FilterCategory.vivid,
      description:
          'Golden hour radiance with warm highlights and luminous shadows',
      state: EditState(
        presetName: 'Vivid Warm',
        tune: TuneAdjustments(
          exposure: 2.5,
          contrast: 10.0,
          highlights: -16.0,
          shadows: 10.0,
          saturation: 12.0,
          vibrance: 20.0,
          warmth: 10.0,
          tint: 2.0,
          clarity: 10.0,
        ),
        details: DetailsAdjustments(sharpening: 8.0),
      ),
    ),

    // 4. Vivid Cool
    LumaFilter(
      id: 'vivid_cool',
      name: 'Vivid Cool',
      category: FilterCategory.vivid,
      description:
          'Crisp clean daylight with cool airy tones and sharp definition',
      state: EditState(
        presetName: 'Vivid Cool',
        tune: TuneAdjustments(
          exposure: 2.5,
          contrast: 12.0,
          highlights: -20.0,
          shadows: 10.0,
          saturation: 12.0,
          vibrance: 22.0,
          warmth: -12.0,
          tint: -2.0,
          clarity: 12.0,
        ),
        details: DetailsAdjustments(sharpening: 8.0),
      ),
    ),

    // 5. Dramatic
    LumaFilter(
      id: 'dramatic',
      name: 'Dramatic',
      category: FilterCategory.dramatic,
      description:
          'High contrast chiaroscuro with deep rich shadows and punchy midtones',
      state: EditState(
        presetName: 'Dramatic',
        tune: TuneAdjustments(
          exposure: -5.0,
          contrast: 30.0,
          highlights: -28.0,
          shadows: -15.0,
          blacks: 16.0,
          saturation: -8.0,
          vibrance: 8.0,
          warmth: -3.0,
          clarity: 20.0,
        ),
        effects: EffectsAdjustments(drama: 24.0),
        details: DetailsAdjustments(sharpening: 12.0),
      ),
    ),

    // 6. Dramatic Warm
    LumaFilter(
      id: 'dramatic_warm',
      name: 'Dramatic Warm',
      category: FilterCategory.dramatic,
      description:
          'Cinematic chiaroscuro bathed in warm golden ambient atmosphere',
      state: EditState(
        presetName: 'Dramatic Warm',
        tune: TuneAdjustments(
          exposure: -5.0,
          contrast: 28.0,
          highlights: -26.0,
          shadows: -12.0,
          blacks: 14.0,
          saturation: -6.0,
          vibrance: 8.0,
          warmth: 12.0,
          tint: 2.0,
          clarity: 18.0,
        ),
        effects: EffectsAdjustments(drama: 20.0),
        details: DetailsAdjustments(sharpening: 12.0),
      ),
    ),

    // 7. Dramatic Cool
    LumaFilter(
      id: 'dramatic_cool',
      name: 'Dramatic Cool',
      category: FilterCategory.dramatic,
      description:
          'Moody cinematic contrast with cool shadow roll-off and moody atmosphere',
      state: EditState(
        presetName: 'Dramatic Cool',
        tune: TuneAdjustments(
          exposure: -5.0,
          contrast: 32.0,
          highlights: -30.0,
          shadows: -12.0,
          blacks: 18.0,
          saturation: -5.0,
          vibrance: 10.0,
          warmth: -16.0,
          tint: -2.0,
          clarity: 20.0,
        ),
        effects: EffectsAdjustments(drama: 20.0),
        details: DetailsAdjustments(sharpening: 12.0),
      ),
    ),

    // 8. Mono
    LumaFilter(
      id: 'mono',
      name: 'Mono',
      category: FilterCategory.bw,
      description:
          'Classic balanced black and white with smooth grayscale tones',
      state: EditState(
        presetName: 'Mono',
        tune: TuneAdjustments(
          exposure: 2.5,
          contrast: 18.0,
          highlights: -20.0,
          shadows: 12.0,
          blacks: 10.0,
          saturation: -100.0,
          clarity: 12.0,
        ),
        effects: EffectsAdjustments(bwMode: true),
        details: DetailsAdjustments(sharpening: 10.0),
      ),
    ),

    // 9. Silvertone
    LumaFilter(
      id: 'silvertone',
      name: 'Silvertone',
      category: FilterCategory.bw,
      description:
          'Luminous high-key silver monochrome with radiant highlights and fine structure',
      state: EditState(
        presetName: 'Silvertone',
        tune: TuneAdjustments(
          exposure: 5.0,
          brightness: 6.0,
          contrast: 10.0,
          highlights: -14.0,
          shadows: 16.0,
          whites: 8.0,
          blacks: -4.0,
          saturation: -100.0,
          clarity: 14.0,
        ),
        effects: EffectsAdjustments(bwMode: true),
        details: DetailsAdjustments(sharpening: 10.0, structure: 10.0),
      ),
    ),

    // 10. Noir
    LumaFilter(
      id: 'noir',
      name: 'Noir',
      category: FilterCategory.bw,
      description:
          'Dramatic film noir with crushed blacks, bold contrast, and fine film grain',
      state: EditState(
        presetName: 'Noir',
        tune: TuneAdjustments(
          exposure: -2.5,
          contrast: 36.0,
          highlights: -22.0,
          shadows: -18.0,
          blacks: -14.0,
          whites: 12.0,
          saturation: -100.0,
          clarity: 22.0,
        ),
        effects: EffectsAdjustments(bwMode: true, grain: 12.0),
        details: DetailsAdjustments(sharpening: 14.0, structure: 14.0),
      ),
    ),
  ];

  static List<LumaFilter> getByCategory(FilterCategory category) {
    if (category == FilterCategory.all) return allFilters;
    if (category == FilterCategory.signature) {
      return allFilters
          .where((f) => f.category == FilterCategory.vivid)
          .toList();
    }
    if (category == FilterCategory.portrait) {
      return allFilters
          .where((f) => f.id == 'vivid' || f.id == 'vivid_warm')
          .toList();
    }
    if (category == FilterCategory.nature) {
      return allFilters
          .where((f) => f.id == 'vivid' || f.id == 'vivid_cool')
          .toList();
    }
    return allFilters.where((f) => f.category == category).toList();
  }

  static LumaFilter? findById(String id) {
    if (id == 'signature_vivid') {
      return findById('vivid');
    }
    try {
      return allFilters.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }
}
