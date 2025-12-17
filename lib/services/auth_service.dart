import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl =
      "https://chat-backend-2-q2i3.onrender.com";
      
  // ---------------- LOGIN ----------------
  static Future<Map<String, dynamic>?> login(
      String email, String password) async {
    final res = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return null;
  }

  // ---------------- REGISTER ----------------
 static Future<String?> register(
    String name, String email, String password) async {

  final res = await http.post(
    Uri.parse("$baseUrl/register"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "name": name,
      "email": email,
      "password": password,
    }),
  );

  if (res.statusCode == 201) return "success";

  if (res.statusCode == 409) {
    final msg = jsonDecode(res.body)["message"];
    if (msg == "Email already registered") return "email_exists";
    if (msg == "Name already taken") return "name_exists";
  }

  return null;
}


  // ---------------- USERS ----------------
  static Future<List<dynamic>> fetchUsers() async {
    final res = await http.get(Uri.parse("$baseUrl/users"));
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> searchUsers(String name) async {
    final res = await http.get(
      Uri.parse("$baseUrl/search?name=$name"),
    );
    return jsonDecode(res.body);
  }
}
