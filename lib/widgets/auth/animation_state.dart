import 'dart:ui';
import 'timeline_data.dart';

class AnimationState {
  final double t;
  final double T;
  final BeatState beat;
  final double emailShakeX;
  final double phoneOpacity;
  final double buttonPressScale;
  final double spinnerAngle;
  final double titleBlur;
  final bool isTitleDone;
  final bool isSubtitleDone;
  final bool isSubtitleError;
  final bool tapActive;
  final Offset tapPosition;
  final double tapScale;
  final double tapOpacity;
  final double fadeOut;
  final bool isError;
  final bool isSuccess;
  final bool isLoading;
  final bool isValid;

  const AnimationState({
    required this.t,
    required this.T,
    required this.beat,
    required this.emailShakeX,
    required this.phoneOpacity,
    required this.buttonPressScale,
    required this.spinnerAngle,
    required this.titleBlur,
    required this.isTitleDone,
    required this.isSubtitleDone,
    required this.isSubtitleError,
    required this.tapActive,
    required this.tapPosition,
    required this.tapScale,
    required this.tapOpacity,
    required this.fadeOut,
    this.isError = false,
    this.isSuccess = false,
    this.isLoading = false,
    this.isValid = false,
  });

  factory AnimationState.initial() {
    return const AnimationState(
      t: 0.0,
      T: 0.0,
      beat: BeatState(
        nameLength: 0,
        email: '',
        passwordDots: 0,
        focusedField: -1,
        isError: false,
        errorOpacity: 0.0,
        isValid: false,
        isLoading: false,
        isDone: false,
      ),
      emailShakeX: 0.0,
      phoneOpacity: 1.0,
      buttonPressScale: 1.0,
      spinnerAngle: 0.0,
      titleBlur: 0.0,
      isTitleDone: false,
      isSubtitleDone: false,
      isSubtitleError: false,
      tapActive: false,
      tapPosition: Offset.zero,
      tapScale: 0.0,
      tapOpacity: 0.0,
      fadeOut: 0.0,
      isError: false,
      isSuccess: false,
      isLoading: false,
      isValid: false,
    );
  }
}
