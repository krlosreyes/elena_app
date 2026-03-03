import 'dart:io';

void main() {
  final dir = Directory('lib/src/features');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart') && !f.path.endsWith('.freezed.dart'));

  for (final file in files) {
    if (file.path.contains('auth_repository.dart') || file.path.contains('user_repository.dart') || file.path.contains('progress_service.dart') || file.path.contains('auth_controller.dart') || file.path.contains('user_controller.dart') || file.path.contains('progress_controller.dart') || file.path.contains('progress_controller.g.dart')) {
      continue;
    }

    String content = file.readAsStringSync();
    bool changed = false;

    // auth_repository -> auth_controller
    if (content.contains('authentication/data/auth_repository.dart')) {
      content = content.replaceAll('authentication/data/auth_repository.dart', 'authentication/application/auth_controller.dart');
      changed = true;
    }
    if (content.contains('authRepositoryProvider')) {
      content = content.replaceAll('authRepositoryProvider', 'authControllerProvider.notifier');
      changed = true;
    }

    // user_repository -> user_controller
    if (content.contains('profile/data/user_repository.dart')) {
      content = content.replaceAll('profile/data/user_repository.dart', 'profile/application/user_controller.dart');
      changed = true;
    }
    if (content.contains('userRepositoryProvider')) {
      content = content.replaceAll('userRepositoryProvider', 'userControllerProvider.notifier');
      changed = true;
    }

    // progress_service -> progress_controller
    if (content.contains('progress/data/progress_service.dart')) {
      // Be careful, some might import as package:elena_app/...
      content = content.replaceAll('progress/data/progress_service.dart', 'progress/application/progress_controller.dart');
      changed = true;
    }
    if (content.contains('progressServiceProvider')) {
      content = content.replaceAll('progressServiceProvider', 'progressControllerProvider.notifier');
      changed = true;
    }

    if (changed) {
      file.writeAsStringSync(content);
      print('Updated: \${file.path}');
    }
  }
}
