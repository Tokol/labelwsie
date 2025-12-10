import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenFoodFactsService {
  static const String _baseUrl = "https://world.openfoodfacts.org/api/v2";
  static const String _userAgent =
      "LabelWise/1.0 (lamasuresh9841955416@gmail.com)";

  /// Fetch product by barcode
  static Future<Map<String, dynamic>?> fetchProduct(String barcode) async {
    final url = "$_baseUrl/product/$barcode.json";

    try {
      final res = await http.get(
        Uri.parse(url),
        headers: {"User-Agent": _userAgent},
      );

      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body);

      if (json["status"] == 1) {
        return json["product"];
      }

      return null;
    } catch (e) {
      print("OFF API error: $e");
      return null;
    }
  }
}
