import 'dart:convert';
import 'package:http/http.dart' as http;

class MLClassifierService {
  static const String api = "http://192.168.17.116:5000/classify_text";

  static Future<double> classify(String text) async {
    final res = await http.post(
      Uri.parse(api),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"text": text}),
    );

    if (res.statusCode != 200) return 0.0;

    final data = jsonDecode(res.body);
    return (data["distress_prob"] as num).toDouble();
  }
}
