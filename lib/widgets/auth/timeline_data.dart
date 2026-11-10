import 'dart:ui';
import 'animation_constants.dart';
import 'login_content.dart';
import 'math_utils.dart';

class TapEvent {
  final double time;
  final double x;
  final double y;

  const TapEvent(this.time, this.x, this.y);

  Offset get offset => Offset(x, y);
}

class BeatState {
  final int nameLength;
  final String email;
  final int passwordDots;
  final int focusedField; // 0: Name, 1: Email, 2: Password, -1: None
  final bool isError;
  final double errorOpacity;
  final bool isValid;
  final bool isLoading;
  final bool isDone;

  const BeatState({
    required this.nameLength,
    required this.email,
    required this.passwordDots,
    required this.focusedField,
    required this.isError,
    required this.errorOpacity,
    required this.isValid,
    required this.isLoading,
    required this.isDone,
  });

  String get displayedName => RafiLoginContent.name.substring(0, nameLength);
}

abstract final class TimelineData {
  static const List<TapEvent> taps = [
    TapEvent(1.4, 200.0, 400.0), // Name field
    TapEvent(2.7, 200.0, 486.0), // Email field
    TapEvent(4.4, 200.0, 677.0), // "Create account"
    TapEvent(6.3, 300.0, 486.0), // Back to Email
    TapEvent(7.2, 200.0, 588.0), // Password field
    TapEvent(8.7, 200.0, 677.0), // "Create account" again
  ];

  static BeatState getBeat(double t) {
    int nameLength = 0;
    if (t >= 1.7 && t < 2.3) {
      final double progress = (t - 1.7) / (2.3 - 1.7);
      nameLength = (progress * RafiLoginContent.name.length).floor();
    } else if (t >= 2.3) {
      nameLength = RafiLoginContent.name.length;
    }

    String email = '';
    if (t >= 3.0 && t < 4.1) {
      final double progress = (t - 3.0) / (4.1 - 3.0);
      final int len = (progress * RafiLoginContent.emailTypo.length).floor();
      email = RafiLoginContent.emailTypo.substring(0, len);
    } else if (t >= 4.1 && t < 6.5) {
      email = RafiLoginContent.emailTypo;
    } else if (t >= 6.5 && t < 6.9) {
      final double progress = (t - 6.5) / (6.9 - 6.5);
      final int fixLen = (progress * RafiLoginContent.emailFix.length).floor();
      email =
          RafiLoginContent.emailTypo +
          RafiLoginContent.emailFix.substring(0, fixLen);
    } else if (t >= 6.9) {
      email = RafiLoginContent.emailTypo + RafiLoginContent.emailFix;
    }

    int passwordDots = 0;
    if (t >= 7.5 && t < 8.4) {
      final double progress = (t - 7.5) / (8.4 - 7.5);
      passwordDots = (progress * RafiLoginContent.passwordLength).floor();
    } else if (t >= 8.4) {
      passwordDots = RafiLoginContent.passwordLength;
    }

    int focusedField = -1;
    if (t >= 1.4 && t < 2.5) {
      focusedField = 0;
    } else if (t >= 2.7 && t < 4.4) {
      focusedField = 1;
    } else if (t >= 6.3 && t < 7.0) {
      focusedField = 1;
    } else if (t >= 7.2 && t < 8.5) {
      focusedField = 2;
    }

    final bool isError = t >= AnimationConstants.atError && t < AnimationConstants.atErrorEnd;
    final double errorOpacity =
        MathUtils.seg(t, AnimationConstants.atError, 4.75) *
        (1.0 - MathUtils.seg(t, 6.35, AnimationConstants.atErrorEnd));
    final bool isValid = t >= AnimationConstants.atFixed;
    final bool isLoading = t >= AnimationConstants.atLoading && t < AnimationConstants.atDone;
    final bool isDone = t >= AnimationConstants.atDone && t < AnimationConstants.atDoneEnd;

    return BeatState(
      nameLength: nameLength,
      email: email,
      passwordDots: passwordDots,
      focusedField: focusedField,
      isError: isError,
      errorOpacity: errorOpacity,
      isValid: isValid,
      isLoading: isLoading,
      isDone: isDone,
    );
  }
}
