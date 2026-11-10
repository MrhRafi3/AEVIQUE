import 'dart:ui';
import 'package:flutter/material.dart';

import 'design_tokens.dart';
import 'form_field.dart';
import 'login_animation_engine.dart';
import 'login_content.dart';
import 'login_credentials.dart';
import 'password_strength.dart';
import 'signup_button.dart';

/// Interactive login form supporting 2-field (identifier + password)
/// or 3-field (name + identifier + password) layout, with password visibility toggle,
/// inline validation, callbacks for forgot password, account creation, and guest entry,
/// optional branding logo, and responsive character reaction synchronization.
class RafiLoginForm extends StatelessWidget {
  final RafiAnimationEngine engine;

  final TextEditingController identifierController;
  final FocusNode identifierFocusNode;
  final RafiIdentifierType identifierType;
  final String? identifierLabel;
  final String? identifierPlaceholder;
  final String? identifierError;
  final bool isIdentifierValid;

  final TextEditingController passwordController;
  final FocusNode passwordFocusNode;
  final String? passwordLabel;
  final String? passwordPlaceholder;
  final String? passwordError;
  final bool isPasswordObscured;
  final VoidCallback onTogglePasswordVisibility;

  final bool showNameField;
  final TextEditingController? nameController;
  final FocusNode? nameFocusNode;
  final String? nameError;

  final bool showPasswordStrength;

  final String? title;
  final String? subtitle;
  final String? authError;
  final bool isSuccess;
  final bool isLoading;

  final String? loginButtonText;
  final String? loginButtonLoadingText;
  final String? loginButtonSuccessText;
  final VoidCallback onLoginPressed;

  final VoidCallback? onForgotPassword;
  final VoidCallback? onCreateAccount;
  final VoidCallback? onSkip;
  final String? footerPromptText;
  final String? footerActionText;
  final String? skipButtonText;

  /// Optional custom logo or brand widget rendered above the title.
  final Widget? logo;

  const RafiLoginForm({
    super.key,
    required this.engine,
    required this.identifierController,
    required this.identifierFocusNode,
    this.identifierType = RafiIdentifierType.email,
    this.identifierLabel,
    this.identifierPlaceholder,
    this.identifierError,
    this.isIdentifierValid = false,
    required this.passwordController,
    required this.passwordFocusNode,
    this.passwordLabel,
    this.passwordPlaceholder,
    this.passwordError,
    required this.isPasswordObscured,
    required this.onTogglePasswordVisibility,
    this.showNameField = false,
    this.nameController,
    this.nameFocusNode,
    this.nameError,
    this.showPasswordStrength = false,
    this.title,
    this.subtitle,
    this.authError,
    this.isSuccess = false,
    this.isLoading = false,
    this.loginButtonText,
    this.loginButtonLoadingText,
    this.loginButtonSuccessText,
    required this.onLoginPressed,
    this.onForgotPassword,
    this.onCreateAccount,
    this.onSkip,
    this.footerPromptText,
    this.footerActionText,
    this.skipButtonText,
    this.logo,
  });

  String _defaultIdentifierLabel() {
    switch (identifierType) {
      case RafiIdentifierType.email:
        return RafiLoginContent.emailLabel;
      case RafiIdentifierType.username:
        return 'Username';
      case RafiIdentifierType.emailOrUsername:
        return 'Email or username';
      case RafiIdentifierType.name:
        return RafiLoginContent.nameLabel;
    }
  }

  String _defaultIdentifierPlaceholder() {
    switch (identifierType) {
      case RafiIdentifierType.email:
        return RafiLoginContent.emailPlaceholder;
      case RafiIdentifierType.username:
        return 'your_username';
      case RafiIdentifierType.emailOrUsername:
        return 'you@email.com or username';
      case RafiIdentifierType.name:
        return RafiLoginContent.namePlaceholder;
    }
  }

  TextInputType _identifierKeyboardType() {
    switch (identifierType) {
      case RafiIdentifierType.email:
      case RafiIdentifierType.emailOrUsername:
        return TextInputType.emailAddress;
      case RafiIdentifierType.name:
        return TextInputType.name;
      case RafiIdentifierType.username:
        return TextInputType.text;
    }
  }

