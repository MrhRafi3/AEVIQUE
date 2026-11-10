import 'dart:math' as math;
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'animation_constants.dart';
import 'animation_state.dart';
import 'character_rig.dart';
import 'crew_data.dart';
import 'design_tokens.dart';
import 'math_utils.dart';
import 'organic_shapes.dart';
import 'spring.dart';
import 'timeline_data.dart';

class StarRenderState {
  final StarDefinition definition;
  double scale = 1.0;
  double rotation = 0.0; // in radians

  StarRenderState(this.definition);
}

class RafiAnimationEngine with ChangeNotifier {
  Ticker? _ticker;
  double? _startTime;
  double? _lastTime;

  Offset _look = const Offset(200.0, 420.0);
  Offset _targetLook = const Offset(200.0, 420.0);

  final Spring _worry = Spring(
    k: AnimationConstants.springWorry.$1,
    c: AnimationConstants.springWorry.$2,
  );
  final Spring _joy = Spring(
    k: AnimationConstants.springJoy.$1,
    c: AnimationConstants.springJoy.$2,
  );
  final Spring _relief = Spring(
    k: AnimationConstants.springRelief.$1,
    c: AnimationConstants.springRelief.$2,
  );

  late final List<CharacterRig> rigs;
  late final List<StarRenderState> stars;

  AnimationState _state = AnimationState.initial();
  AnimationState get state => _state;

  bool _isDisposed = false;
  final bool prefersReducedMotion;

  // Reactive state flags
  bool _isError = false;
  bool _isSuccess = false;
  bool _isLoading = false;
  bool _isValid = false;
  BeatState _cachedBeat = AnimationState.initial().beat;

  double? _errorStartTime;
  double? _successStartTime;
  double? _buttonPressTime;
  double? _tapStartTime;
  Offset _tapPosition = Offset.zero;

  // Staggered hops tracking for celebration
  int _hopCount = 0;

  final TextPainter _textPainter = TextPainter(
    textDirection: TextDirection.ltr,
  );
  final Map<String, double> _textWidthCache = {};

  RafiAnimationEngine({
    TickerProvider? vsync,
    this.prefersReducedMotion = false,
  }) {
    rigs = [
      for (int i = 0; i < CrewData.crew.length; i++)
        CharacterRig(CrewData.crew[i], i),
    ];
    stars = CrewData.stars
        .map((s) => StarRenderState(s))
        .toList(growable: false);

    if (prefersReducedMotion) {
      // Settle rigs to resting steady state immediately
      _tickSimulation(1.5, isDirectInit: true);
    } else if (vsync != null) {
      _ticker = vsync.createTicker(_handleTick);
      _ticker!.start();
    }
  }

  void start(TickerProvider vsync) {
    if (prefersReducedMotion) return;
    _ticker?.dispose();
    _ticker = vsync.createTicker(_handleTick);
    _ticker!.start();
  }

  void lookAt(Offset target) {
    _targetLook = target;
  }

  void lookAtField(int fieldIndex, [double textOffset = 0.0]) {
    const double fieldLeft = DesignTokens.fieldInset;
    const double fieldPad = DesignTokens.fieldPaddingHorizontal;
    final double textStartX = fieldLeft + fieldPad + textOffset;

    switch (fieldIndex) {
      case 0: // Name (in 3-field) or Identifier (in 2-field)
        _targetLook = Offset(textStartX.clamp(46.0, 350.0), 388.0);
        break;
      case 1: // Email (in 3-field) or Password (in 2-field)
        _targetLook = Offset(textStartX.clamp(46.0, 350.0), 480.0);
        break;
      case 2: // Password (in 3-field mode)
        _targetLook = Offset(textStartX.clamp(46.0, 350.0), 560.0);
        break;
      default:
        _targetLook = const Offset(200.0, 420.0);
    }
  }

  void lookAtButton() {
    _targetLook = const Offset(200.0, 677.0);
  }

