// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class ApiClient {
//   static const String _baseUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-09-2025:generateContent";
//   static const String _apiKey = ""; // 运行时由环境提供

//   Future<String> postGemini(Map<String, dynamic> payload) async {
//     final response = await http.post(
//       Uri.parse("$_baseUrl?key=$_apiKey"),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode(payload),
//     );

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       return data['candidates'][0]['content']['parts'][0]['text'];
//     } else {
//       throw Exception('Failed to call AI API: ${response.body}');
//     }
//   }
// }