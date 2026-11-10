import 'dart:async';
import 'package:flutter/material.dart';

export '../widgets/auth/auth_callbacks.dart';
export '../widgets/auth/login_credentials.dart';

import '../widgets/luma_logo.dart';
import '../widgets/auth/character_painter.dart';
import '../widgets/auth/crew_data.dart';
import '../widgets/auth/design_tokens.dart';
import '../widgets/auth/login_animation_engine.dart';
import '../widgets/auth/login_content.dart';
import '../widgets/auth/login_credentials.dart';
import '../widgets/auth/login_form.dart';
import '../widgets/auth/stars_painter.dart';
import '../widgets/auth/tap_indicator.dart';
import 'home_screen.dart';

/// LumaFix interactive Login Screen.
///
/// Features five interactive vector characters with physics-driven googly eyes,
/// real user input fields, password toggle, inline validation, guest bypass,
/// and pluggable authentication callbacks.
class LoginScreen extends StatefulWidget {
  /// Authentication handler invoked when the user submits valid credentials.
  ///
  /// Can return an [AuthResult], complete normally on success, or throw an exception
  /// with a user-friendly error message on failure.
  final FutureOr<dynamic> Function(LoginCredentials credentials)? onLogin;

  /// Callback invoked when the user taps "Forgot password?".
  final VoidCallback? onForgotPassword;

  /// Callback invoked when the user taps the footer registration link.
  final VoidCallback? onCreateAccount;

  /// Callback invoked after successful authentication and celebration animation.
  final void Function(LoginCredentials credentials)? onAuthenticated;

  /// Quick bypass callback to jump directly to the editing studio as guest.
  final VoidCallback? onSkip;

  /// Format and validation mode for the primary identifier field.
  final RafiIdentifierType identifierType;

  /// Custom override for the identifier field label.
  final String? identifierLabel;

  /// Custom override for the identifier field placeholder.
  final String? identifierPlaceholder;

  /// Custom override for the password field label.
  final String? passwordLabel;

  /// Custom override for the password field placeholder.
  final String? passwordPlaceholder;

  /// Header title (defaults to "LumaFix").
  final String? title;

  /// Header subtitle (defaults to "Precision Photo Studio").
  final String? subtitle;

  /// Main action button label (defaults to "Log in").
  final String? loginButtonText;

  /// Button label displayed while authentication is in progress.
  final String? loginButtonLoadingText;

  /// Button label displayed upon successful authentication.
  final String? loginButtonSuccessText;

  /// Footer prompt text (defaults to "Don't have an account?").
  final String? footerPromptText;

  /// Footer action text (defaults to "Sign up").
  final String? footerActionText;

  /// Text for the skip/guest bypass action.
  final String? skipButtonText;

  /// Optional brand logo or icon widget placed above the title.
  final Widget? logo;

  /// Custom validator for the identifier input.
  final String? Function(String? value)? identifierValidator;

  /// Custom validator for the password input.
  final String? Function(String? value)? passwordValidator;

  /// Optional externally managed controller for the identifier field.
  final TextEditingController? identifierController;

  /// Optional externally managed controller for the password field.
  final TextEditingController? passwordController;

  /// Optional externally managed focus node for the identifier field.
  final FocusNode? identifierFocusNode;

  /// Optional externally managed focus node for the password field.
  final FocusNode? passwordFocusNode;

  /// Whether to display the animated password strength bar.
  final bool showPasswordStrength;

  /// Whether to display an optional Name field above the identifier (3-field mode).
  final bool showNameField;

  /// Optional externally managed controller for the name field.
  final TextEditingController? nameController;

  /// Optional externally managed focus node for the name field.
  final FocusNode? nameFocusNode;

  /// Custom validator for the name input.
  final String? Function(String? value)? nameValidator;

  /// Deprecated phone mockup toggle retained for complete backwards compatibility.
  @Deprecated('Mockup has been replaced with a native responsive layout.')
  final bool showPhoneFrame;

