# 🚀 PLAN DE ACCIÓN PARA PRODUCCIÓN
**ElenaApp - Release Roadmap**  
**Duración estimada**: 4-5 semanas  
**Prioridad**: CRÍTICA  
**Rama**: `nutricion` (en desarrollo)

---

## 📊 ROADMAP VISUAL

```
SEMANA 1: SEGURIDAD CRÍTICA
├─ Limpiar credenciales en memory
├─ Remover keys hardcodeadas
├─ Agregar flutter_secure_storage
├─ Cleanup print statements
└─ Agregar permission_handler

SEMANA 2: ARQUITECTURA & REFACTOR
├─ Mover queries Firestore a Data layer
├─ Crear FoodRepository completo
├─ Implementar Dependency Injection
├─ Standardizar Riverpod providers
└─ Eliminar archivos duplicados

SEMANA 3: TESTING & VALIDACIÓN
├─ Input validation en todos formularios
├─ Error handling consistente
├─ Connectivity checks
├─ Ejecutar test suite (70%+ coverage)
└─ Firebase Crashlytics

SEMANA 4: COMPLIANCE
├─ Privacy Policy & Terms of Service
├─ HealthKit/Health Connect setup
├─ Preparar screenshots & metadata
├─ Firestore Rules audit
└─ HIPAA/GDPR verification

SEMANA 5: BUILD & RELEASE
├─ Android release build & test
├─ iOS release build & test
├─ Internal testing (alpha/beta)
└─ Store submission
```

---

## 📋 CHECKLIST DETALLADO POR FASE

### FASE 1: SEGURIDAD CRÍTICA (SEMANA 1)

#### ✅ Task 1.1: Credenciales en Memory
**Archivo**: `lib/src/features/authentication/presentation/login_screen.dart`

```dart
// ANTES (❌ Inseguro)
@override
void dispose() {
  _passwordController.dispose();
  super.dispose();
}

// DESPUÉS (✅ Seguro)
@override
void dispose() {
  _passwordController.clear(); // Limpiar datos
  _emailController.clear();
  _passwordController.dispose();
  _emailController.dispose();
  super.dispose();
}
```

**Archivos**:
- [ ] `lib/src/features/authentication/presentation/login_screen.dart`
- [ ] `lib/src/features/authentication/presentation/register_screen.dart`

**Estimado**: 30 min

#### ✅ Task 1.2: Agregar flutter_secure_storage
**Archivo**: `pubspec.yaml`

```yaml
dependencies:
  flutter_secure_storage: ^9.0.0
```

**Crear archivo**: `lib/src/core/services/secure_storage_service.dart`
```dart
class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  Future<void> saveBodyMetrics({
    required String userId,
    required double bodyFatPercentage,
    required double waistCircumference,
  }) async {
    await _storage.write(
      key: 'bodyFat_$userId',
      value: bodyFatPercentage.toString(),
    );
    // ... más datos
  }
  
  Future<double?> getBodyFatPercentage(String userId) async {
    final value = await _storage.read(key: 'bodyFat_$userId');
    return value != null ? double.tryParse(value) : null;
  }
}
```

**Archivos**:
- [ ] Actualizar `pubspec.yaml`
- [ ] Crear `lib/src/core/services/secure_storage_service.dart`
- [ ] Actualizar repositorios para usar SecureStorageService

**Estimado**: 2 horas

#### ✅ Task 1.3: Remover ReCaptcha Hardcodeado
**Archivo**: `lib/main.dart` línea 68

```dart
// ANTES (❌ Expuesto)
providerWeb: ReCaptchaV3Provider(
  '6Lcw_YcpAAAAAZ6Z4G4G4G4G4G4G4G4G4G4G4G4G',
),

// DESPUÉS (✅ Desde Firebase Console)
// Configurar en Firebase Console y dejar que Firebase maneje
// O usar environment variables
```

**Acción**: 
- Ir a Firebase Console > reCAPTCHA
- Activar reCAPTCHA v3 para Web
- Firebase lo inyecta automáticamente

**Estimado**: 30 min

#### ✅ Task 1.4: Cleanup Print Statements
**Archivos**:
- [ ] `lib/main.dart`
- [ ] `lib/test_food_seeder.dart`
- [ ] `lib/src/features/onboarding/presentation/onboarding_screen.dart`

