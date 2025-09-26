import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ICloudBackupService {
  static const MethodChannel _channel = MethodChannel('com.online404.timer/icloud_backup');

  Future<void> saveBackup(Map<String, dynamic> payload) async {
    final data = jsonEncode(payload);
    if (kDebugMode) {
      print('🔒 iCloud backup: Tentative de sauvegarde, taille: ${data.length} caractères');
      print('🔒 iCloud backup: Payload version: ${payload['version']}');
    }

    try {
      await _channel.invokeMethod<void>('saveBackup', {'data': data});
      if (kDebugMode) {
        print('🔒 iCloud backup: Sauvegarde réussie');
      }
    } on MissingPluginException catch (e) {
      if (kDebugMode) {
        print('🔒 iCloud backup: Plugin manquant - $e');
      }
      throw PlatformException(
        code: 'unavailable',
        message: 'La sauvegarde iCloud n\'est pas disponible sur cette plateforme.',
      );
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('🔒 iCloud backup: Erreur de plateforme - ${e.code}: ${e.message}');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('🔒 iCloud backup: Erreur inattendue - $e');
      }
      throw PlatformException(
        code: 'unknown_error',
        message: 'Erreur inattendue lors de la sauvegarde: $e',
      );
    }
  }
}
