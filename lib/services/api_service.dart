import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:image_picker/image_picker.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:3000';
  // static const String baseUrl = 'http://192.168.6.16:3000';
  // static const String baseUrl = 'http://localhost:3000';
  // static const String baseUrl = 'http://192.168.137.42:3000';
  // static const String baseUrl = 'https://murally-ultramicroscopical-mittie.ngrok-free.dev';
  static const String baseUrlimage = 'http://10.0.2.2:3000';
  // static const String baseUrlimage = 'http://192.168.6.16:3000';
  // static const String baseUrlimage = 'http://localhost:3000';
  // static const String baseUrlimage = 'http://192.168.137.42:3000';
  // static const String baseUrlimage = 'https://murally-ultramicroscopical-mittie.ngrok-free.dev';
  static const String avatarBaseUrl = "${baseUrlimage}/uploads/avatar/";
  // ============================
  // LOGIN
  // ============================
  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    print(response.body);

    return jsonDecode(response.body);
  }

  // ============================
  // REGISTER
  // ============================
  static Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
  ) async {
    final url = Uri.parse('$baseUrl/auth/register');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    return jsonDecode(response.body);
  }

  // ============================
  // DASHBOARD
  // ============================
  static Future<Map<String, dynamic>> getDashboardData(
    String token, {
    int? userId,
  }) async {
    final url = userId != null
        ? '$baseUrl/profil/get/$userId'
        : '$baseUrl/api/user/data';

    final resp = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    return resp.statusCode == 200
        ? jsonDecode(resp.body)
        : {'status': false, 'message': 'Gagal ambil data'};
  }

  // ============================
  // GET ALL USERS
  // ============================
  static Future<dynamic> getAllUsers(String token) async {
    final url = Uri.parse("$baseUrl/user/list");

    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    return jsonDecode(response.body);
  }

  // ============================
  // RESET PASSWORD
  // ============================
  static Future<dynamic> resetPassword(String token, String idUser) async {
    final url = Uri.parse("$baseUrl/user/reset_password/$idUser");

    final response = await http.post(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    return jsonDecode(response.body);
  }

  // ============================
  // UPLOAD ARTWORK (FINAL)
  // ============================
  static Future<Map<String, dynamic>> uploadArtwork({
    required String token,
    required int userId,
    required String title,
    required String description,
    required String price,
    required List<String> tags,
    required List<XFile> images, // hanya satu list!
  }) async {
    final url = Uri.parse("$baseUrl/artwork/upload");

    final request = http.MultipartRequest("POST", url);
    request.headers["Authorization"] = "Bearer $token";

    request.fields["id_user"] = userId.toString();
    request.fields["title"] = title;
    request.fields["description"] = description;
    request.fields["price"] = price;
    request.fields["tags"] = jsonEncode(tags);

    // Upload semua gambar -> images[]
    for (var img in images) {
      final bytes = await img.readAsBytes();
      final mime = lookupMimeType(img.name)?.split('/') ?? ['image', 'jpeg'];

      request.files.add(
        http.MultipartFile.fromBytes(
          "images[]",
          bytes,
          filename: img.name,
          contentType: MediaType(mime[0], mime[1]),
        ),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    print("RESPON MENTAH DARI SERVER:");
    print(response.body);

    return jsonDecode(response.body);
  }

  // ============================
  // GET ALL DRAFT
  // ============================
  static Future<List<Map<String, dynamic>>> getDraftContents() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('$baseUrl/artwork/draft'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    print("Raw Response: ${response.body}"); // DEBUG

    if (response.statusCode != 200) {
      throw Exception("Failed: ${response.statusCode}");
    }

    dynamic json;
    try {
      json = jsonDecode(response.body);
    } catch (e) {
      throw Exception("Response bukan JSON valid");
    }

    // Jika API balas langsung list
    if (json is List) {
      return List<Map<String, dynamic>>.from(json);
    }

    // Jika API balas object tapi isinya list
    if (json is Map) {
      if (json.containsKey('data') && json['data'] is List) {
        return List<Map<String, dynamic>>.from(json['data']);
      }

      if (json.containsKey('artworks') && json['artworks'] is List) {
        return List<Map<String, dynamic>>.from(json['artworks']);
      }

      // Jika API balas objek kosong → return list kosong
      return [];
    }

    throw Exception("API tidak mengembalikan list");
  }

  static Future<List<Map<String, dynamic>>> getAllContentsAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('$baseUrl/artwork/all_admin'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    print("Raw Response: ${response.body}"); // DEBUG

    if (response.statusCode != 200) {
      throw Exception("Failed: ${response.statusCode}");
    }

    final json = jsonDecode(response.body);

    // =============== FIX PENTING ===============
    if (json is Map && json['data'] is List) {
      return List<Map<String, dynamic>>.from(json['data']);
    }

    return [];
  }


  // ============================
  // GET ALL ARTWORK (FINAL FIX)
  // ============================
  static Future<List<Map<String, dynamic>>> getAllArtwork() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('$baseUrl/artwork/all'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    print("Raw Response: ${response.body}"); // DEBUG

    if (response.statusCode != 200) {
      throw Exception("Failed: ${response.statusCode}");
    }

    dynamic json;
    try {
      json = jsonDecode(response.body);
    } catch (e) {
      throw Exception("Response bukan JSON valid");
    }

    // Jika API balas langsung list
    if (json is List) {
      return List<Map<String, dynamic>>.from(json);
    }

    // Jika API balas object tapi isinya list
    if (json is Map) {
      if (json.containsKey('data') && json['data'] is List) {
        return List<Map<String, dynamic>>.from(json['data']);
      }

      if (json.containsKey('artworks') && json['artworks'] is List) {
        return List<Map<String, dynamic>>.from(json['artworks']);
      }

      // Jika API balas objek kosong → return list kosong
      return [];
    }

    throw Exception("API tidak mengembalikan list");
  }

  // ============================
  // GET MY ARTWORK
  // ============================
  static Future<List<dynamic>> getMyArtwork(int idUser) async {
    final url = Uri.parse("$baseUrl/artwork/my/$idUser");
    final response = await http.get(url);

    dynamic json = jsonDecode(response.body);

    if (json is List) return json;
    if (json is Map && json.containsKey('data')) return json['data'];

    return [];
  }

  static Future<Map<String, dynamic>> getUploaderProfile(int userId) async {
    final url = Uri.parse("${baseUrl}/user/uplofile/$userId");

    final response = await http.get(url);
    return jsonDecode(response.body);
  }

  // ============================
  // Update Status
  // ============================
  static Future<Map<String, dynamic>> updateArtworkStatus({
    required String token,
    required int idArtwork,
    required String status,
  }) async {
    final url = Uri.parse("$baseUrl/artwork/updateStatus");

    final response = await http.post(
      url,
      body: {
        "id_artwork": idArtwork.toString(),
        "status": status,
      },
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    return jsonDecode(response.body);
  }

  static Future<dynamic> createOrder(String token, Map<String, dynamic> data) async {
    final url = Uri.parse("$baseUrl/order/create");

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(data),
    );

    print(response.body);
    return jsonDecode(response.body);
  }

  static Future<List<Map<String, dynamic>>> getMyOrders(int idBuyer) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('$baseUrl/order/my-buyer?id_buyer=$idBuyer'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    print("Raw Response My Orders: ${response.body}"); // debug

    if (response.statusCode != 200) {
      throw Exception("Failed: ${response.statusCode}");
    }

    dynamic json;
    try {
      json = jsonDecode(response.body);
    } catch (e) {
      throw Exception("Response bukan JSON valid");
    }

    if (json is List) {
      return List<Map<String, dynamic>>.from(json);
    }

    if (json is Map) {
      if (json.containsKey('data') && json['data'] is List) {
        return List<Map<String, dynamic>>.from(json['data']);
      }
      return [];
    }

    throw Exception("API tidak mengembalikan list");
  }
  // ApiService.dart
  static Future<Map<String, dynamic>> getCreatorOrders(int idCreator) async {
    final url = Uri.parse("$baseUrl/order/my-creator?id_creator=$idCreator");

    final response = await http.get(url);
    return jsonDecode(response.body);
  } 
  // ApiService.dart
  static Future<Map<String, dynamic>> getMyAllOrders(int idBuyer) async {
    final url = Uri.parse("$baseUrl/order/my-buyer?id_buyer=$idBuyer");

    final response = await http.get(url);
    return jsonDecode(response.body);
  } 

  static Future<Map<String, dynamic>> uploadPaymentProof({
    required int idOrder,
    required int amount,
    required XFile file,
  }) async {
    final uri = Uri.parse("$baseUrl/order/upload-payment");
    final request = http.MultipartRequest("POST", uri);

    // field text
    request.fields["id_order"] = idOrder.toString();
    request.fields["amount"] = amount.toString();

    // file (JANGAN PAKSA MIME)
    request.files.add(
      await http.MultipartFile.fromPath(
        "bukti", // HARUS SAMA DENGAN BACKEND
        file.path,
      ),
    );

    final res = await request.send();
    final body = await res.stream.bytesToString();

    // 🔥 WAJIB
    if (res.statusCode != 200) {
      throw Exception(
        "Upload payment gagal (${res.statusCode}): $body",
      );
    }

    return jsonDecode(body);
  }

  static Future<Map<String, dynamic>> acceptPayment(int idOrder) async {
  final res = await http.post(
    Uri.parse("$baseUrl/order/accept-payment"),
    body: {"id_order": idOrder.toString()},
  );
  return jsonDecode(res.body);
}

static Future<Map<String, dynamic>> rejectPayment(int idOrder) async {
  final res = await http.post(
    Uri.parse("$baseUrl/order/reject-payment"),
    body: {"id_order": idOrder.toString()},
  );
  return jsonDecode(res.body);
}

}