  void lookAtRest() {
    _targetLook = const Offset(200.0, 420.0);
  }

  void triggerError() {
    _isError = true;
    _isSuccess = false;
    _errorStartTime = _state.T;

    // Flinch characters with surprise
    for (int ci = 0; ci < rigs.length; ci++) {
      rigs[ci].shake.v += (ci % 2 != 0 ? -1.0 : 1.0) * 260.0;
      rigs[ci].sq.v -= 7.0;
    }
    if (prefersReducedMotion) {
      _worry.x = 1.0;
      _worry.v = 0.0;
    }
    _tickSimulation(
      _state.T + (prefersReducedMotion ? 1.0 : 0.0),
      isDirectInit: prefersReducedMotion,
    );
    notifyListeners();
  }

  void clearError() {
    if (_isError) {
      _isError = false;
      _tickSimulation(_state.T);
      notifyListeners();
    }
  }

  void triggerSuccess() {
    _isSuccess = true;
    _isError = false;
    _successStartTime = _state.T;
    _hopCount = 0;
    _targetLook = const Offset(200.0, 300.0);

    // Initial hop
    for (int ci = 0; ci < rigs.length; ci++) {
      rigs[ci].hop.v -= 420.0;
      rigs[ci].sq.v -= 10.0;
    }
    if (prefersReducedMotion) {
      _joy.x = 1.0;
      _joy.v = 0.0;
    }
    _tickSimulation(
      _state.T + (prefersReducedMotion ? 1.0 : 0.0),
      isDirectInit: prefersReducedMotion,
    );
    notifyListeners();
  }

  void triggerValid() {
    _isValid = true;
    for (final rig in rigs) {
      rig.sq.v += 4.0;
    }
    _tickSimulation(_state.T);
    notifyListeners();
  }

