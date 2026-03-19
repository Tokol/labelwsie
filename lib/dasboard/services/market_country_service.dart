import 'dart:convert';

import 'package:http/http.dart' as http;

class MarketCountryResolution {
  final String? country;
  final String source;

  const MarketCountryResolution({
    required this.country,
    required this.source,
  });
}

class MarketCountryService {
  MarketCountryService._();

  static Future<MarketCountryResolution> resolve({
    required Map<String, dynamic> product,
  }) async {
    try {
      final response = await http
          .get(Uri.parse("https://ipwho.is/"))
          .timeout(const Duration(milliseconds: 1200));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded["success"] == true) {
          final country = decoded["country"]?.toString().trim();
          if (country != null && country.isNotEmpty) {
            return MarketCountryResolution(
              country: country,
              source: "geoip",
            );
          }
        }
      }
    } catch (_) {
      // GeoIP is best-effort only.
    }

    final fallbackCountry = _extractProductCountry(product);
    return MarketCountryResolution(
      country: fallbackCountry,
      source:
          fallbackCountry == null ? "unavailable" : "product_origin_fallback",
    );
  }

  static String? _extractProductCountry(Map<String, dynamic> product) {
    final candidates = [
      product["countries"]?.toString(),
      product["origins"]?.toString(),
    ];

    for (final raw in candidates) {
      final parsed = _cleanCountryLabel(raw);
      if (parsed != null) return parsed;
    }

    return null;
  }

  static String? _cleanCountryLabel(String? raw) {
    if (raw == null) return null;

    final value = raw
        .split(",")
        .map((part) => part.trim())
        .firstWhere(
          (part) => part.isNotEmpty,
          orElse: () => "",
        )
        .replaceFirst(RegExp(r"^[a-z]{2}:"), "")
        .replaceAll("-", " ")
        .trim();

    if (value.isEmpty) return null;

    return value
        .split(RegExp(r"\s+"))
        .map((word) {
          if (word.isEmpty) return word;
          return "${word[0].toUpperCase()}${word.substring(1)}";
        })
        .join(" ");
  }
}
