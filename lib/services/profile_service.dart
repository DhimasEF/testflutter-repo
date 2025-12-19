import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class ProfileService {
  static Future<String?> uploadAvatar(int userId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null) return null;

    final file = result.files.single;
    final base64Image = base64Encode(file.bytes!);

    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/profil/upload-avatar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id_user': userId,
        'avatar_base64': 'data:image/png;base64,$base64Image',
      }),
    );

    if (response.statusCode != 200) return null;

    final resData = jsonDecode(response.body);
    if (resData['status'] != true) return null;

    return resData['avatar']; // ⬅️ return path avatar
  }
}
