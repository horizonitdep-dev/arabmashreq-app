import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/config/app_config.dart';
import '../../../core/storage/local_storage.dart';
import '../../../shared/models/auth_user_model.dart';
import '../../../shared/models/notification_preferences_model.dart';
import '../../../shared/services/api_exception.dart';
import '../../../shared/services/service_providers.dart';

class AuthState {
  const AuthState({
    required this.initialized,
    required this.isLoading,
    this.user,
    this.token,
    this.message,
    this.errorMessage,
    this.fieldErrors = const <String, String>{},
    this.preferences = NotificationPreferencesModel.defaults,
    this.preferencesLoading = false,
  });

  final bool initialized;
  final bool isLoading;
  final AuthUserModel? user;
  final String? token;
  final String? message;
  final String? errorMessage;
  final Map<String, String> fieldErrors;
  final NotificationPreferencesModel preferences;
  final bool preferencesLoading;

  bool get isAuthenticated =>
      token != null && token!.isNotEmpty && user != null;

  AuthState copyWith({
    bool? initialized,
    bool? isLoading,
    AuthUserModel? user,
    String? token,
    String? message,
    String? errorMessage,
    Map<String, String>? fieldErrors,
    NotificationPreferencesModel? preferences,
    bool? preferencesLoading,
    bool clearUser = false,
    bool clearToken = false,
    bool clearMessage = false,
    bool clearError = false,
  }) {
    return AuthState(
      initialized: initialized ?? this.initialized,
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : (user ?? this.user),
      token: clearToken ? null : (token ?? this.token),
      message: clearMessage ? null : (message ?? this.message),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      fieldErrors: fieldErrors ?? this.fieldErrors,
      preferences: preferences ?? this.preferences,
      preferencesLoading: preferencesLoading ?? this.preferencesLoading,
    );
  }