```dart
// ANTES (❌ Expuesto en prod)
print('Debug info');

// DESPUÉS (✅ Solo en debug)
if (kDebugMode) {
  debugPrint('Debug info');
}
```

**Estimado**: 1 hora

#### ✅ Task 1.5: Agregar Permission Handler
**Archivo**: `pubspec.yaml`

```yaml
dependencies:
  permission_handler: ^11.4.0
```

**Crear**: `lib/src/core/services/permissions_service.dart`
```dart
class PermissionsService {
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }
  
  Future<bool> requestGalleryPermission() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }
}
```

**Archivos a actualizar**:
- [ ] `pubspec.yaml`
- [ ] Crear `lib/src/core/services/permissions_service.dart`
- [ ] `android/app/src/main/AndroidManifest.xml` - agregar permisos
- [ ] `ios/Runner/Info.plist` - agregar descripciones

**Estimado**: 2 horas

**TOTAL FASE 1**: 6 horas aprox.

---

### FASE 2: ARQUITECTURA & REFACTOR (SEMANA 2)

#### ✅ Task 2.1: Crear FoodRepository Completo
**Crear**: `lib/src/features/nutrition/data/repositories/food_repository_impl.dart`

```dart
class FoodRepositoryImpl implements FoodRepository {
  final FirebaseFirestore _firestore;
  
  Future<List<FoodModel>> getFoodsByCategory(String category) async {
    try {
      final query = await _firestore
          .collection('master_food_db')
          .where('metadata.category', isEqualTo: category)
          .get();
      
      return query.docs
          .map((doc) => FoodModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
      rethrow;
    }
  }
  
  Future<List<FoodModel>> searchFoods(String query) async {
    try {
      // Implementar búsqueda eficiente
      final lowerQuery = query.toLowerCase();
      final result = await _firestore
          .collection('master_food_db')
          .where('nameLowercase', isGreaterThanOrEqualTo: lowerQuery)
          .where('nameLowercase', isLessThanOrEqualTo: '$lowerQuery\uf8ff')
          .get();
      
      return result.docs
          .map((doc) => FoodModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
      rethrow;
    }
  }
}
```

**Archivos**:
- [ ] Actualizar `lib/src/features/nutrition/domain/repositories/food_repository.dart` (interfaz)
- [ ] Crear `lib/src/features/nutrition/data/repositories/food_repository_impl.dart`

**Estimado**: 2 horas

#### ✅ Task 2.2: Refactor onboarding_screen.dart
**Archivo**: `lib/src/features/onboarding/presentation/onboarding_screen.dart`

```dart
// ANTES (❌ Queries en presentation)
final proteinsData = await _firestore
    .collection('master_food_db')
    .where('metadata.category', isEqualTo: 'Proteinas')
    .get();

// DESPUÉS (✅ Usar repository)
final proteinsData = await _foodRepository.getFoodsByCategory('Proteinas');
```

**Pasos**:
1. Inyectar FoodRepository en widget
2. Reemplazar todas las queries directas
3. Usar nuevo método genérico

**Estimado**: 2 horas

#### ✅ Task 2.3: Crear Service Locator
**Crear**: `lib/src/core/di/service_locator.dart`

```dart
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  // Firebase
  getIt.registerSingleton(FirebaseFirestore.instance);
  getIt.registerSingleton(FirebaseAuth.instance);
  
  // Services
  getIt.registerSingleton(SecureStorageService());
  getIt.registerSingleton(PermissionsService());
  
  // Repositories
  getIt.registerSingleton<FoodRepository>(
    FoodRepositoryImpl(getIt<FirebaseFirestore>()),
  );
}
```

**Archivos**:
- [ ] `pubspec.yaml` - agregar `get_it: ^7.5.0`
- [ ] Crear `lib/src/core/di/service_locator.dart`
- [ ] Actualizar `lib/main.dart` - llamar `setupServiceLocator()`

**Estimado**: 1.5 horas

