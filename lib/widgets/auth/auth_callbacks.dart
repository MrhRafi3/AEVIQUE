import 'dart:async';
import 'login_credentials.dart';

/// Function signature for the login callback.
///
/// Can return an [AuthResult], complete normally on success, or throw an exception
/// with a user-friendly error message on failure.
typedef RafiLoginCallback =
    FutureOr<dynamic> Function(LoginCredentials credentials);

typedef LumaLoginCallback = RafiLoginCallback;

/// Function signature for post-authentication callback.
typedef RafiAuthenticatedCallback = void Function(LoginCredentials credentials);
typedef LumaAuthenticatedCallback = RafiAuthenticatedCallback;