  Iterable<String> _identifierAutofillHints() {
    switch (identifierType) {
      case RafiIdentifierType.email:
        return const [AutofillHints.email];
      case RafiIdentifierType.username:
        return const [AutofillHints.username];
      case RafiIdentifierType.emailOrUsername:
        return const [AutofillHints.email, AutofillHints.username];
      case RafiIdentifierType.name:
        return const [AutofillHints.name];
    }
  }

  @override
  Widget build(BuildContext context) {
    // Title and Subtitle calculation
    final String effectiveTitle = isSuccess
        ? (title ?? RafiLoginContent.titleDone)
        : (title ?? RafiLoginContent.title);

    String effectiveSubtitle = subtitle ?? RafiLoginContent.subtitle;
    if (isSuccess) {
      effectiveSubtitle = RafiLoginContent.subtitleDone;
    } else if (authError != null && authError!.isNotEmpty) {
      effectiveSubtitle = authError!;
    } else if (identifierError != null || passwordError != null) {
      effectiveSubtitle = RafiLoginContent.subtitleError;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Optional Logo / Brand Widget
        if (logo != null) ...[
          Center(child: logo!),
          const SizedBox(height: 16.0),
        ],

        // Title with scoped blur listener
        ListenableBuilder(
          listenable: engine,
          builder: (context, _) {
            Widget titleTextWidget = Text(
              effectiveTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: RafiDesignTokens.fontFamily,
                package: RafiDesignTokens.fontPackage,
                fontSize: RafiDesignTokens.titleSize,
                fontWeight: RafiDesignTokens.titleWeight,
                letterSpacing: RafiDesignTokens.titleTracking,
                color: RafiDesignTokens.ink,
                height: 1.0,
              ),
            );

            final double blur = engine.state.titleBlur;
            if (blur > 0.02) {
              titleTextWidget = ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: titleTextWidget,
              );
            }
            return titleTextWidget;
          },
        ),
        const SizedBox(height: 8.0),

        // Subtitle
        Text(
          effectiveSubtitle,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: RafiDesignTokens.fontFamily,
            package: RafiDesignTokens.fontPackage,
            fontSize: RafiDesignTokens.subtitleSize,
            fontWeight: RafiDesignTokens.subtitleWeight,
            color:
                (authError != null ||
                    identifierError != null ||
                    passwordError != null)
                ? RafiDesignTokens.error
                : RafiDesignTokens.muted,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 24.0),

        // Optional Name Field (3-field mode)
        if (showNameField &&
            nameController != null &&
            nameFocusNode != null) ...[
          RafiFormField(
            fieldKey: const Key('name_field'),
            label: RafiLoginContent.nameLabel,
            placeholder: RafiLoginContent.namePlaceholder,
            controller: nameController!,
            focusNode: nameFocusNode!,
            isError: nameError != null,
            errorMessage: nameError,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.name,
            autofillHints: const [AutofillHints.name],
            enabled: !isLoading && !isSuccess,
            onChanged: (val) {
              engine.lookAtField(0, val.length * 8.0);
            },
          ),
          const SizedBox(height: 16.0),
        ],

        // Primary Identifier Field (Email / Username) with scoped shake listener
        ListenableBuilder(
          listenable: engine,
          builder: (context, _) {
            return RafiFormField(
              fieldKey: const Key('identifier_field'),
              label: identifierLabel ?? _defaultIdentifierLabel(),
              placeholder:
                  identifierPlaceholder ?? _defaultIdentifierPlaceholder(),
              controller: identifierController,
              focusNode: identifierFocusNode,
              isError: identifierError != null,
              errorMessage: identifierError,
              shakeX: engine.state.emailShakeX,
              showCheck: true,
              checkOpacity: isIdentifierValid ? 1.0 : 0.0,
              checkScale: isIdentifierValid ? 1.0 : 0.5,
              keyboardType: _identifierKeyboardType(),
              autofillHints: _identifierAutofillHints(),
              textInputAction: TextInputAction.next,
              enabled: !isLoading && !isSuccess,
              onChanged: (val) {
                engine.lookAtField(showNameField ? 1 : 0, val.length * 8.0);
              },
            );
          },
        ),
        const SizedBox(height: 16.0),