  static const AuthState initial = AuthState(
    initialized: false,
    isLoading: false,
  );
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this.ref) : super(AuthState.initial) {
    loadSession();
  }

  final Ref ref;

  Future<void> loadSession() async {
    final storage = await ref.read(localStorageProvider.future);
    final backend = ref.read(backendServiceProvider);

    final token = storage.getAuthToken();
    final userJson = storage.getAuthUser();

    if (token == null || userJson == null) {
      backend.setToken(null);
      state =
          state.copyWith(initialized: true, clearUser: true, clearToken: true);
      return;
    }

    backend.setToken(token);
    final cachedUser = AuthUserModel.fromJson(userJson);
    state = state.copyWith(
      initialized: true,
      token: token,
      user: cachedUser,
      clearError: true,
      fieldErrors: const <String, String>{},
    );

    try {
      final freshUser = await backend.fetchProfile();
      await storage.setAuthUser(freshUser.toJson());
      state = state.copyWith(user: freshUser);
      await loadPreferences();
    } catch (_) {
      await clearSession();
    }
  }

  Future<bool> login({
    required String email,
    required String password,
    String deviceName = 'mobile-app',
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearMessage: true,
      fieldErrors: const <String, String>{},
    );

    try {
      final response = await ref.read(backendServiceProvider).login(
            email: email,
            password: password,
            deviceName: deviceName,
          );

      await _persistSession(token: response.token, user: response.user);
      await _registerCurrentDeviceToken();
      state = state.copyWith(
        isLoading: false,
        token: response.token,
        user: response.user,
        message: response.message,
      );
      await loadPreferences();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        fieldErrors: e.fieldErrors,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'حدث خطأ غير متوقع أثناء تسجيل الدخول.',
      );
      return false;
    }
  }

  Future<bool> loginWithGoogle({String deviceName = 'mobile-app'}) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearMessage: true,
      fieldErrors: const <String, String>{},
    );

    try {
      final googleSignIn = _buildGoogleSignIn();
      final account = await googleSignIn.signIn();
      if (account == null) {
        state = state.copyWith(
          isLoading: false,
          message: 'تم إلغاء تسجيل الدخول عبر Google.',
        );
        return false;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw ApiException(
          message: 'تعذر الحصول على رمز التحقق من Google.',
        );
      }

      final response = await ref.read(backendServiceProvider).googleLogin(
            idToken: idToken,
            accessToken: auth.accessToken,
            deviceName: deviceName,
          );

      await _persistSession(token: response.token, user: response.user);
      await _registerCurrentDeviceToken();
      state = state.copyWith(
        isLoading: false,
        token: response.token,
        user: response.user,
        message: response.message,
      );
      await loadPreferences();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        fieldErrors: e.fieldErrors,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'تعذر تسجيل الدخول عبر Google حالياً.',
      );
      return false;
    }
  }

  Future<bool> loginWithApple({String deviceName = 'mobile-app'}) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearMessage: true,
      fieldErrors: const <String, String>{},
    );

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        throw ApiException(
          message:
              '\u062a\u0639\u0630\u0631 \u0627\u0644\u062d\u0635\u0648\u0644 \u0639\u0644\u0649 \u0631\u0645\u0632 \u0627\u0644\u062a\u062d\u0642\u0642 \u0645\u0646 Apple.',
        );
      }

      final authorizationCode = credential.authorizationCode;
      final fullName = [
        credential.givenName,
        credential.familyName,
      ].where((part) => part != null && part.trim().isNotEmpty).join(' ');

      final response = await ref.read(backendServiceProvider).appleLogin(
            identityToken: identityToken,
            authorizationCode: authorizationCode,
            userIdentifier: credential.userIdentifier,
            email: credential.email,
            fullName: fullName.isEmpty ? null : fullName,
            deviceName: deviceName,
          );

      await _persistSession(token: response.token, user: response.user);
      await _registerCurrentDeviceToken();
      state = state.copyWith(
        isLoading: false,
        token: response.token,
        user: response.user,
        message: response.message,
      );
      await loadPreferences();
      return true;
    } on SignInWithAppleAuthorizationException catch (e) {
      state = state.copyWith(
        isLoading: false,
        message: e.code == AuthorizationErrorCode.canceled
            ? '\u062a\u0645 \u0625\u0644\u063a\u0627\u0621 \u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062f\u062e\u0648\u0644 \u0639\u0628\u0631 Apple.'
            : null,
        errorMessage: e.code == AuthorizationErrorCode.canceled
            ? null
            : '\u062a\u0639\u0630\u0631 \u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062f\u062e\u0648\u0644 \u0639\u0628\u0631 Apple \u062d\u0627\u0644\u064a\u0627\u064b.',
      );
      return false;
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        fieldErrors: e.fieldErrors,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            '\u062a\u0639\u0630\u0631 \u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062f\u062e\u0648\u0644 \u0639\u0628\u0631 Apple \u062d\u0627\u0644\u064a\u0627\u064b.',
      );
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    String? phone,
    required String password,
    required String passwordConfirmation,
    String deviceName = 'mobile-app',
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearMessage: true,
      fieldErrors: const <String, String>{},
    );

    try {
      final response = await ref.read(backendServiceProvider).register(
            name: name,
            email: email,
            phone: phone,
            password: password,
            passwordConfirmation: passwordConfirmation,
            deviceName: deviceName,
          );

      await _persistSession(token: response.token, user: response.user);
      await _registerCurrentDeviceToken();
      state = state.copyWith(
        isLoading: false,
        token: response.token,
        user: response.user,
        message: response.message,
      );
      await loadPreferences();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        fieldErrors: e.fieldErrors,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'حدث خطأ غير متوقع أثناء إنشاء الحساب.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    state =
        state.copyWith(isLoading: true, clearError: true, clearMessage: true);
    await ref.read(backendServiceProvider).logout();
    await _signOutGoogleIfNeeded();
    await clearSession();
    state = state.copyWith(isLoading: false, message: 'تم تسجيل الخروج بنجاح.');
  }

  Future<void> clearSession() async {
    final storage = await ref.read(localStorageProvider.future);
    await storage.clearAuthSession();
    ref.read(backendServiceProvider).setToken(null);
    state = state.copyWith(
      clearUser: true,
      clearToken: true,
      preferences: NotificationPreferencesModel.defaults,
      fieldErrors: const <String, String>{},
    );
  }

  Future<void> refreshProfile() async {
    if (!state.isAuthenticated) return;

    try {
      final freshUser = await ref.read(backendServiceProvider).fetchProfile();
      final storage = await ref.read(localStorageProvider.future);
      await storage.setAuthUser(freshUser.toJson());
      state = state.copyWith(user: freshUser, clearError: true);
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(errorMessage: 'تعذر تحديث بيانات الحساب.');
    }
  }

  Future<void> loadPreferences() async {
    if (!state.isAuthenticated) return;

    state = state.copyWith(preferencesLoading: true, clearError: true);
    try {
      final prefs =
          await ref.read(backendServiceProvider).fetchUserPreferences();
      state = state.copyWith(preferences: prefs, preferencesLoading: false);
    } on ApiException catch (e) {
      state =
          state.copyWith(preferencesLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        preferencesLoading: false,
        errorMessage: 'تعذر تحميل تفضيلات الإشعارات.',
      );
    }
  }

  Future<bool> savePreferences(NotificationPreferencesModel prefs) async {
    if (!state.isAuthenticated) return false;

    state = state.copyWith(
        preferencesLoading: true, clearError: true, clearMessage: true);
    try {
      final updated =
          await ref.read(backendServiceProvider).updateUserPreferences(prefs);
      state = state.copyWith(
        preferencesLoading: false,
        preferences: updated,
        message: 'تم حفظ تفضيلات الإشعارات.',
      );
      return true;
    } on ApiException catch (e) {
      state =
          state.copyWith(preferencesLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        preferencesLoading: false,
        errorMessage: 'تعذر حفظ التفضيلات حالياً.',
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(
        clearError: true,
        clearMessage: true,
        fieldErrors: const <String, String>{});
  }

  Future<void> _persistSession(
      {required String token, required AuthUserModel user}) async {
    final storage = await ref.read(localStorageProvider.future);
    await storage.setAuthToken(token);
    await storage.setAuthUser(user.toJson());
    ref.read(backendServiceProvider).setToken(token);
  }

  GoogleSignIn _buildGoogleSignIn() {
    return GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: AppConfig.googleWebClientId.trim().isEmpty
          ? null
          : AppConfig.googleWebClientId.trim(),
    );
  }

  Future<void> _signOutGoogleIfNeeded() async {
    try {
      await _buildGoogleSignIn().signOut();
    } catch (_) {
      // Keep logout flow resilient.
    }
  }

  Future<void> _registerCurrentDeviceToken() async {
    try {
      final storage = await ref.read(localStorageProvider.future);
      final token = storage.getLastFcmToken();
      if (token == null || token.isEmpty) return;
      final deviceId = storage.getOrCreateDeviceId();
      await ref.read(backendServiceProvider).registerFcmToken(token, deviceId);
    } catch (_) {
      // Keep authentication flow resilient even if FCM registration fails.
    }
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});