#### ✅ Task 2.4: Eliminar Archivos Duplicados
```bash
# Archivos a eliminar
rm lib/src/features/training/domain/entities/training_entities.freezed\ 2.dart
rm lib/src/features/training/domain/entities/interactive_routine.freezed\ 2.dart

# Regenerar
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

**Estimado**: 1 hora

#### ✅ Task 2.5: Standardizar Riverpod Providers
**Audit**: Revisar todos los providers y standardizar

```dart
// Patrón a usar:
@riverpod
Future<List<FoodModel>> foodsByCategory(
  FoodsByCategoryRef ref,
  String category,
) async {
  final repository = ref.watch(foodRepositoryProvider);
  return repository.getFoodsByCategory(category);
}
```

**Estimado**: 2 horas

**TOTAL FASE 2**: 8.5 horas aprox.

---

### FASE 3: TESTING & VALIDACIÓN (SEMANA 3)

#### ✅ Task 3.1: Crear Validadores
**Crear**: `lib/src/core/utils/validators.dart`

```dart
class FormValidators {
  static String? validateEmail(String? value) {
    if (value?.isEmpty ?? true) return 'Email requerido';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!)) {
      return 'Email inválido';
    }
    return null;
  }
  
  static String? validatePassword(String? value) {
    if (value?.isEmpty ?? true) return 'Contraseña requerida';
    if (value!.length < 8) return 'Mínimo 8 caracteres';
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Debe contener mayúscula';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Debe contener número';
    }
    return null;
  }
  
  static String? validateBodyFat(String? value) {
    if (value?.isEmpty ?? true) return 'Porcentaje requerido';
    final num = double.tryParse(value!);
    if (num == null) return 'Número inválido';
    if (num < 5 || num > 60) return 'Rango: 5-60%';
    return null;
  }
}
```

**Archivos**:
- [ ] Crear `lib/src/core/utils/validators.dart`
- [ ] Actualizar todos los formularios para usar validadores

**Estimado**: 2 horas

#### ✅ Task 3.2: Implementar Crashlytics
**Archivo**: `pubspec.yaml`

```yaml
firebase_crashlytics: ^7.0.0
firebase_analytics: ^11.0.0
```

**Actualizar**: `lib/main.dart`

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Activar Crashlytics
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
    !kDebugMode,
  );
  
  // Usar como error handler
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack);
    return true;
  };
}
```

**Estimado**: 1.5 horas

#### ✅ Task 3.3: Agregar Conectividad
**Archivo**: `pubspec.yaml`

```yaml
connectivity_plus: ^5.0.0
```

**Crear**: `lib/src/core/providers/connectivity_provider.dart`

```dart
@riverpod
Stream<ConnectivityResult> connectivityStatus(
  ConnectivityStatusRef ref,
) {
  return Connectivity().onConnectivityChanged;
}
```

**Estimado**: 1.5 horas

#### ✅ Task 3.4: Ejecutar Tests
```bash
flutter test --coverage

# Generar reporte
coverage run --function-coverage --branch-coverage -o coverage/coverage.json test/
```

**Target**: > 70% coverage

**Archivos a testear**:
- [ ] `lib/src/features/nutrition/domain/services/recommendation_engine.dart`
- [ ] `lib/src/core/utils/validators.dart`
- [ ] `lib/src/features/nutrition/data/repositories/food_repository_impl.dart`

**Estimado**: 3 horas

**TOTAL FASE 3**: 8 horas aprox.

---

### FASE 4: COMPLIANCE (SEMANA 4)

#### ✅ Task 4.1: Privacy Policy
**Crear**: `PRIVACY_POLICY.md`

```markdown
# Política de Privacidad - ElenaApp

## 1. Información que Recopilamos
- Datos biométricos (edad, peso, porcentaje de grasa corporal)
- Datos de salud (patologías, historial)
- Datos de actividad (entrenamientos, ayunos)
- Datos de ubicación (opcional)

## 2. Cómo Usamos la Información
- Personalizar recomendaciones
- Mejorar el algoritmo
- Cumplimiento legal

## 3. Seguridad de Datos
- Encriptación en tránsito (HTTPS)
- Encriptación en reposo (AES-256)
- Firebase Firestore con autenticación

## 4. Retención de Datos
- Datos retenidos mientras la cuenta esté activa
- Eliminación a solicitud del usuario
- 90 días después de cierre de cuenta

## 5. HIPAA/GDPR Compliance
[Detalles específicos según jurisdicción]
```

**Estimado**: 2 horas

#### ✅ Task 4.2: Terms of Service
**Crear**: `TERMS_OF_SERVICE.md`

