import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../authentication/application/auth_controller.dart';
import '../data/user_repository.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';

final interfaceSettingsProvider =
    StateNotifierProvider<InterfaceSettingsNotifier, InterfaceSettings>((ref) {
  return InterfaceSettingsNotifier(ref);
});

class InterfaceSettings {
  static const String technical = 'TECHNICAL';
  static const String classic = 'HUMAN';

  final bool isGridVisible;
  final String typography;

  InterfaceSettings({
    this.isGridVisible = true,
    this.typography = technical,
  });

  InterfaceSettings copyWith({
    bool? isGridVisible,
    String? typography,
  }) {
    return InterfaceSettings(
      isGridVisible: isGridVisible ?? this.isGridVisible,
      typography: typography ?? this.typography,
    );
  }
}

class InterfaceSettingsNotifier extends StateNotifier<InterfaceSettings> {
  final Ref _ref;
  ProviderSubscription? _userSub;

  InterfaceSettingsNotifier(this._ref) : super(InterfaceSettings()) {
    _loadSettings();
    _listenToUserChanges();
  }

  static const _gridKey = 'sys_grid_visibility';
  static const _typoKey = 'sys_typography_preference';

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      isGridVisible: prefs.getBool(_gridKey) ?? true,
      typography: prefs.getString(_typoKey) ?? InterfaceSettings.technical,
    );
  }

  void _listenToUserChanges() {
    // Escuchar cambios de autenticación para suscribirse/desuscribirse
    _ref.listen(authStateChangesProvider, (previous, next) {
      final user = next.value;

      // Limpiar suscripción previa si existe
      _userSub?.close();
      _userSub = null;

      if (user != null) {
        // Nueva suscripción para el usuario activo
        _userSub = _ref.listen(userStreamProvider(user.uid), (prev, snapshot) {
          final userModel = snapshot.value;
          if (userModel != null) {
            // ✅ FIX: Evitamos .name.toUpperCase() para prevenir NoSuchMethodError en Web/DDC
            final String typo =
                userModel.typographyStyle == TypographyStyle.technical
                    ? InterfaceSettings.technical
                    : InterfaceSettings.classic;

            if (typo != state.typography) {
              state = state.copyWith(typography: typo);
            }
          }
        }, fireImmediately: true);
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _userSub?.close();
    super.dispose();
  }

  Future<void> setGridVisibility(bool visible) async {
    state = state.copyWith(isGridVisible: visible);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_gridKey, visible);
  }

  Future<void> setTypography(String type) async {
    state = state.copyWith(typography: type);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_typoKey, type);

    // Sincronizar con Firestore si el usuario está autenticado
    final user = _ref.read(authStateChangesProvider).value;
    if (user != null) {
      await _ref.read(userRepositoryProvider).updateUser(user.uid, {
        'typographyStyle':
            type == InterfaceSettings.technical ? 'technical' : 'human',
      });
    }
  }
}
