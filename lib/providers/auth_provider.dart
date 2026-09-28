import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../data/models/auth_api_models.dart';
import '../data/storage/local_storage.dart';
import '../providers/providers.dart';

part 'auth_provider.freezed.dart';
part 'auth_provider.g.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    @Default(false) bool isLoading,
    @Default(false) bool isSignedIn,
    User? user,
    String? error,
    ApiUser? apiUser,
  }) = _AuthState;
}

@riverpod
class Auth extends _$Auth {
  final Logger _logger = Logger('GoogleAuth');

  late final GoogleSignIn _googleSignIn;
  late final FirebaseAuth _firebaseAuth;

  static bool get isAppleSignInAvailable {
    return !kIsWeb && (Platform.isIOS || Platform.isMacOS);
  }

  @override
  AuthState build() {
    _googleSignIn = GoogleSignIn(
      serverClientId: '609784996081-iajntrguv1shj44an71mjml59a17igdi.apps.googleusercontent.com',
      scopes: [
        'email',
        'profile',
      ],
      // Add your OAuth client ID here
      // clientId: _getClientId(),
    );

    _firebaseAuth = FirebaseAuth.instance;

    scheduleMicrotask(() async {
      await _checkCurrentUser();
    });

    ref.read(localStorageProvider).addListener(StorageKey.token, (value) {
      if (value == null) {
        state = state.copyWith(isSignedIn: false, user: null);
      } else {
        // state = state.copyWith(status: AuthStatus.authenticated);
      }
    });

    return const AuthState();
  }

