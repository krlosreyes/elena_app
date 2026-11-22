// SPEC-305 — abre el enlace de una fuente científica.
//
// En iOS usa SFSafariViewController (LaunchMode.inAppBrowserView): el
// usuario lee el estudio sin salir de Elena y vuelve con "Listo". Si eso
// falla (sin navegador in-app disponible), cae al navegador externo.
//
// `open` es reemplazable en tests para verificar QUÉ URL se abre sin
// depender del plugin nativo.

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

typedef SourceLinkHandler = Future<bool> Function(Uri uri);

abstract final class SourceLinkOpener {
  static Future<bool> _defaultOpen(Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      if (ok) return true;
    } catch (_) {
      // Sigue al navegador externo.
    }
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  static SourceLinkHandler _handler = _defaultOpen;

  static Future<bool> open(String url) => _handler(Uri.parse(url));

  @visibleForTesting
  static set handlerForTesting(SourceLinkHandler? handler) =>
      _handler = handler ?? _defaultOpen;
}