  const LoginScreen({
    super.key,
    this.onLogin,
    this.onForgotPassword,
    this.onCreateAccount,
    this.onAuthenticated,
    this.onSkip,
    this.identifierType = RafiIdentifierType.email,
    this.identifierLabel,
    this.identifierPlaceholder,
    this.passwordLabel,
    this.passwordPlaceholder,
    this.title = LumaLoginContent.brandTitle,
    this.subtitle = LumaLoginContent.brandSubtitle,
    this.loginButtonText,
    this.loginButtonLoadingText,
    this.loginButtonSuccessText,
    this.footerPromptText,
    this.footerActionText,
    this.skipButtonText,
    this.logo,
    this.identifierValidator,
    this.passwordValidator,
    this.identifierController,
    this.passwordController,
    this.identifierFocusNode,
    this.passwordFocusNode,
    this.showPasswordStrength = false,
    this.showNameField = false,
    this.nameController,
    this.nameFocusNode,
    this.nameValidator,
    this.showPhoneFrame = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  RafiAnimationEngine? _engine;
  bool? _lastReducedMotion;

  // Controllers & ownership flags
  late TextEditingController _identifierController;
  late bool _ownsIdentifierController;
  late FocusNode _identifierFocusNode;
  late bool _ownsIdentifierFocusNode;

  late TextEditingController _passwordController;
  late bool _ownsPasswordController;
  late FocusNode _passwordFocusNode;
  late bool _ownsPasswordFocusNode;

  TextEditingController? _nameController;
  bool _ownsNameController = false;
  FocusNode? _nameFocusNode;
  bool _ownsNameFocusNode = false;

  // Form State
  bool _isPasswordObscured = true;
  bool _isLoading = false;
  bool _isSuccess = false;
  String? _identifierError;
  String? _passwordError;
  String? _nameError;
  String? _authError;
  bool _isIdentifierValid = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    if (widget.identifierController != null) {
      _identifierController = widget.identifierController!;
      _ownsIdentifierController = false;
    } else {
      _identifierController = TextEditingController();
      _ownsIdentifierController = true;
    }

    if (widget.identifierFocusNode != null) {
      _identifierFocusNode = widget.identifierFocusNode!;
      _ownsIdentifierFocusNode = false;
    } else {
      _identifierFocusNode = FocusNode();
      _ownsIdentifierFocusNode = true;
    }

    if (widget.passwordController != null) {
      _passwordController = widget.passwordController!;
      _ownsPasswordController = false;
    } else {
      _passwordController = TextEditingController();
      _ownsPasswordController = true;
    }

    if (widget.passwordFocusNode != null) {
      _passwordFocusNode = widget.passwordFocusNode!;
      _ownsPasswordFocusNode = false;
    } else {
      _passwordFocusNode = FocusNode();
      _ownsPasswordFocusNode = true;
    }

    if (widget.showNameField) {
      if (widget.nameController != null) {
        _nameController = widget.nameController!;
        _ownsNameController = false;
      } else {
        _nameController = TextEditingController();
        _ownsNameController = true;
      }

      if (widget.nameFocusNode != null) {
        _nameFocusNode = widget.nameFocusNode!;
        _ownsNameFocusNode = false;
      } else {
        _nameFocusNode = FocusNode();
        _ownsNameFocusNode = true;
      }
    }

    // Attach listeners for character eye tracking and input validation
    _identifierFocusNode.addListener(_handleIdentifierFocusChange);
    _passwordFocusNode.addListener(_handlePasswordFocusChange);
    _identifierController.addListener(_handleIdentifierTextChange);
    _passwordController.addListener(_handlePasswordTextChange);

    _nameFocusNode?.addListener(_handleNameFocusChange);
  }

  void _handleIdentifierFocusChange() {
    if (_identifierFocusNode.hasFocus) {
      _engine?.lookAtField(widget.showNameField ? 1 : 0);
    } else if (!_passwordFocusNode.hasFocus &&
        !(_nameFocusNode?.hasFocus ?? false)) {
      _engine?.lookAtRest();
    }
  }

  void _handlePasswordFocusChange() {
    if (_passwordFocusNode.hasFocus) {
      _engine?.lookAtField(widget.showNameField ? 2 : 1);
    } else if (!_identifierFocusNode.hasFocus &&
        !(_nameFocusNode?.hasFocus ?? false)) {
      _engine?.lookAtRest();
    }
  }

  void _handleNameFocusChange() {
    if (_nameFocusNode?.hasFocus ?? false) {
      _engine?.lookAtField(0);
    } else if (!_identifierFocusNode.hasFocus && !_passwordFocusNode.hasFocus) {
      _engine?.lookAtRest();
    }
  }

  void _handleIdentifierTextChange() {
    final text = _identifierController.text.trim();
    final bool valid = _checkIdentifierValidity(text);

    if (_isIdentifierValid != valid) {
      setState(() {
        _isIdentifierValid = valid;
      });
      _engine?.setValid(valid);
    }

    if (_identifierError != null || _authError != null) {
      setState(() {
        _identifierError = null;
        _authError = null;
      });
      _engine?.clearError();
    }
  }

  void _handlePasswordTextChange() {
    if (_passwordError != null || _authError != null) {
      setState(() {
        _passwordError = null;
        _authError = null;
      });
      _engine?.clearError();
    }
  }

  bool _checkIdentifierValidity(String text) {
    if (text.isEmpty) return false;
    switch (widget.identifierType) {
      case RafiIdentifierType.email:
        return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text);
      case RafiIdentifierType.username:
        return text.length >= 3;
      case RafiIdentifierType.emailOrUsername:
        return text.length >= 3;
      case RafiIdentifierType.name:
        return text.isNotEmpty;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reducedMotion = MediaQuery.disableAnimationsOf(context);

    if (_engine == null || _lastReducedMotion != reducedMotion) {
      _engine?.dispose();
      _lastReducedMotion = reducedMotion;
      _engine = RafiAnimationEngine(
        vsync: this,
        prefersReducedMotion: reducedMotion,
      );
    }
  }

  @override
  void didUpdateWidget(covariant LoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.identifierController != oldWidget.identifierController) {
      _identifierController.removeListener(_handleIdentifierTextChange);
      if (_ownsIdentifierController) _identifierController.dispose();
      if (widget.identifierController != null) {
        _identifierController = widget.identifierController!;
        _ownsIdentifierController = false;
      } else {
        _identifierController = TextEditingController();
        _ownsIdentifierController = true;
      }
      _identifierController.addListener(_handleIdentifierTextChange);
    }

    if (widget.identifierFocusNode != oldWidget.identifierFocusNode) {
      _identifierFocusNode.removeListener(_handleIdentifierFocusChange);
      if (_ownsIdentifierFocusNode) _identifierFocusNode.dispose();
      if (widget.identifierFocusNode != null) {
        _identifierFocusNode = widget.identifierFocusNode!;
        _ownsIdentifierFocusNode = false;
      } else {
        _identifierFocusNode = FocusNode();
        _ownsIdentifierFocusNode = true;
      }
      _identifierFocusNode.addListener(_handleIdentifierFocusChange);
    }

    if (widget.passwordController != oldWidget.passwordController) {
      _passwordController.removeListener(_handlePasswordTextChange);
      if (_ownsPasswordController) _passwordController.dispose();
      if (widget.passwordController != null) {
        _passwordController = widget.passwordController!;
        _ownsPasswordController = false;
      } else {
        _passwordController = TextEditingController();
        _ownsPasswordController = true;
      }
      _passwordController.addListener(_handlePasswordTextChange);
    }

    if (widget.passwordFocusNode != oldWidget.passwordFocusNode) {
      _passwordFocusNode.removeListener(_handlePasswordFocusChange);
      if (_ownsPasswordFocusNode) _passwordFocusNode.dispose();
      if (widget.passwordFocusNode != null) {
        _passwordFocusNode = widget.passwordFocusNode!;
        _ownsPasswordFocusNode = false;
      } else {
        _passwordFocusNode = FocusNode();
        _ownsPasswordFocusNode = true;
      }
      _passwordFocusNode.addListener(_handlePasswordFocusChange);
    }

    if (widget.showNameField != oldWidget.showNameField ||
        widget.nameController != oldWidget.nameController ||
        widget.nameFocusNode != oldWidget.nameFocusNode) {
      _nameFocusNode?.removeListener(_handleNameFocusChange);
      if (_ownsNameController) _nameController?.dispose();
      if (_ownsNameFocusNode) _nameFocusNode?.dispose();

      if (widget.showNameField) {
        if (widget.nameController != null) {
          _nameController = widget.nameController!;
          _ownsNameController = false;
        } else {
          _nameController = TextEditingController();
          _ownsNameController = true;
        }

        if (widget.nameFocusNode != null) {
          _nameFocusNode = widget.nameFocusNode!;
          _ownsNameFocusNode = false;
        } else {
          _nameFocusNode = FocusNode();
          _ownsNameFocusNode = true;
        }
        _nameFocusNode!.addListener(_handleNameFocusChange);
      } else {
        _nameController = null;
        _ownsNameController = false;
        _nameFocusNode = null;
        _ownsNameFocusNode = false;
      }
    }
  }

