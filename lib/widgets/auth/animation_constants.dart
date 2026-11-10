abstract final class AnimationConstants {
  static const double loopDuration = 18.0;
  static const double stillAt = 12.0;

  // Event milestones
  static const double atError = 4.55;
  static const double atErrorEnd = 6.6;
  static const double atFixed = 6.9;
  static const double atLoading = 8.85;
  static const double atDone = 9.8;
  static const double atTitle = 9.9;
  static const double atDoneEnd = 17.2;
  static const double atFadeOut = 17.4;

  // Hops and Button press timestamps
  static const List<double> hops = [9.8, 10.45, 11.1];
  static const List<double> presses = [4.45, 8.75];

  // Character pop-in delays
  static const double cookieDelay = 0.15;
  static const double beanDelay = 0.30;
  static const double sunDelay = 0.45;
  static const double wobbleDelay = 0.60;
  static const double pebbleDelay = 0.75;

  // Spring physical constants (stiffness, damping)
  static const (double, double) springWorry = (140.0, 20.0);
  static const (double, double) springJoy = (260.0, 30.0);
  static const (double, double) springRelief = (90.0, 17.0);
  static const (double, double) springHop = (230.0, 14.0);
  static const (double, double) springLean = (70.0, 13.0);
  static const (double, double) springShake = (300.0, 10.0);
  static const (double, double) springSquash = (360.0, 17.0);
  static const (double, double) springTurn = (80.0, 14.0);
  static const (double, double) springPupil = (140.0, 8.5);
}