        // Password Field with inline Forgot Password action
        RafiFormField(
          fieldKey: const Key('password_field'),
          label: passwordLabel ?? RafiLoginContent.passwordLabel,
          trailingAction: onForgotPassword != null
              ? GestureDetector(
                  key: const Key('forgot_password_button'),
                  onTap: (!isLoading && !isSuccess) ? onForgotPassword : null,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4.0,
                      vertical: 2.0,
                    ),
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        fontFamily: RafiDesignTokens.fontFamily,
                        package: RafiDesignTokens.fontPackage,
                        fontSize: RafiDesignTokens.labelSize,
                        fontWeight: RafiDesignTokens.labelWeight,
                        color: RafiDesignTokens.muted,
                        height: 1.0,
                      ),
                    ),
                  ),
                )
              : null,
          placeholder:
              passwordPlaceholder ?? RafiLoginContent.passwordPlaceholder,
          controller: passwordController,
          focusNode: passwordFocusNode,
          isPassword: true,
          obscureText: isPasswordObscured,
          onTogglePasswordVisibility: onTogglePasswordVisibility,
          isError: passwordError != null,
          errorMessage: passwordError,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          enabled: !isLoading && !isSuccess,
          onChanged: (val) {
            engine.lookAtField(showNameField ? 2 : 1, val.length * 8.0);
          },
          onSubmitted: (_) => onLoginPressed(),
        ),

        // Optional Password Strength Meter reactively listening to password keystrokes
        if (showPasswordStrength) ...[
          const SizedBox(height: 10.0),
          ListenableBuilder(
            listenable: passwordController,
            builder: (context, _) {
              return PasswordStrengthMeter(
                passwordDots: passwordController.text.length,
                maxDots: RafiLoginContent.passwordLength,
              );
            },
          ),
        ],

        const SizedBox(height: 22.0),

        // Main Action Button (Log in / Create account) with scoped press & spinner listener
        ListenableBuilder(
          listenable: engine,
          builder: (context, _) {
            final state = engine.state;
            return SignupButton(
              isLoading: isLoading,
              isDone: isSuccess,
              enabled: !isLoading && !isSuccess,
              label: loginButtonText ?? RafiLoginContent.button,
              loadingLabel:
                  loginButtonLoadingText ?? RafiLoginContent.buttonLoading,
              doneLabel: loginButtonSuccessText ?? RafiLoginContent.buttonDone,
              pressScale: state.buttonPressScale,
              spinnerAngle: state.spinnerAngle,
              onTap: () {
                engine.lookAtButton();
                engine.triggerButtonPress();
                onLoginPressed();
              },
            );
          },
        ),
        const SizedBox(height: 18.0),

        // Footer (e.g. "Don't have an account? Sign up" / "Already a member? Log in")
        Center(
          child: GestureDetector(
            key: const Key('create_account_button'),
            onTap: (!isLoading && !isSuccess) ? onCreateAccount : null,
            behavior: HitTestBehavior.opaque,
            child: Text.rich(
              TextSpan(
                text: '${footerPromptText ?? RafiLoginContent.member} ',
                style: const TextStyle(
                  fontFamily: RafiDesignTokens.fontFamily,
                  package: RafiDesignTokens.fontPackage,
                  fontSize: RafiDesignTokens.memberSize,
                  fontWeight: RafiDesignTokens.memberWeight,
                  color: RafiDesignTokens.muted,
                  height: 1.0,
                ),
                children: [
                  TextSpan(
                    text: footerActionText ?? RafiLoginContent.login,
                    style: const TextStyle(
                      fontFamily: RafiDesignTokens.fontFamily,
                      package: RafiDesignTokens.fontPackage,
                      fontSize: RafiDesignTokens.memberSize,
                      fontWeight: RafiDesignTokens.loginWeight,
                      color: RafiDesignTokens.ink,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Quick Guest / Skip to Studio Button
        if (onSkip != null) ...[
          const SizedBox(height: 14.0),
          Center(
            child: GestureDetector(
              key: const Key('skip_to_studio_button'),
              onTap: (!isLoading && !isSuccess) ? onSkip : null,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                child: Text(
                  skipButtonText ?? LumaLoginContent.continueAsGuest,
                  style: const TextStyle(
                    fontFamily: RafiDesignTokens.fontFamily,
                    package: RafiDesignTokens.fontPackage,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    color: RafiDesignTokens.ink,
                    decoration: TextDecoration.underline,
                    decorationColor: RafiDesignTokens.muted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

typedef LumaLoginForm = RafiLoginForm;