  @override
  void dispose() {
    _identifierFocusNode.removeListener(_handleIdentifierFocusChange);
    _passwordFocusNode.removeListener(_handlePasswordFocusChange);
    _identifierController.removeListener(_handleIdentifierTextChange);
    _passwordController.removeListener(_handlePasswordTextChange);
    _nameFocusNode?.removeListener(_handleNameFocusChange);

    if (_ownsIdentifierController) _identifierController.dispose();
    if (_ownsIdentifierFocusNode) _identifierFocusNode.dispose();
    if (_ownsPasswordController) _passwordController.dispose();
    if (_ownsPasswordFocusNode) _passwordFocusNode.dispose();
    if (_ownsNameController) _nameController?.dispose();
    if (_ownsNameFocusNode) _nameFocusNode?.dispose();

    _engine?.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordObscured = !_isPasswordObscured;
    });
  }

  Future<void> _handleSubmit() async {
    // Prevent duplicate submissions while in-flight or already succeeded
    if (_isLoading || _isSuccess) return;

    final String identifier = _identifierController.text.trim();
    final String password = _passwordController.text;
    final String? name = _nameController?.text.trim();

    // 1. Validation
    String? idErr;
    if (widget.identifierValidator != null) {
      idErr = widget.identifierValidator!(identifier);
    } else {
      if (identifier.isEmpty) {
        idErr =
            'Please enter your ${widget.identifierLabel ?? _defaultIdentifierLabelName()}';
      } else if (widget.identifierType == RafiIdentifierType.email &&
          !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(identifier)) {
        idErr = RafiLoginContent.error;
      } else if (widget.identifierType == RafiIdentifierType.username &&
          identifier.length < 3) {
        idErr = 'Username must be at least 3 characters';
      }
    }

    String? passErr;
    if (widget.passwordValidator != null) {
      passErr = widget.passwordValidator!(password);
    } else {
      if (password.isEmpty) {
        passErr = 'Please enter your password';
      } else if (password.length < 8) {
        passErr = 'Password must be at least 8 characters';
      }
    }

    String? nameErr;
    if (widget.showNameField) {
      if (widget.nameValidator != null) {
        nameErr = widget.nameValidator!(name);
      } else if (name == null || name.isEmpty) {
        nameErr = 'Please enter your name';
      }
    }

    if (idErr != null || passErr != null || nameErr != null) {
      setState(() {
        _identifierError = idErr;
        _passwordError = passErr;
        _nameError = nameErr;
        _authError = null;
      });
      _engine?.triggerError();
      return;
    }

    // 2. Begin Authentication Request
    setState(() {
      _isLoading = true;
      _authError = null;
      _identifierError = null;
      _passwordError = null;
      _nameError = null;
    });
    _engine?.setLoading(true);

    final credentials = LoginCredentials(
      identifier: identifier,
      password: password,
      name: name,
    );

    try {
      if (widget.onLogin != null) {
        final result = await widget.onLogin!(credentials);

        if (!mounted) return;

        if (result is AuthResult) {
          if (!result.isSuccess) {
            _handleAuthFailure(result.errorMessage ?? 'Authentication failed');
            return;
          }
        }
      }

      // Success
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });
      _engine?.setLoading(false);
      _engine?.triggerSuccess();

      if (widget.onAuthenticated != null) {
        widget.onAuthenticated!(credentials);
      } else {
        // Default transition to home screen
        _navigateToHomeScreen();
      }
    } catch (error) {
      if (!mounted) return;
      final String message = error is Exception
          ? error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '')
          : error.toString();
      _handleAuthFailure(message);
    }
  }

  void _handleAuthFailure(String message) {
    setState(() {
      _isLoading = false;
      _authError = message;
    });
    _engine?.setLoading(false);
    _engine?.triggerError();
  }

  void _handleSkip() {
    if (widget.onSkip != null) {
      widget.onSkip!();
    } else if (widget.onAuthenticated != null) {
      widget.onAuthenticated!(
        const LoginCredentials(
          identifier: 'guest@lumafix.app',
          password: '',
          name: 'Guest Creator',
        ),
      );
    } else {
      _navigateToHomeScreen();
    }
  }

  void _navigateToHomeScreen() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  String _defaultIdentifierLabelName() {
    switch (widget.identifierType) {
      case RafiIdentifierType.email:
        return 'email';
      case RafiIdentifierType.username:
        return 'username';
      case RafiIdentifierType.emailOrUsername:
        return 'email or username';
      case RafiIdentifierType.name:
        return 'name';
    }
  }

  Widget _buildDefaultLogo() {
    return const LumaLogo(
      size: 48,
      showGlow: true,
      primaryColor: RafiDesignTokens.ink,
      accentColor: Color(0xFFFF8A32),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_engine == null) {
      return const SizedBox.shrink();
    }

    final Widget formWidget = RafiLoginForm(
      engine: _engine!,
      identifierController: _identifierController,
      identifierFocusNode: _identifierFocusNode,
      identifierType: widget.identifierType,
      identifierLabel: widget.identifierLabel,
      identifierPlaceholder: widget.identifierPlaceholder,
      identifierError: _identifierError,
      isIdentifierValid: _isIdentifierValid,
      passwordController: _passwordController,
      passwordFocusNode: _passwordFocusNode,
      passwordLabel: widget.passwordLabel,
      passwordPlaceholder: widget.passwordPlaceholder,
      passwordError: _passwordError,
      isPasswordObscured: _isPasswordObscured,
      onTogglePasswordVisibility: _togglePasswordVisibility,
      showNameField: widget.showNameField,
      nameController: _nameController,
      nameFocusNode: _nameFocusNode,
      nameError: _nameError,
      showPasswordStrength: widget.showPasswordStrength,
      title: widget.title,
      subtitle: widget.subtitle,
      authError: _authError,
      isSuccess: _isSuccess,
      isLoading: _isLoading,
      loginButtonText: widget.loginButtonText,
      loginButtonLoadingText: widget.loginButtonLoadingText,
      loginButtonSuccessText: widget.loginButtonSuccessText,
      onLoginPressed: _handleSubmit,
      onForgotPassword: widget.onForgotPassword,
      onCreateAccount: widget.onCreateAccount,
      onSkip: _handleSkip,
      footerPromptText: widget.footerPromptText,
      footerActionText: widget.footerActionText,
      skipButtonText: widget.skipButtonText,
      logo: widget.logo ?? _buildDefaultLogo(),
    );

    final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bool isKeyboardOpen = bottomInset > 0.0;

    return Semantics(
      label: RafiLoginContent.description,
      container: true,
      child: Material(
        color: RafiDesignTokens.screen,
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (event) {
            _engine!.triggerTap(event.localPosition);
          },
          child: Stack(
            children: [
              // Layer 1: Front characters (Wobble, Pebble) peeking at the bottom corners
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: isKeyboardOpen ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: CustomPaint(
                      painter: CharacterPainter(
                        engine: _engine!,
                        layer: CharacterLayer.front,
                      ),
                    ),
                  ),
                ),
              ),

              // Layer 2: Main Responsive Full-Screen Layout with SafeArea
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double screenWidth = constraints.maxWidth;
                    final double screenHeight = constraints.maxHeight;

                    // Responsive margins: 24 on phones, centered on wider displays
                    final double horizontalPadding = screenWidth > 440.0
                        ? 0.0
                        : RafiDesignTokens.fieldInset;

                    return SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: 400.0,
                            minHeight: screenHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Top character stage with Stars & Back characters (Cookie, Sun, Bean)
                                SizedBox(
                                    height: 190.0,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      alignment: Alignment.center,
                                      children: [
                                        Positioned.fill(
                                          child: RepaintBoundary(
                                            child: IgnorePointer(
                                              child: CustomPaint(
                                                painter: StarsPainter(
                                                  engine: _engine!,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned.fill(
                                          child: RepaintBoundary(
                                            child: IgnorePointer(
                                              child: CustomPaint(
                                                painter: CharacterPainter(
                                                  engine: _engine!,
                                                  layer: CharacterLayer.back,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // Interactive Form (Logo, Title, Subtitle, Inputs, Button, Footer, Guest skip)
                                formWidget,

                                // Flexible space ensuring the footer rests comfortably when content fits
                                const Spacer(),
                                const SizedBox(height: 24.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Layer 3: Tap indicator ring (expands at tap position)
              ListenableBuilder(
                listenable: _engine!,
                builder: (context, _) {
                  final state = _engine!.state;
                  return TapIndicator(
                    active: state.tapActive,
                    position: state.tapPosition,
                    scale: state.tapScale,
                    opacity: state.tapOpacity,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compatibility aliases
typedef RafiLoginScreen = LoginScreen;
typedef LumaLoginScreen = LoginScreen;
