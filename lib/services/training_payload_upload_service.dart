import 'dart:convert';

import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;

import 'backend_api_config.dart';
import 'installation_registration_service.dart';

class TrainingPayloadUploadService {
  static Future<void> upload({
    required Box box,
    required Map<String, dynamic> payload,
  }) async {
    final installationId = box.get("installation_id")?.toString().trim();
    final clientToken = InstallationRegistrationService.clientToken(box);

    if (installationId == null || installationId.isEmpty) {
      throw Exception("Missing installation_id");
    }

    if (clientToken == null || clientToken.isEmpty) {
      throw Exception("Missing client token");
    }

    final response = await http.post(
      Uri.parse(BackendApiConfig.recordsUrl),
      headers: {
        "Content-Type": "application/json",
        "X-Installation-Id": installationId,
        "Authorization": "Bearer $clientToken",
      },
      body: jsonEncode({
        "payload": payload,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(
        "Training payload upload failed (${response.statusCode}): ${response.body}",
      );
    }
  }
}