```markdown
# Términos de Servicio - ElenaApp

## 1. Aceptación de Términos
Al usar ElenaApp, aceptas estos términos.

## 2. Disclaimer Médico
ElenaApp NO es un sustituto de asesoramiento médico profesional.
Siempre consulta con un profesional de salud antes de cambiar tu régimen.

## 3. Limitación de Responsabilidad
[Términos legales estándar]

## 4. Propiedad Intelectual
[IP Protection]

## 5. Cambios a los Términos
Nos reservamos el derecho de modificar estos términos.
```

**Estimado**: 1.5 horas

#### ✅ Task 4.3: HealthKit Setup (iOS)
**Archivo**: `ios/Runner/Info.plist`

```xml
<key>NSHealthShareUsageDescription</key>
<string>Usamos datos de HealthKit para personalizar tus recomendaciones de salud.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>Usamos HealthKit para registrar tu actividad y progreso.</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>Usamos tu ubicación para personalizar recomendaciones de ejercicio.</string>
```

**Estimado**: 1 hora

#### ✅ Task 4.4: Health Connect Setup (Android)
**Archivo**: `android/app/src/main/AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.HEALTH_CONNECT_READ" />
<uses-permission android:name="android.permission.HEALTH_CONNECT_WRITE" />

<!-- Queries needed for Health Connect -->
<queries>
  <intent>
    <action android:name="android.intent.action.HEALTH_CONNECT" />
  </intent>
</queries>
```

**Estimado**: 1 hora

#### ✅ Task 4.5: Firestore Rules Audit
**Archivo**: `firestore.rules`

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{uid} {
      allow read, write: if request.auth.uid == uid;
      
      // Nested collections
      match /nutrition/{document=**} {
        allow read, write: if request.auth.uid == uid;
      }
      
      match /training/{document=**} {
        allow read, write: if request.auth.uid == uid;
      }
    }
    
    // Public read-only food database
    match /master_food_db/{document=**} {
      allow read: if true;
      allow write: if request.auth.uid in ["admin_uid_1", "admin_uid_2"];
    }
  }
}
```

**Estimado**: 1.5 horas

**TOTAL FASE 4**: 7.5 horas aprox.

---

### FASE 5: BUILD & RELEASE (SEMANA 5)

#### ✅ Task 5.1: Android Release Build

```bash
# 1. Generar keystore (si no existe)
keytool -genkey -v -keystore ~/key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias elena_app

# 2. Crear android/key.properties
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=elena_app
storeFile=/path/to/key.jks

# 3. Build
flutter build appbundle --release

# 4. Test en device
flutter install --release
```

**Estimado**: 1 hora (incluye testing)

#### ✅ Task 5.2: iOS Release Build

```bash
# 1. Verificar certificados en Xcode
open ios/Runner.xcworkspace

# 2. Build
flutter build ios --release

# 3. Archive en Xcode
# Abrir ios/Runner.xcworkspace
# Product > Archive

