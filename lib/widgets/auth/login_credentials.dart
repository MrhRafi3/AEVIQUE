/// Mode for the primary identifier field in the Login Screen.
enum RafiIdentifierType {
  /// Standard email address format with validation.
  email,

  /// Username identifier.
  username,

  /// Flexible field accepting either an email address or username.
  emailOrUsername,

  /// Full name identifier.
  name,
}

typedef LumaIdentifierType = RafiIdentifierType;

/// Strongly typed credentials model delivered to authentication callbacks.
///
/// Password strings are protected in [toString] to prevent accidental exposure
/// in application logs or crash reporting tools.
class LoginCredentials {
  /// The user-entered identifier (email, username, or name).
  final String identifier;

  /// The user-entered password.
  final String password;

  /// Optional display name if a name field was enabled.
  final String? name;

  const LoginCredentials({
    required this.identifier,
    required this.password,
    this.name,
  });

  @override
  String toString() =>
      'LoginCredentials(identifier: $identifier, password: [PROTECTED]'
      '${name != null ? ', name: $name' : ''})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoginCredentials &&
          runtimeType == other.runtimeType &&
          identifier == other.identifier &&
          password == other.password &&
          name == other.name;

  @override
  int get hashCode => Object.hash(identifier, password, name);
}

/// Typed result contract for authentication callbacks.
class AuthResult {
  /// Whether the authentication succeeded.
  final bool isSuccess;

  /// User-friendly error message if authentication failed.
  final String? errorMessage;

  /// Creates a successful authentication result.
  const AuthResult.success() : isSuccess = true, errorMessage = null;

  /// Creates a failed authentication result with a descriptive [errorMessage].
  const AuthResult.failure(this.errorMessage) : isSuccess = false;

  @override
  String toString() =>
      isSuccess ? 'AuthResult.success()' : 'AuthResult.failure($errorMessage)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthResult &&
          runtimeType == other.runtimeType &&
          isSuccess == other.isSuccess &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(isSuccess, errorMessage);
}
