import '../models/edit_state.dart';

class PresetItem {
  final String id;
  final String name;
  final String description;
  final EditState state;

  const PresetItem({
    required this.id,
    required this.name,
    required this.description,
    required this.state,
  });
}

class PresetCatalogue {
  static const List<PresetItem> presets = [
    PresetItem(
      id: 'portra_warm',
      name: 'Portra Warm',
      description: 'Gentle warmth, soft skin highlights, and fine analog character',
      state: EditState(
        presetName: 'Portra Warm',
        tune: TuneAdjustments(
          warmth: 24.0,
          tint: 6.0,
          highlights: -12.0,
          shadows: 14.0,
          contrast: -8.0,
          saturation: 8.0,
        ),
        effects: EffectsAdjustments(
          grain: 15.0,
        ),
      ),
    ),
    PresetItem(
      id: 'noir_contrast',
      name: 'Noir Contrast',
      description: 'Deep blacks, commanding midtone contrast, and crisp monochrome tone',
      state: EditState(
        presetName: 'Noir Contrast',
        tune: TuneAdjustments(
          contrast: 32.0,
          highlights: -15.0,
          shadows: -10.0,
        ),
        details: DetailsAdjustments(
          sharpening: 25.0,
          structure: 20.0,
        ),
        effects: EffectsAdjustments(
          bwMode: true,
          grain: 20.0,
        ),
      ),
    ),
    PresetItem(
      id: 'nordic_crisp',
      name: 'Nordic Crisp',
      description: 'Cool tones, clean whites, and razor-sharp clarity',
      state: EditState(
        presetName: 'Nordic Crisp',
        tune: TuneAdjustments(
          warmth: -20.0,
          tint: -5.0,
          brightness: 6.0,
          contrast: 14.0,
          highlights: 10.0,
          shadows: 8.0,
        ),
        details: DetailsAdjustments(
          sharpening: 35.0,
          structure: 15.0,
        ),
      ),
    ),
    PresetItem(
      id: 'golden_hour',
      name: 'Golden Hour',
      description: 'Radiant sunset glow, lifted shadows, and warm ambiance',
      state: EditState(
        presetName: 'Golden Hour',
        tune: TuneAdjustments(
          warmth: 40.0,
          tint: 10.0,
          ambiance: 20.0,
          shadows: 18.0,
          saturation: 15.0,
        ),
        effects: EffectsAdjustments(
          bloom: 22.0,
        ),
      ),
    ),
    PresetItem(
      id: 'cinematic_moody',
      name: 'Cinematic Moody',
      description: 'Atmospheric split-tones with lifted blacks and deep mood',
      state: EditState(
        presetName: 'Cinematic Moody',
        tune: TuneAdjustments(
          contrast: 18.0,
          saturation: -18.0,
          highlights: -20.0,
          shadows: 15.0,
        ),
        effects: EffectsAdjustments(
          drama: 30.0,
          vintage: 20.0,
        ),
        vignette: VignetteAdjustments(
          amount: -45.0,
          radius: 55.0,
          feather: 50.0,
        ),
      ),
    ),
    PresetItem(
      id: 'vibrant_nature',
      name: 'Vibrant Nature',
      description: 'Punchy vivid colors, deep dynamic range, and rich sky greens',
      state: EditState(
        presetName: 'Vibrant Nature',
        tune: TuneAdjustments(
          saturation: 35.0,
          contrast: 15.0,
          ambiance: 18.0,
          highlights: -10.0,
          shadows: 12.0,
        ),
        details: DetailsAdjustments(
          sharpening: 20.0,
          structure: 25.0,
        ),
      ),
    ),
    PresetItem(
      id: 'vintage_70s',
      name: 'Vintage 70s',
      description: 'Retro washed warmth, subtle fade, and heavy analog film grain',
      state: EditState(
        presetName: 'Vintage 70s',
        tune: TuneAdjustments(
          warmth: 28.0,
          tint: 12.0,
          contrast: -12.0,
          saturation: -10.0,
        ),
        effects: EffectsAdjustments(
          vintage: 45.0,
          grain: 40.0,
        ),
        vignette: VignetteAdjustments(
          amount: -35.0,
          radius: 50.0,
        ),
      ),
    ),
  ];
}