  void setValid(bool valid) {
    if (_isValid != valid) {
      _isValid = valid;
      if (valid) {
        for (final rig in rigs) {
          rig.sq.v += 4.0;
        }
      }
      _tickSimulation(_state.T);
      notifyListeners();
    }
  }

  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      if (loading) {
        _targetLook = const Offset(200.0, 677.0);
      }
      _tickSimulation(_state.T);
      notifyListeners();
    }
  }

  void triggerButtonPress() {
    _buttonPressTime = _state.T;
    _tickSimulation(_state.T);
    notifyListeners();
  }

  void triggerTap(Offset position) {
    _tapStartTime = _state.T;
    _tapPosition = position;
    _tickSimulation(_state.T);
    notifyListeners();
  }

  void reset() {
    _isError = false;
    _isSuccess = false;
    _isLoading = false;
    _isValid = false;
    _errorStartTime = null;
    _successStartTime = null;
    _worry.reset();
    _joy.reset();
    _relief.reset();
    _targetLook = const Offset(200.0, 420.0);
    _look = const Offset(200.0, 420.0);
    for (final rig in rigs) {
      rig.reset();
    }
    _tickSimulation(_state.T);
    notifyListeners();
  }

  void _handleTick(Duration elapsed) {
    if (_isDisposed) return;
    final double elapsedSeconds = elapsed.inMicroseconds / 1000000.0;
    _tickSimulation(elapsedSeconds);
    notifyListeners();
  }

  void _tickSimulation(double nowSeconds, {bool isDirectInit = false}) {
    final double T = nowSeconds;
    _startTime ??= T;

    final double dt = _lastTime == null
        ? 1.0 / 60.0
        : math.min(0.05, T - _lastTime!);
    _lastTime = T;

    // Field shake calculation when an error is triggered
    double emailShakeX = 0.0;
    if (_errorStartTime != null) {
      final double elapsedSinceError = T - _errorStartTime!;
      if (elapsedSinceError >= 0.0 && elapsedSinceError < 0.55) {
        final double uShake = MathUtils.clamp(elapsedSinceError / 0.55);
        emailShakeX = math.sin(uShake * math.pi * 5.0) * 8.0 * (1.0 - uShake);
      }
    }

    // Button press dip scale
    double buttonPressScale = 1.0;
    if (_buttonPressTime != null) {
      final double elapsedSincePress = (T - _buttonPressTime!).abs();
      if (elapsedSincePress < 0.12) {
        final double pr = 1.0 - elapsedSincePress / 0.12;
        buttonPressScale = 1.0 - 0.05 * pr;
      }
    }

    // Rotating spinner angle
    final double spinnerAngle = (T * 540.0) * (math.pi / 180.0);

    // Staggered celebration hops
    if (_isSuccess && _successStartTime != null) {
      final double sinceSuccess = T - _successStartTime!;
      if (_hopCount == 0 && sinceSuccess >= 0.65) {
        _hopCount = 1;
        for (int ci = 0; ci < rigs.length; ci++) {
          rigs[ci].hop.v -= 420.0;
          rigs[ci].sq.v -= 10.0;
        }
      } else if (_hopCount == 1 && sinceSuccess >= 1.30) {
        _hopCount = 2;
        for (int ci = 0; ci < rigs.length; ci++) {
          rigs[ci].hop.v -= 420.0;
          rigs[ci].sq.v -= 10.0;
        }
      }
    }

    // Smooth look target interpolation
    _look = Offset(
      _look.dx + (_targetLook.dx - _look.dx) * math.min(1.0, dt * 6.0),
      _look.dy + (_targetLook.dy - _look.dy) * math.min(1.0, dt * 6.0),
    );

    // Tap indicator ring calculation
    bool tapActive = false;
    Offset tapPos = Offset.zero;
    double tapOpacity = 0.0;
    double tapScale = 0.6;

    if (_tapStartTime != null) {
      final double uTap = (T - _tapStartTime!) / 0.45;
      if (uTap >= 0.0 && uTap < 1.0) {
        tapPos = Offset(_tapPosition.dx - 22.0, _tapPosition.dy - 22.0);
        tapOpacity = math.sin(math.pi * uTap);
        tapScale = 0.6 + 0.6 * uTap;
        tapActive = true;
      }
    }

    // Step shared moods
    _worry.step(_isError ? 1.0 : 0.0, dt);
    _joy.step(_isSuccess ? 1.0 : 0.0, dt);
    _relief.step((_isValid && !_isSuccess) ? 1.0 : 0.0, dt);

    final double er = MathUtils.clamp(_worry.x, 0.0, 1.2);
    final double jy = MathUtils.clamp(_joy.x, 0.0, 1.2);
    final double okk = MathUtils.clamp(_relief.x, 0.0, 1.2);

    for (int ci = 0; ci < rigs.length; ci++) {
      final CharacterRig c = rigs[ci];
      final MemberDefinition m = c.member;

      c.hop.step(0.0, dt);
      c.shake.step(0.0, dt);
      c.sq.step(0.0, dt);

      // Pop in with overshoot (or 1.0 immediately if reduced motion)
      final double pop = isDirectInit || prefersReducedMotion
          ? 1.0
          : MathUtils.clamp((T - m.delay) / 0.6);
      final double ps = pop < 1.0
          ? MathUtils.eio(pop) * (1.0 + math.sin(pop * math.pi) * 0.16)
          : 1.0;

      // Lean toward look target
      final double dx = _look.dx - m.x;
      final double dy = _look.dy - m.y;
      c.lean.step(MathUtils.clamp(dx / 300.0, -1.0, 1.0) * 5.0, dt);

      // Stretch & squash & breathing
      final double vy = c.hop.v;
      final double stretch =
          MathUtils.clamp(-vy / 1800.0, -0.12, 0.14) + c.sq.x * 0.012;
      final double sx =
          ps * (1.0 - stretch * 0.6) * (1.0 + math.sin(T * 2.0 + ci) * 0.012);
      final double sy =
          ps *
          (1.0 + stretch) *
          (1.0 - er * 0.04) *
          (1.0 + math.sin(T * 2.0 + ci + 1.0) * 0.012);

      c.rootTranslation = Offset(m.x, m.y + c.hop.x * 0.06);
      c.rootRotationDeg =
          m.rotation +
          c.lean.x +
          c.shake.x * 0.06 +
          math.sin(T * 1.1 + ci) * 1.2;
      c.scaleX = sx;
      c.scaleY = sy;

      // Face turning toward look target
      final double ang = (-m.rotation * math.pi) / 180.0;
      final double rx0 = dx * math.cos(ang) - dy * math.sin(ang);
      final double ry0 = dx * math.sin(ang) + dy * math.cos(ang);
      final double dd = math.sqrt(rx0 * rx0 + ry0 * ry0);
      final double safeDd = dd == 0.0 ? 1.0 : dd;

      c.turnX.step((rx0 / safeDd) * 7.0, dt);
      c.turnY.step((ry0 / safeDd) * 5.0, dt);
      c.faceTranslation = Offset(c.turnX.x, c.turnY.x);

      // Eye rig updates
      for (int k = 0; k < c.eyes.length; k++) {
        final eye = c.eyes[k];
        final double ex = _look.dx - (m.x + eye.x);
        final double ey = _look.dy - (m.y + eye.y);
        final double rx = ex * math.cos(ang) - ey * math.sin(ang);
        final double ry = ex * math.sin(ang) + ey * math.cos(ang);
        final double dEye = math.sqrt(rx * rx + ry * ry);
        final double safeDEye = dEye == 0.0 ? 1.0 : dEye;
        final double reach = eye.r * 0.42;

        final double tx = (rx / safeDEye) * reach * math.min(1.0, dEye / 70.0);
        final double ty = (ry / safeDEye) * reach * math.min(1.0, dEye / 70.0);

        eye.vx +=
            (AnimationConstants.springPupil.$1 * (tx - eye.px) -
                AnimationConstants.springPupil.$2 * eye.vx) *
            dt;
        eye.vy +=
            (AnimationConstants.springPupil.$1 * (ty - eye.py) -
                    AnimationConstants.springPupil.$2 * eye.vy) *
                dt +
            c.hop.v * 0.0016;
        eye.vx += c.shake.v * 0.0012;
        eye.px += eye.vx * dt;
        eye.py += eye.vy * dt;

        final double prEye = math.sqrt(eye.px * eye.px + eye.py * eye.py);
        if (prEye > reach * 1.15) {
          final double factor = (reach * 1.15) / prEye;
          eye.px *= factor;
          eye.py *= factor;
        }

        final double pupR = eye.r * (0.52 - 0.12 * er + 0.04 * okk);
        eye.pupilRadius = pupR;

        // Eye blinking
        final double ph = (T + ci * 0.83) % 4.6;
        final double bl = ph < 0.16 ? math.sin((ph / 0.16) * math.pi) : 0.0;
        final double lidH = math.max(bl, er * 0.3);
        eye.lidHeight = lidH;

        final double hj = MathUtils.clamp(jy);
        eye.normalEyeOpacity = 1.0 - hj;
        eye.happyOpacity = hj;

        final double big = 1.0 + er * 0.1;
        eye.whiteRadius = eye.r * big;
        eye.clipRadius = eye.r * big + 1.5;

        final int side = c.eyes.length == 1 ? 0 : (k == 0 ? 1 : -1);
        eye.browOpacity = MathUtils.clamp(er);
        eye.browTranslationY = -3.0 * er;
        eye.browRotation = side * -18.0 * er;
      }

      // Extras: sweat, blush, heart
      final double sw = (T * 0.9 + ci * 0.3) % 1.0;
      c.sweatTranslation = Offset(m.sweatAt.dx, m.sweatAt.dy + sw * 14.0);
      c.sweatOpacity = MathUtils.clamp(er) * (1.0 - sw);

      c.blushOpacity = MathUtils.clamp(jy) * 0.9;

      final double hf = (T * 0.7 + ci * 0.37) % 1.0;
      c.heartTranslation = Offset(
        m.heartAt.dx + math.sin(hf * 6.0) * 3.0,
        m.heartAt.dy - hf * 22.0,
      );
      c.heartScale = 0.8 + 0.3 * hf;
      c.heartOpacity = MathUtils.clamp(jy) * math.sin(math.pi * hf);

      // Mouth & tongue morphing
      final double mx = m.mouth.x;
      final double my = m.mouth.y;
      final double mw = m.mouth.halfWidth;
      final double sm =
          MathUtils.lerp(0.25, -0.85, MathUtils.clamp(er)) *
              (1.0 - math.max(okk * 0.7, jy)) +
          math.max(okk * 0.55, jy);
      final double op = MathUtils.clamp(jy);
      final double w = mw * (1.0 + 0.15 * jy - 0.15 * er);
      final double cy1 = my + w * 0.85 * sm + op * w * 0.5;
      final double cy2 = my + op * w * 0.25;

      c.mouthPath = OrganicShapes.mouthPath(
        mx: mx,
        my: my,
        w: w,
        cy1: cy1,
        cy2: cy2,
      );
      c.mouthFillOpacity = op;

      c.tongueCenter = Offset(mx, my + w * 0.6 * op);
      c.tongueRadiusX = mw * 0.45 * op;
      c.tongueRadiusY = mw * 0.22 * op;
      c.tongueOpacity = op * 0.9;
    }

    // Stars update
    for (int i = 0; i < stars.length; i++) {
      final star = stars[i];
      final double twStar = 0.75 + 0.25 * math.sin(T * 3.0 + i * 1.7);
      final double b = 1.0 + jy * (0.6 + 0.4 * math.sin(T * 9.0 + i));
      star.scale = twStar * b;
      star.rotation = (T * 20.0 + i * 30.0) * (math.pi / 180.0);
    }

    // Phone opacity (smooth fade in over first 0.4s or 1.0 immediately)
    final double phoneOpacity = isDirectInit || prefersReducedMotion
        ? 1.0
        : MathUtils.clamp(T / 0.4);

    if (_cachedBeat.isError != _isError ||
        _cachedBeat.isValid != _isValid ||
        _cachedBeat.isLoading != _isLoading ||
        _cachedBeat.isDone != _isSuccess) {
      _cachedBeat = BeatState(
        nameLength: 0,
        email: '',
        passwordDots: 0,
        focusedField: -1,
        isError: _isError,
        errorOpacity: _isError ? 1.0 : 0.0,
        isValid: _isValid,
        isLoading: _isLoading,
        isDone: _isSuccess,
      );
    }

    _state = AnimationState(
      t: T,
      T: T,
      beat: _cachedBeat,
      emailShakeX: emailShakeX,
      phoneOpacity: phoneOpacity,
      buttonPressScale: buttonPressScale,
      spinnerAngle: spinnerAngle,
      titleBlur: 0.0,
      isTitleDone: _isSuccess,
      isSubtitleDone: _isSuccess,
      isSubtitleError: _isError,
      tapActive: tapActive,
      tapPosition: tapPos,
      tapScale: tapScale,
      tapOpacity: tapOpacity,
      fadeOut: 1.0,
      isError: _isError,
      isSuccess: _isSuccess,
      isLoading: _isLoading,
      isValid: _isValid,
    );
  }

  double measureCachedText(String key, String text, TextStyle style) {
    if (text.isEmpty) return 0.0;
    return _textWidthCache.putIfAbsent(key, () {
      _textPainter.text = TextSpan(text: text, style: style);
      _textPainter.layout();
      return _textPainter.width;
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _ticker?.dispose();
    _textPainter.dispose();
    _textWidthCache.clear();
    super.dispose();
  }
}

typedef LumaAnimationEngine = RafiAnimationEngine;
