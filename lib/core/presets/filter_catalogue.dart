import '../models/edit_state.dart';

enum FilterCategory {
  all,
  signature,
  portrait,
  nature,
  everyday,
  food,
  travel,
  film,
  bw,
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
    final blendedTune = TuneAdjustments(
      exposure: sTune.exposure * t,
      brightness: sTune.brightness * t,
      contrast: sTune.contrast * t,
      saturation: sTune.saturation * t,
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
      bwMode: t >= 0.5 ? sEffects.bwMode : false,
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
    );
  }
}

class FilterCatalogue {
  static const List<LumaFilter> allFilters = [
    // ----------------------------------------------------
    // SIGNATURE VIVID (iPhone-Inspired)
    // ----------------------------------------------------
    LumaFilter(
      id: 'signature_vivid',
      name: 'Signature Vivid',
      category: FilterCategory.signature,
      description:
          'Dynamic vivid look: punchy vibrance, controlled highlights, and crisp natural skin',
      state: EditState(
        presetName: 'Signature Vivid',
        tune: TuneAdjustments(
          highlights: -12.0,
          shadows: 14.0,
          contrast: 14.0,
          vibrance: 26.0,
          saturation: 8.0,
          warmth: 4.0,
          clarity: 10.0,
        ),
        details: DetailsAdjustments(sharpening: 16.0, structure: 18.0),
      ),
    ),
    LumaFilter(
      id: 'vivid_warm',
      name: 'Vivid Warm',
      category: FilterCategory.signature,
      description:
          'Sunny golden daylight with rich saturation and warm highlights',
      state: EditState(
        presetName: 'Vivid Warm',
        tune: TuneAdjustments(
          warmth: 16.0,
          tint: 6.0,
          vibrance: 22.0,
          contrast: 12.0,
          highlights: -10.0,
          shadows: 12.0,
        ),
        details: DetailsAdjustments(sharpening: 15.0, structure: 14.0),
      ),
    ),
    LumaFilter(
      id: 'vivid_cool',
      name: 'Vivid Cool',
      category: FilterCategory.signature,
      description:
          'Crisp, clean, cool tones with controlled skies and sharp definition',
      state: EditState(
        presetName: 'Vivid Cool',
        tune: TuneAdjustments(
          warmth: -14.0,
          tint: -4.0,
          vibrance: 20.0,
          contrast: 14.0,
          highlights: 6.0,
          shadows: 8.0,
        ),
        details: DetailsAdjustments(sharpening: 20.0, structure: 16.0),
      ),
    ),

    // ----------------------------------------------------
    // PORTRAIT & HUMAN SKIN
    // ----------------------------------------------------
    LumaFilter(
      id: 'portrait_natural',
      name: 'Natural Portrait',
      category: FilterCategory.portrait,
      description: 'Faithful skin tone balance with gentle highlight rolloff',
      state: EditState(
        presetName: 'Natural Portrait',
        tune: TuneAdjustments(
          warmth: 8.0,
          tint: 4.0,
          highlights: -15.0,
          shadows: 14.0,
          contrast: -6.0,
          vibrance: 8.0,
        ),
        details: DetailsAdjustments(sharpening: 10.0),
      ),
    ),
    LumaFilter(
      id: 'portrait_vivid',
      name: 'Portrait Vivid',
      category: FilterCategory.portrait,
      description: 'Lively eyes and lips with protected natural skin hues',
      state: EditState(
        presetName: 'Portrait Vivid',
        tune: TuneAdjustments(
          vibrance: 24.0,
          contrast: 12.0,
          warmth: 6.0,
          shadows: 10.0,
          clarity: 10.0,
        ),
        details: DetailsAdjustments(sharpening: 16.0),
      ),
    ),
    LumaFilter(
      id: 'portrait_soft_skin',
      name: 'Soft Skin Tone',
      category: FilterCategory.portrait,
      description: 'Dreamy highlight diffusion and flattering gentle contrast',
      state: EditState(
        presetName: 'Soft Skin Tone',
        tune: TuneAdjustments(
          contrast: -10.0,
          highlights: -14.0,
          shadows: 12.0,
          warmth: 10.0,
        ),
        effects: EffectsAdjustments(bloom: 18.0),
      ),
    ),
    LumaFilter(
      id: 'portrait_warm',
      name: 'Warm Portrait',
      category: FilterCategory.portrait,
      description: 'Radiant amber skin tones and cozy studio warmth',
      state: EditState(
        presetName: 'Warm Portrait',
        tune: TuneAdjustments(
          warmth: 24.0,
          tint: 8.0,
          ambiance: 12.0,
          shadows: 12.0,
          contrast: -4.0,
        ),
      ),
    ),
    LumaFilter(
      id: 'portrait_studio_clean',
      name: 'Studio Clean',
      category: FilterCategory.portrait,
      description: 'Crisp commercial studio lighting with clean whites',
      state: EditState(
        presetName: 'Studio Clean',
        tune: TuneAdjustments(
          whites: 16.0,
          contrast: 14.0,
          clarity: 12.0,
          highlights: 8.0,
          shadows: 6.0,
        ),
        details: DetailsAdjustments(sharpening: 20.0),
      ),
    ),
    LumaFilter(
      id: 'portrait_golden',
      name: 'Golden Portrait',
      category: FilterCategory.portrait,
      description: 'Luminous magic-hour glow with soft amber rim light',
      state: EditState(
        presetName: 'Golden Portrait',
        tune: TuneAdjustments(
          warmth: 36.0,
          tint: 12.0,
          ambiance: 18.0,
          shadows: 16.0,
          vibrance: 14.0,
        ),
        effects: EffectsAdjustments(bloom: 22.0),
      ),
    ),
    LumaFilter(
      id: 'portrait_moody',
      name: 'Moody Portrait',
      category: FilterCategory.portrait,
      description: 'Dramatic low-key contrast with muted background tones',
      state: EditState(
        presetName: 'Moody Portrait',
        tune: TuneAdjustments(
          contrast: 22.0,
          shadows: -14.0,
          saturation: -16.0,
          highlights: -10.0,
        ),
        effects: EffectsAdjustments(drama: 25.0),
        vignette: VignetteAdjustments(amount: -35.0, radius: 55.0),
      ),
    ),
    LumaFilter(
      id: 'portrait_bw',
      name: 'B&W Portrait',
      category: FilterCategory.portrait,
      description: 'Classic fine-art monochrome with rich skin gradations',
      state: EditState(
        presetName: 'B&W Portrait',
        tune: TuneAdjustments(contrast: 18.0, shadows: 10.0, highlights: -8.0),
        details: DetailsAdjustments(sharpening: 22.0, structure: 15.0),
        effects: EffectsAdjustments(bwMode: true, grain: 12.0),
      ),
    ),

    // ----------------------------------------------------
    // NATURE & ENVIRONMENT
    // ----------------------------------------------------
    LumaFilter(
      id: 'nature_vivid',
      name: 'Nature Vivid',
      category: FilterCategory.nature,
      description: 'Vibrant foliage, deep blue skies, and high dynamic range',
      state: EditState(
        presetName: 'Nature Vivid',
        tune: TuneAdjustments(
          vibrance: 36.0,
          contrast: 15.0,
          highlights: -14.0,
          shadows: 12.0,
        ),
        details: DetailsAdjustments(structure: 24.0, sharpening: 18.0),
      ),
    ),
    LumaFilter(
      id: 'nature_lush_green',
      name: 'Lush Green',
      category: FilterCategory.nature,
      description:
          'Deep emerald greens and rich foliage depth without clipping',
      state: EditState(
        presetName: 'Lush Green',
        tune: TuneAdjustments(
          warmth: -6.0,
          tint: -10.0,
          vibrance: 32.0,
          contrast: 14.0,
          shadows: 8.0,
        ),
        details: DetailsAdjustments(structure: 18.0),
      ),
    ),
    LumaFilter(
      id: 'nature_forest_deep',
      name: 'Forest Deep',
      category: FilterCategory.nature,
      description: 'Moody alpine woodland tones with shadowed micro-contrast',
      state: EditState(
        presetName: 'Forest Deep',
        tune: TuneAdjustments(
          warmth: -12.0,
          contrast: 22.0,
          saturation: -12.0,
          shadows: -10.0,
        ),
        details: DetailsAdjustments(structure: 25.0),
      ),
    ),
    LumaFilter(
      id: 'nature_blue_sky',
      name: 'Blue Sky',
      category: FilterCategory.nature,
      description: 'Deep royal skies and lifted cloud volume',
      state: EditState(
        presetName: 'Blue Sky',
        tune: TuneAdjustments(
          warmth: -18.0,
          highlights: -20.0,
          vibrance: 26.0,
          clarity: 16.0,
        ),
        details: DetailsAdjustments(structure: 18.0),
      ),
    ),
    LumaFilter(
      id: 'nature_ocean_clarity',
      name: 'Ocean Clarity',
      category: FilterCategory.nature,
      description: 'Aquamarine water clarity with crisp surface definition',
      state: EditState(
        presetName: 'Ocean Clarity',
        tune: TuneAdjustments(
          warmth: -14.0,
          tint: -6.0,
          contrast: 16.0,
          clarity: 22.0,
          whites: 12.0,
        ),
        details: DetailsAdjustments(sharpening: 22.0, structure: 18.0),
      ),
    ),
    LumaFilter(
      id: 'nature_golden_hour',
      name: 'Golden Hour',
      category: FilterCategory.nature,
      description: 'Honeyed late-afternoon sunbeams and lifted amber shadows',
      state: EditState(
        presetName: 'Golden Hour',
        tune: TuneAdjustments(
          warmth: 40.0,
          tint: 12.0,
          ambiance: 20.0,
          shadows: 18.0,
          saturation: 12.0,
        ),
        effects: EffectsAdjustments(bloom: 20.0),
      ),
    ),
    LumaFilter(
      id: 'nature_sunset_glow',
      name: 'Sunset Glow',
      category: FilterCategory.nature,
      description: 'Fiery horizon crimson and saturated twilight tones',
      state: EditState(
        presetName: 'Sunset Glow',
        tune: TuneAdjustments(
          warmth: 36.0,
          tint: 18.0,
          saturation: 15.0,
          highlights: -15.0,
          shadows: 12.0,
        ),
      ),
    ),
    LumaFilter(
      id: 'nature_autumn_warmth',
      name: 'Autumn Warmth',
      category: FilterCategory.nature,
      description: 'Rich russet reds, golden ochres, and crisp cool air',
      state: EditState(
        presetName: 'Autumn Warmth',
        tune: TuneAdjustments(
          warmth: 28.0,
          tint: 12.0,
          vibrance: 24.0,
          contrast: 12.0,
          shadows: 8.0,
        ),
      ),
    ),
    LumaFilter(
      id: 'nature_mountain_crisp',
      name: 'Mountain Crisp',
      category: FilterCategory.nature,
      description:
          'Atmospheric alpine haze reduction with dramatic edge clarity',
      state: EditState(
        presetName: 'Mountain Crisp',
        tune: TuneAdjustments(
          clarity: 26.0,
          contrast: 16.0,
          warmth: -10.0,
          highlights: 10.0,
        ),
        details: DetailsAdjustments(sharpening: 30.0, structure: 20.0),
      ),
    ),
    LumaFilter(
      id: 'nature_flower_pop',
      name: 'Flower Pop',
      category: FilterCategory.nature,
      description: 'Vivid botanical color pop with velvety shadow rolloff',
      state: EditState(
        presetName: 'Flower Pop',
        tune: TuneAdjustments(
          vibrance: 40.0,
          saturation: 10.0,
          contrast: 10.0,
          clarity: 14.0,
        ),
        details: DetailsAdjustments(sharpening: 18.0),
      ),
    ),

    // ----------------------------------------------------
    // EVERYDAY, FOOD & TRAVEL
    // ----------------------------------------------------
    LumaFilter(
      id: 'everyday_natural',
      name: 'Everyday Natural',
      category: FilterCategory.everyday,
      description:
          'Subtle enhancement that keeps photos feeling completely real',
      state: EditState(
        presetName: 'Everyday Natural',
        tune: TuneAdjustments(
          exposure: 4.0,
          contrast: 6.0,
          vibrance: 12.0,
          clarity: 8.0,
          shadows: 6.0,
        ),
      ),
    ),
    LumaFilter(
      id: 'everyday_clean_bright',
      name: 'Clean Bright',
      category: FilterCategory.everyday,
      description: 'Bright airy lifestyle tones with clean lifted whites',
      state: EditState(
        presetName: 'Clean Bright',
        tune: TuneAdjustments(
          exposure: 12.0,
          highlights: 10.0,
          shadows: 14.0,
          contrast: -6.0,
          vibrance: 10.0,
        ),
      ),
    ),
    LumaFilter(
      id: 'food_fresh',
      name: 'Food Fresh',
      category: FilterCategory.food,
      description:
          'Appetizing food photography: vivid garnish and glistening highlights',
      state: EditState(
        presetName: 'Food Fresh',
        tune: TuneAdjustments(
          warmth: 8.0,
          vibrance: 26.0,
          contrast: 14.0,
          whites: 10.0,
          clarity: 14.0,
        ),
        details: DetailsAdjustments(sharpening: 24.0),
      ),
    ),
    LumaFilter(
      id: 'food_rich',
      name: 'Food Rich',
      category: FilterCategory.food,
      description: 'Deep warm bakery and roasted tones with cozy contrast',
      state: EditState(
        presetName: 'Food Rich',
        tune: TuneAdjustments(
          warmth: 20.0,
          contrast: 18.0,
          ambiance: 16.0,
          saturation: 12.0,
        ),
      ),
    ),
    LumaFilter(
      id: 'travel_vivid',
      name: 'Travel Vivid',
      category: FilterCategory.travel,
      description:
          'High-energy travel snapshot aesthetic with rich architecture',
      state: EditState(
        presetName: 'Travel Vivid',
        tune: TuneAdjustments(
          contrast: 16.0,
          vibrance: 28.0,
          highlights: -12.0,
          shadows: 12.0,
        ),
        details: DetailsAdjustments(sharpening: 20.0, structure: 20.0),
      ),
    ),
    LumaFilter(
      id: 'street_contrast',
      name: 'Street Contrast',
      category: FilterCategory.travel,
      description: 'Punchy documentary street photography with deep shadows',
      state: EditState(
        presetName: 'Street Contrast',
        tune: TuneAdjustments(
          contrast: 28.0,
          clarity: 22.0,
          shadows: -14.0,
          saturation: -8.0,
        ),
        details: DetailsAdjustments(sharpening: 24.0),
      ),
    ),
    LumaFilter(
      id: 'urban_clean',
      name: 'Urban Clean',
      category: FilterCategory.everyday,
      description:
          'Modern glass, concrete, and steel with neutral cooler balance',
      state: EditState(
        presetName: 'Urban Clean',
        tune: TuneAdjustments(
          warmth: -10.0,
          contrast: 14.0,
          clarity: 18.0,
          whites: 12.0,
        ),
      ),
    ),
    LumaFilter(
      id: 'soft_pastel',
      name: 'Soft Pastel',
      category: FilterCategory.everyday,
      description: 'Gentle low-contrast pastel tones with creamy highlights',
      state: EditState(
        presetName: 'Soft Pastel',
        tune: TuneAdjustments(
          contrast: -18.0,
          saturation: -12.0,
          highlights: -8.0,
          exposure: 8.0,
        ),
        effects: EffectsAdjustments(bloom: 22.0),
      ),
    ),
    LumaFilter(
      id: 'film_warm',
      name: 'Film Warm',
      category: FilterCategory.film,
      description: 'Classic 35mm film warm palette with organic analog grain',
      state: EditState(
        presetName: 'Film Warm',
        tune: TuneAdjustments(warmth: 24.0, contrast: -6.0, shadows: 10.0),
        effects: EffectsAdjustments(vintage: 26.0, grain: 22.0),
      ),
    ),
    LumaFilter(
      id: 'matte_fade',
      name: 'Matte Fade',
      category: FilterCategory.film,
      description:
          'Lifted matte black levels for an indie editorial print look',
      state: EditState(
        presetName: 'Matte Fade',
        tune: TuneAdjustments(contrast: -12.0, saturation: -14.0),
        effects: EffectsAdjustments(vintage: 45.0, grain: 16.0),
      ),
    ),

    // ----------------------------------------------------
    // MONOCHROME & CREATIVE
    // ----------------------------------------------------
    LumaFilter(
      id: 'bw_classic',
      name: 'Classic B&W',
      category: FilterCategory.bw,
      description: 'Balanced Rec. 709 monochrome conversion for all genres',
      state: EditState(
        presetName: 'Classic B&W',
        tune: TuneAdjustments(contrast: 14.0, highlights: -6.0, shadows: 6.0),
        details: DetailsAdjustments(sharpening: 16.0),
        effects: EffectsAdjustments(bwMode: true),
      ),
    ),
    LumaFilter(
      id: 'bw_high_contrast',
      name: 'High Contrast B&W',
      category: FilterCategory.bw,
      description:
          'Bold inky blacks, bright whites, and striking geometric lines',
      state: EditState(
        presetName: 'High Contrast B&W',
        tune: TuneAdjustments(contrast: 38.0, shadows: -16.0, whites: 14.0),
        details: DetailsAdjustments(sharpening: 25.0, structure: 24.0),
        effects: EffectsAdjustments(bwMode: true),
      ),
    ),
    LumaFilter(
      id: 'bw_soft',
      name: 'Soft Monochrome',
      category: FilterCategory.bw,
      description: 'Delicate silvery tones with gentle midtones and soft glow',
      state: EditState(
        presetName: 'Soft Monochrome',
        tune: TuneAdjustments(
          contrast: -10.0,
          highlights: -12.0,
          shadows: 14.0,
        ),
        effects: EffectsAdjustments(bwMode: true, bloom: 16.0),
      ),
    ),
    LumaFilter(
      id: 'silver_tone',
      name: 'Silver Tone',
      category: FilterCategory.bw,
      description: 'Luminous silver-halide darkroom print aesthetic',
      state: EditState(
        presetName: 'Silver Tone',
        tune: TuneAdjustments(contrast: 16.0, whites: 16.0, clarity: 16.0),
        details: DetailsAdjustments(sharpening: 20.0, structure: 18.0),
        effects: EffectsAdjustments(bwMode: true, grain: 14.0),
      ),
    ),
    LumaFilter(
      id: 'vintage_film_classic',
      name: 'Vintage Film',
      category: FilterCategory.film,
      description: 'Washed 1970s tones with faded blacks and analog grain',
      state: EditState(
        presetName: 'Vintage Film',
        tune: TuneAdjustments(
          warmth: 20.0,
          tint: 10.0,
          contrast: -10.0,
          saturation: -12.0,
        ),
        effects: EffectsAdjustments(vintage: 40.0, grain: 26.0),
        vignette: VignetteAdjustments(amount: -30.0, radius: 50.0),
      ),
    ),
    LumaFilter(
      id: 'cinematic_cool',
      name: 'Cinematic Cool',
      category: FilterCategory.film,
      description:
          'Nordic thriller aesthetic with cold shadows and sharp drama',
      state: EditState(
        presetName: 'Cinematic Cool',
        tune: TuneAdjustments(
          warmth: -20.0,
          tint: -6.0,
          contrast: 18.0,
          saturation: -14.0,
        ),
        effects: EffectsAdjustments(drama: 26.0),
        vignette: VignetteAdjustments(amount: -35.0, radius: 55.0),
      ),
    ),
    LumaFilter(
      id: 'cinematic_warm',
      name: 'Cinematic Warm',
      category: FilterCategory.film,
      description:
          'Golden movie look with rich midtone contrast and amber shadows',
      state: EditState(
        presetName: 'Cinematic Warm',
        tune: TuneAdjustments(
          warmth: 28.0,
          contrast: 16.0,
          saturation: -10.0,
          shadows: 10.0,
        ),
        effects: EffectsAdjustments(drama: 22.0, vintage: 18.0),
        vignette: VignetteAdjustments(amount: -30.0, radius: 55.0),
      ),
    ),
    LumaFilter(
      id: 'grain_film',
      name: 'Grain Film',
      category: FilterCategory.film,
      description: 'Pronounced analog grain structure on punchy monochrome',
      state: EditState(
        presetName: 'Grain Film',
        tune: TuneAdjustments(contrast: 14.0, shadows: -6.0),
        details: DetailsAdjustments(structure: 22.0),
        effects: EffectsAdjustments(bwMode: true, grain: 58.0),
      ),
    ),
  ];

  static List<LumaFilter> getByCategory(FilterCategory category) {
    if (category == FilterCategory.all) return allFilters;
    return allFilters.where((f) => f.category == category).toList();
  }

  static LumaFilter? findById(String id) {
    try {
      return allFilters.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }
}
