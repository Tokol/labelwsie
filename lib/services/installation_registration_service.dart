import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;

import 'backend_api_config.dart';

class InstallationRegistrationService {
  static const String _tokenKey = "client_token";

  static Future<void> ensureRegistered(Box box) async {
    final installationId = box.get("installation_id")?.toString().trim();
    final existingToken = box.get(_tokenKey)?.toString().trim();

    if (installationId == null || installationId.isEmpty) {
      return;
    }

    if (existingToken != null && existingToken.isNotEmpty) {
      return;
    }

    final response = await http.post(
      Uri.parse(BackendApiConfig.registerInstallationUrl),
      headers: const {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "installation_id": installationId,
        "platform": _platformLabel(),
        "app_version": "1.0.0",
      }),
    );

    if (response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      final clientToken = decoded["client_token"]?.toString().trim();
      if (clientToken != null && clientToken.isNotEmpty) {
        await box.put(_tokenKey, clientToken);
      }
      return;
    }

    throw Exception(
      "Installation registration failed (${response.statusCode}): ${response.body}",
    );
  }

  static String? clientToken(Box box) => box.get(_tokenKey)?.toString().trim();

  static String _platformLabel() {
    if (kIsWeb) return "web";
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return "android";
      case TargetPlatform.iOS:
        return "ios";
      case TargetPlatform.macOS:
        return "macos";
      case TargetPlatform.windows:
        return "windows";
      case TargetPlatform.linux:
        return "linux";
      case TargetPlatform.fuchsia:
        return "fuchsia";
    }
  }
}
