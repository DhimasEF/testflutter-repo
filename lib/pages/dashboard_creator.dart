import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'edit_profil_page.dart';
import 'login_page.dart';
import 'upload_konten_page.dart';
import 'creator_transaksi_page.dart';
import 'dart:html' as html;
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../widgets/creator_appbar.dart';
import '../widgets/creator_drawer.dart';


class CreatorDashboardPage extends StatefulWidget {
  const CreatorDashboardPage({super.key});

  @override
  _CreatorDashboardPageState createState() => _CreatorDashboardPageState();
}

class _CreatorDashboardPageState extends State<CreatorDashboardPage> {
  String username = '';
  String email = '';
  String role = '';
  String? avatarUrl;
  Map<String, dynamic> data = {};
  bool isLoading = true;

  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> reloadData() async {
    await loadUserData();      // panggil ulang function kamu sendiri
    setState(() {});           // refresh UI
  }

  Future<void> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';
    int userId = prefs.getInt('id_user') ?? 0;
    role = prefs.getString('role') ?? '';

    if (role != 'creator') {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => LoginPage()));
      return;
    }

    final result = await ApiService.getDashboardData(token, userId: userId);
    if (result['status'] == true && result['data'] != null) {
      setState(() {
        data = result['data'];
        username = data['username'] ?? '';
        email = data['email'] ?? '';
        avatarUrl = (data['avatar'] != null && data['avatar'] != "")
          ? ApiService.avatarBaseUrl + data['avatar']
          : null;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> uploadAvatarWeb(int userId) async {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();
    await input.onChange.first;

    if (input.files!.isEmpty) return;

    final file = input.files!.first;
    final reader = html.FileReader();
    reader.readAsDataUrl(file);
    await reader.onLoad.first;

    final base64Image = reader.result as String;

    final response = await http.post(
      Uri.parse('http://192.168.6.16:3000/profil/upload-avatar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id_user': userId,
        'avatar_base64': base64Image,
      }),
    );

    if (response.statusCode == 200) {
      final resData = jsonDecode(response.body);
      if (resData['status'] == true) {
        setState(() {
          avatarUrl = (resData['avatar'] != null && resData['avatar'] != "")
              ? ApiService.avatarBaseUrl + resData['avatar']
              : null;
        });

        await loadUserData();
      }
    }
  }

  // Slide Profile Panel
  void showProfilePanel(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierLabel: "Profil Creator",
      barrierDismissible: true,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              bottomLeft: Radius.circular(20),
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.75,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Profil Creator",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: avatarUrl != null
                            ? NetworkImage(avatarUrl!)
                            : const AssetImage('assets/default.jpg')
                                as ImageProvider,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: InkWell(
                          onTap: () async {
                            SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            int userId = prefs.getInt('id_user') ?? 0;
                            await uploadAvatarWeb(userId);
                            Navigator.pop(context);
                            loadUserData();
                          },
                          child: Container(
                            decoration: const BoxDecoration(
                                color: Colors.blue, shape: BoxShape.circle),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(Icons.edit,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(),
                  infoRow("Nama", data["name"]),
                  infoRow("Email", data["email"]),
                  infoRow("Username", data["username"]),
                  infoRow("Role", data["role"]),
                  infoRow("Bio", data["bio"]),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text("Edit Profil"),
                    onPressed: () async {
                      Navigator.pop(context);
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => EditProfilePage(userData: data)),
                      );
                      if (updated == true) loadUserData();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position:
              Tween(begin: const Offset(1, 0), end: const Offset(0, 0)).animate(anim1),
          child: child,
        );
      },
    );
  }

  Widget infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Flexible(
            child: Text(
              value != null ? value.toString() : "-",
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // MENU MANAGER — sesuai selectedIndex
  Widget getCurrentPage() {
    switch (selectedIndex) {
      case 0:
        return dashboardContent();
      case 1:
        return UploadKontenPage();
      case 2:
        return CreatorTransaksiPage();
      default:
        return Center(child: Text("Menu tidak ditemukan"));
    }
  }

  // Konten halaman dashboard
  Widget dashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl!)
                    : const AssetImage('assets/default.jpg')
                        as ImageProvider,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${data['name'] ?? username} 👋',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(email, style: TextStyle(color: Colors.grey[700])),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CreatorAppBar(
        title: "Dashboard Creator",
        username: username,
        avatarUrl: avatarUrl,
        onProfileTap: () => showProfilePanel(context),
      ),

      drawer: CreatorDrawer(
        username: username,
        avatarUrl: avatarUrl,
        selectedIndex: selectedIndex,
        currentMenu: "dashboard",
        onItemSelected: (i) {
          setState(() => selectedIndex = i);
          Navigator.pop(context); // tutup drawer
        },
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : getCurrentPage(),
    );
  }
}