# 4. Upload to TestFlight
```

**Estimado**: 2 horas (incluye certificados)

#### ✅ Task 5.3: Store Submissions
**Google Play Store**:
- [ ] Crear app en Google Play Console
- [ ] Subir APK/AAB
- [ ] Completar store listing
- [ ] Enviar a revisión

**App Store**:
- [ ] Crear app en App Store Connect
- [ ] Subir build desde TestFlight
- [ ] Completar app review information
- [ ] Enviar a revisión

**Estimado**: 2 horas

**TOTAL FASE 5**: 5 horas aprox.

---

## 🎯 MÉTRICAS POR ENTREGABLE

### Semana 1 Deliverables
- ✅ Todas las credenciales limpias
- ✅ 0 print statements en prod
- ✅ flutter_secure_storage integrado
- ✅ permission_handler funcionando
- **Commit**: `feat(security): implement production-ready security hardening`

### Semana 2 Deliverables
- ✅ FoodRepository completo
- ✅ Queries Firestore en data layer
- ✅ Service Locator implementado
- ✅ Archivos duplicados eliminados
- **Commit**: `refactor(architecture): move to clean architecture patterns`

### Semana 3 Deliverables
- ✅ Validadores en todos los formularios
- ✅ Crashlytics implementado
- ✅ Conectividad checks
- ✅ > 70% test coverage
- **Commit**: `test(validation): comprehensive error handling and testing`

### Semana 4 Deliverables
- ✅ Privacy Policy publicada
- ✅ Terms of Service publicados
- ✅ HealthKit/Health Connect configurado
- ✅ Firestore Rules auditadas
- **Commit**: `docs(compliance): legal documents and app store compliance`

### Semana 5 Deliverables
- ✅ Android release build testeado
- ✅ iOS release build testeado
- ✅ Ambas apps en stores
- **Tag**: `v1.0.0-release`

---

## 💰 ESTIMACIONES

| Fase | Horas | Días (8h/día) | Recursos |
|------|-------|---------------|----------|
| Fase 1 - Seguridad | 6 | 1 | 1 Dev |
| Fase 2 - Arquitectura | 8.5 | 1.1 | 1 Dev |
| Fase 3 - Testing | 8 | 1 | 1 Dev |
| Fase 4 - Compliance | 7.5 | 0.9 | 1 Dev + 0.5 Legal |
| Fase 5 - Release | 5 | 0.6 | 1 Dev |
| **TOTAL** | **35** | **4.6 días** | 1 Dev |

**Calendario**:
- Semana 1: Lunes-Martes (Fase 1)
- Semana 2: Miércoles-Jueves (Fase 2)
- Semana 3: Viernes-Lunes (Fase 3)
- Semana 4: Martes-Miércoles (Fase 4)
- Semana 5: Jueves-Viernes (Fase 5)

---

## 📊 MÉTRICAS DE CALIDAD

**Pre-Release Checklist**:
- [ ] 0 Critical issues
- [ ] 0 High issues
- [ ] flutter analyze: 0 errors, < 10 warnings
- [ ] flutter test: 100% pass rate, > 70% coverage
- [ ] No debugPrint() en code
- [ ] No print() en code
- [ ] Todos los TODOs resueltos
- [ ] Código revisado por 2 personas
- [ ] Testeo manual en device real
- [ ] Testeo de integración completado

---

## 🔐 Security Checklist Pre-Release

- [ ] Firebase App Check activado
- [ ] SSL/TLS para todas las conexiones
- [ ] Secrets no en el código (firebase_options solo)
- [ ] flutter_secure_storage para datos sensibles
- [ ] Credenciales limpias en memory
- [ ] No hardcoded API keys
- [ ] Firestore rules validadas
- [ ] Privacy Policy en sitio
- [ ] Terms of Service en sitio
- [ ] HIPAA/GDPR compliance verificada

---

## 📱 Store Readiness Checklist

### Google Play Store
- [ ] Privacy Policy URL completa
- [ ] Screenshots (mínimo 2, máximo 8)
- [ ] Descripción corta (50-80 caracteres)
- [ ] Descripción larga (80-4000 caracteres)
- [ ] Categoría: Health & Fitness
- [ ] Content rating completada
- [ ] Permisos justificados
- [ ] Versión mínima SDK: 21
- [ ] Target SDK: 34+
- [ ] Signed APK/AAB

### Apple App Store
- [ ] Privacy Policy URL completa
- [ ] Screenshots (2-5 por idioma)
- [ ] Descripción (30-170 caracteres)
- [ ] Notas de la versión
- [ ] Categoría: Health & Fitness
- [ ] Keywords (máximo 100 caracteres)
- [ ] Support URL
- [ ] Privacy/Data Section completada
- [ ] Certificados y provisioning profiles vigentes

---

## 🚀 GO LIVE CRITERIA

App está lista para publicación cuando:

1. ✅ Todas las correcciones de Fase 1 implementadas
2. ✅ Clean Architecture compliance (80%+)
3. ✅ Test coverage > 70%
4. ✅ 0 Critical/High security issues
5. ✅ Documentación legal completada
6. ✅ Testeo en device real completado
7. ✅ Code review aprobado
8. ✅ Compliance checklist 100%

---

## 📞 CONTACTO & SOPORTE

**En caso de dudas**:
1. Revisar `AUDITORIA_PRODUCCION_COMPLETA.md` para detalles
2. Consultar commit messages de cada fase
3. Ejecutar automated checks: `flutter analyze && flutter test`

**Post-Release**:
- Monitorear Crashlytics diariamente primera semana
- Monitorear Analytics para UX issues
- Estar listo para responder a app store reviews

---

**Preparado por**: GitHub Copilot  
**Fecha**: 31 de marzo de 2026  
**Versión**: 1.0  
**Status**: READY FOR IMPLEMENTATION
