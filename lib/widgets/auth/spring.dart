/// A damped spring stepped once per frame (semi-implicit Euler):
/// [x] chases a target, [v] is its velocity.
class Spring {
  double x;
  double v;
  final double k; // stiffness
  final double c; // damping

  Spring({required this.k, required this.c, this.x = 0.0, this.v = 0.0});

  /// Step the spring towards [target] with time step [dt].
  void step(double target, double dt) {
    v += (k * (target - x) - c * v) * dt;
    x += v * dt;
  }

  void reset() {
    x = 0.0;
    v = 0.0;
  }
}
