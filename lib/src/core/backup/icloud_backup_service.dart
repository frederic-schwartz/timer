import 'dart:convert';

import 'package:flutter/services.dart';

class ICloudBackupService {
  static const MethodChannel _channel = MethodChannel('com.online404.timer/icloud_backup');

  Future<void> saveBackup(Map<String, dynamic> payload) async {
    final data = jsonEncode(payload);
    try {
      await _channel.invokeMethod<void>('saveBackup', {'data': data});
    } on MissingPluginException {
      throw PlatformException(
        code: 'unavailable',
        message: 'La sauvegarde iCloud n\'est pas disponible sur cette plateforme.',
      );
    }
  }
}
