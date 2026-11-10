/// Default strings and localized labels for Login Screen.
abstract final class RafiLoginContent {
  static const String name = 'Mira';
  static const String emailTypo = 'mira@studio';
  static const String emailFix = '.io';
  static const int passwordLength = 9;
  static const String passwordDot = '•';

  static const String time = '9:41';
  static const String title = 'Join the crew';
  static const String titleDone = 'Welcome aboard!';
  static const String subtitle = "They'll keep an eye on things";
  static const String subtitleError = 'Uh-oh, something looks incorrect';
  static const String subtitleDone = 'The crew is thrilled to have you';

  static const String nameLabel = 'Name';
  static const String namePlaceholder = 'Your name';
  static const String emailLabel = 'Email';
  static const String emailPlaceholder = 'you@email.com';
  static const String check = '✓';
  static const String error = 'Please enter a valid email address';

  static const String passwordLabel = 'Password';
  static const String passwordPlaceholder = '8+ characters';

  static const String button = 'Log in';
  static const String buttonLoading = 'Signing in...';
  static const String buttonDone = 'Welcome aboard';

  static const String member = "Don't have an account?";
  static const String login = 'Sign up';

  static const String description =
      'Login screen watched by five reactive vector characters with googly eyes.';
}

/// LumaFix-specific brand copy
abstract final class LumaLoginContent {
  static const String brandTitle = 'LumaFix';
  static const String brandSubtitle = 'Precision Photo Studio';
  static const String welcomeBack = 'Welcome to LumaFix';
  static const String continueAsGuest = 'Continue as Guest';
  static const String skipToStudio = 'Skip to Studio';
  static const String tagline = 'See Beyond Ordinary.';
}
