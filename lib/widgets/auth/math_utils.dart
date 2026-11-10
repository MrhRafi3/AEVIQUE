abstract final class MathUtils {
  /// Clamps [v] between [a] and [b]. Defaults to 0..1.
  static double clamp(double v, [double a = 0.0, double b = 1.0]) {
    if (v < a) return a;
    if (v > b) return b;
    return v;
  }

  /// Linear interpolation between [a] and [b] with factor [u].
  static double lerp(double a, double b, double u) => a + (b - a) * u;

  /// Cubic ease-in-out on [0, 1].
  static double eio(double u) {
    if (u < 0.5) {
      return 4.0 * u * u * u;
    } else {
      final double term = -2.0 * u + 2.0;
      return 1.0 - (term * term * term) / 2.0;
    }
  }

  /// Eased progress of [t] through [[a], [b]]: 0 before [a], 1 after [b].
  static double seg(double t, double a, double b) {
    if (a == b) return t >= b ? 1.0 : 0.0;
    return eio(clamp((t - a) / (b - a), 0.0, 1.0));
  }
}