  Future<void> _checkCurrentUser() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (ref.read(localStorageProvider).token?.isNotEmpty == true) {
        state = state.copyWith(
          isSignedIn: true,
          user: currentUser,
        );

        // Try to get user info from API
        await _fetchUserProfile();
      }
    } catch (e) {
      _logger.info('No existing Google sign-in found: $e');
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
      );

      ref.read(analyticsProvider).logEvent(name: 'google_sign_in_attempt');

      // Sign in with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        state = state.copyWith(isLoading: false);
        return;
      }

      // Get Google authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Sign in with Firebase using Google credentials
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        // Get ID token for API authentication
        final idToken = await firebaseUser.getIdToken();
        if (idToken == null) {
          throw Exception('Failed to get ID token');
        }

        // Authenticate with your API using the Firebase ID token
        await _authenticateWithAPI(idToken, googleUser: googleUser);

        state = state.copyWith(
          isLoading: false,
          isSignedIn: true,
          user: firebaseUser,
        );

        ref.read(analyticsProvider).logEvent(
          name: 'google_sign_in_success',
          parameters: {
            'user_id': firebaseUser.uid,
            'email': firebaseUser.email ?? '',
          },
        );
      } else {
        throw Exception('Firebase authentication failed');
      }
    } catch (e) {
      _logger.severe('Google sign-in failed: $e');

      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );

      ref.read(analyticsProvider).logEvent(
        name: 'google_sign_in_failed',
        parameters: {'error': e.toString()},
      );
    }
  }

  Future<void> signInWithApple() async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
      );

      ref.read(analyticsProvider).logEvent(name: 'apple_sign_in_attempt');

      // Request Apple Sign-In
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: kIsWeb
            ? WebAuthenticationOptions(
                clientId: 'your-apple-service-id',
                redirectUri: Uri.parse('https://keremetapps.if.ua/auth/callback'),
              )
            : null,
      );

      // Create Firebase credential from Apple credential
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in with Firebase using Apple credentials
      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(oauthCredential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        // Get ID token for API authentication
        final idToken = await firebaseUser.getIdToken();
        if (idToken == null) {
          throw Exception('Failed to get ID token');
        }

        // Update display name if this is the first time signing in
        if (firebaseUser.displayName == null &&
            appleCredential.givenName != null &&
            appleCredential.familyName != null) {
          final displayName = '${appleCredential.givenName} ${appleCredential.familyName}';
          await firebaseUser.updateDisplayName(displayName);
        }

        // Authenticate with your API using the Firebase ID token
        await _authenticateWithAPI(
          idToken,
          appleCredential: appleCredential,
        );

        state = state.copyWith(
          isLoading: false,
          isSignedIn: true,
          user: firebaseUser,
        );

        ref.read(analyticsProvider).logEvent(
          name: 'apple_sign_in_success',
          parameters: {
            'user_id': firebaseUser.uid,
            'email': firebaseUser.email ?? '',
          },
        );
      } else {
        throw Exception('Firebase authentication failed');
      }
    } catch (e) {
      _logger.severe('Apple sign-in failed: $e');

      // Handle specific Apple Sign-In errors
      String errorMessage = _getAppleSignInErrorMessage(e);

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );

      ref.read(analyticsProvider).logEvent(
        name: 'apple_sign_in_failed',
        parameters: {'error': e.toString()},
      );
    }
  }

  Future<void> _authenticateWithAPI(
    String idToken, {
    GoogleSignInAccount? googleUser,
    AuthorizationCredentialAppleID? appleCredential,
  }) async {
    assert(idToken.isNotEmpty, 'ID token must not be empty');
    assert(googleUser != null || appleCredential != null, 'At least one credential must be provided');
    try {
      final response = await ref.read(authAPIRepoProvider).loginWithGoogle(
            idToken: idToken,
            email: googleUser?.email ?? appleCredential?.email ?? '',
            displayName: googleUser?.displayName ?? appleCredential?.givenName,
            photoUrl: googleUser?.photoUrl,
          );

      if (response.success && response.data != null) {
        state = state.copyWith(apiUser: response.data!.user);

        // Store the API token
        ref.read(localStorageProvider).setToken(response.data!.token);
      } else {
        throw Exception(response.error ?? 'API authentication failed');
      }
    } catch (e) {
      _logger.severe('API authentication failed: $e');
      rethrow;
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final response = await ref.read(authAPIRepoProvider).getProfile();

      if (response.success && response.data != null) {
        state = state.copyWith(apiUser: response.data);
      }
    } catch (e) {
      _logger.warning('Failed to fetch user profile: $e');
    }
  }

  Future<void> signOut() async {
    try {
      state = state.copyWith(isLoading: true);

      // Sign out from Google
      await _googleSignIn.signOut();

      // Sign out from Firebase
      await _firebaseAuth.signOut();

      // Clear API token
      ref.read(localStorageProvider).clearToken();

      state = const AuthState();

      ref.read(analyticsProvider).logEvent(name: 'google_sign_out');
    } catch (e) {
      _logger.severe('Sign out failed: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to sign out: $e',
      );
    }
  }

  Future<void> deleteAccount() async {
    try {
      state = state.copyWith(isLoading: true);

      // Delete from your API first
      if (state.apiUser != null) {
        await ref.read(authAPIRepoProvider).deleteAccount();
      }

      // Delete Firebase account
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        await currentUser.delete();
      }

      // Sign out from Google
      await _googleSignIn.signOut();

      // Clear local storage
      ref.read(localStorageProvider).clearToken();

      state = const AuthState();

      ref.read(analyticsProvider).logEvent(name: 'google_account_deleted');
    } catch (e) {
      _logger.severe('Account deletion failed: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete account: $e',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  String _getAppleSignInErrorMessage(dynamic error) {
    if (error is SignInWithAppleAuthorizationException) {
      switch (error.code) {
        case AuthorizationErrorCode.canceled:
          return 'Apple Sign-In was canceled.';
        case AuthorizationErrorCode.failed:
          return 'Apple Sign-In failed. Please try again.';
        case AuthorizationErrorCode.invalidResponse:
          return 'Invalid response from Apple Sign-In.';
        case AuthorizationErrorCode.notHandled:
          return 'Apple Sign-In request was not handled.';
        case AuthorizationErrorCode.unknown:
          return 'An unknown error occurred with Apple Sign-In.';
        default:
          return 'Apple Sign-In failed: ${error.message}';
      }
    }
    return _getErrorMessage(error);
  }

  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'account-exists-with-different-credential':
          return 'An account already exists with a different sign-in method.';
        case 'invalid-credential':
          return 'The credential is invalid or has expired.';
        case 'operation-not-allowed':
          return 'Google sign-in is not enabled.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'invalid-verification-code':
          return 'Invalid verification code.';
        case 'invalid-verification-id':
          return 'Invalid verification ID.';
        default:
          return 'Authentication failed: ${error.message}';
      }
    } else if (error.toString().contains('network_error')) {
      return 'Network error. Please check your internet connection.';
    } else if (error.toString().contains('sign_in_canceled')) {
      return 'Sign-in was cancelled.';
    } else if (error.toString().contains('sign_in_failed')) {
      return 'Google sign-in failed. Please try again.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }
}
