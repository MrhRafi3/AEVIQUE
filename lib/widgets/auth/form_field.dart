import 'package:flutter/material.dart';
import 'design_tokens.dart';
import 'login_content.dart';

/// Interactive form field with real text input, focus tracking,
/// password visibility toggle, checkmark indicator, and shake animation.
class RafiFormField extends StatelessWidget {
  final String label;
  final double? labelTop;
  final double? inputTop;
  final String placeholder;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onTogglePasswordVisibility;
  final bool isError;
  final String? errorMessage;
  final double shakeX;
  final bool showCheck;
  final double checkOpacity;
  final double checkScale;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final bool enabled;
  final Key? fieldKey;
  final Widget? trailingAction;

  const RafiFormField({
    super.key,
    required this.label,
    this.labelTop,
    this.inputTop,
    required this.placeholder,
    required this.controller,
    required this.focusNode,
    this.isPassword = false,
    this.obscureText = true,
    this.onTogglePasswordVisibility,
    this.isError = false,
    this.errorMessage,
    this.shakeX = 0.0,
    this.showCheck = false,
    this.checkOpacity = 0.0,
    this.checkScale = 1.0,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onSubmitted,
    this.autofillHints,
    this.enabled = true,
    this.fieldKey,
    this.trailingAction,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) {
        final bool isFocused = focusNode.hasFocus;
        final Color borderColor = isError
            ? RafiDesignTokens.error
            : (isFocused ? RafiDesignTokens.ink : RafiDesignTokens.fieldEdge);
        final double borderWidth = (isError || isFocused) ? 2.0 : 1.5;

        final Widget labelTextWidget = Text(
          label,
          style: const TextStyle(
            fontFamily: RafiDesignTokens.fontFamily,
            package: RafiDesignTokens.fontPackage,
            fontSize: RafiDesignTokens.labelSize,
            fontWeight: RafiDesignTokens.labelWeight,
            letterSpacing: RafiDesignTokens.labelTracking,
            color: RafiDesignTokens.muted,
            height: 1.0,
          ),
        );

        final Widget inputBox = Transform.translate(
          offset: Offset(shakeX, 0.0),
          child: Container(
            height: RafiDesignTokens.fieldHeight,
            padding: const EdgeInsets.symmetric(
              horizontal: RafiDesignTokens.fieldPaddingHorizontal,
            ),
            decoration: BoxDecoration(
              color: RafiDesignTokens.fieldFill,
              borderRadius: BorderRadius.circular(RafiDesignTokens.fieldRadius),
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            child: Row(
              children: [
                // Real editable text field
                Expanded(
                  child: Semantics(
                    label: label,
                    child: TextField(
                      key: fieldKey,
                      controller: controller,
                      focusNode: focusNode,
                      obscureText: isPassword && obscureText,
                      obscuringCharacter: RafiLoginContent.passwordDot,
                      enabled: enabled,
                      keyboardType: keyboardType,
                      textInputAction: textInputAction,
                      onChanged: onChanged,
                      onSubmitted: onSubmitted,
                      autofillHints: autofillHints,
                      style: TextStyle(
                        fontFamily: RafiDesignTokens.fontFamily,
                        package: RafiDesignTokens.fontPackage,
                        fontSize: RafiDesignTokens.fieldSize,
                        fontWeight: RafiDesignTokens.fieldWeight,
                        letterSpacing: (isPassword && obscureText)
                            ? RafiDesignTokens.dotsTracking
                            : null,
                        color: RafiDesignTokens.ink,
                        height: 1.0,
                      ),
                      cursorColor: RafiDesignTokens.ink,
                      cursorWidth: RafiDesignTokens.caretWidth,
                      cursorRadius: const Radius.circular(
                        RafiDesignTokens.caretRadius,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        hintText: placeholder,
                        hintStyle: const TextStyle(
                          fontFamily: RafiDesignTokens.fontFamily,
                          package: RafiDesignTokens.fontPackage,
                          fontSize: RafiDesignTokens.fieldSize,
                          fontWeight: RafiDesignTokens.placeholderWeight,
                          color: RafiDesignTokens.placeholder,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),

                // Password Visibility Toggle
                if (isPassword)
                  GestureDetector(
                    key: const Key('password_visibility_toggle'),
                    onTap: onTogglePasswordVisibility,
                    behavior: HitTestBehavior.opaque,
                    child: Semantics(
                      button: true,
                      label: obscureText ? 'Show password' : 'Hide password',
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 48.0,
                          minHeight: 48.0,
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Icon(
                          obscureText
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20.0,
                          color: isFocused
                              ? RafiDesignTokens.ink
                              : RafiDesignTokens.muted,
                        ),
                      ),
                    ),
                  ),

                // Green Checkmark indicator (for valid identifier)
                if (showCheck && !isPassword)
                  Opacity(
                    opacity: checkOpacity,
                    child: Transform.scale(
                      scale: checkScale,
                      child: Container(
                        width: RafiDesignTokens.checkSize,
                        height: RafiDesignTokens.checkSize,
                        decoration: const BoxDecoration(
                          color: RafiDesignTokens.ok,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          RafiLoginContent.check,
                          style: TextStyle(
                            color: RafiDesignTokens.onOk,
                            fontSize: RafiDesignTokens.checkFontSize,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );

        final Widget? errorWidget =
            (isError && errorMessage != null && errorMessage!.isNotEmpty)
            ? Text(
                errorMessage!,
                maxLines: 2,
                softWrap: true,
                style: const TextStyle(
                  fontFamily: RafiDesignTokens.fontFamily,
                  package: RafiDesignTokens.fontPackage,
                  fontSize: RafiDesignTokens.errorSize,
                  fontWeight: RafiDesignTokens.errorWeight,
                  color: RafiDesignTokens.error,
                  height: 1.1,
                ),
              )
            : null;

        // Legacy absolute positioning if explicit coordinates are provided
        if (labelTop != null && inputTop != null) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: RafiDesignTokens.labelLeft,
                top: labelTop,
                child: labelTextWidget,
              ),
              Positioned(
                left: RafiDesignTokens.fieldInset,
                right: RafiDesignTokens.fieldInset,
                top: inputTop,
                height: RafiDesignTokens.fieldHeight,
                child: inputBox,
              ),
              if (errorWidget != null)
                Positioned(
                  left: RafiDesignTokens.errorLeft,
                  right: RafiDesignTokens.fieldInset,
                  top: inputTop! + RafiDesignTokens.fieldHeight + 4.0,
                  child: errorWidget,
                ),
            ],
          );
        }

        // Modern responsive flow layout
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 2.0),
                  child: labelTextWidget,
                ),
                ?trailingAction,
              ],
            ),
            const SizedBox(height: 6.0),
            inputBox,
            if (errorWidget != null) ...[
              const SizedBox(height: 4.0),
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: errorWidget,
              ),
            ],
          ],
        );
      },
    );
  }
}

typedef LumaFormField = RafiFormField;
