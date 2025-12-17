import 'package:flutter/material.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/admin_appbar.dart';

import '../widgets/profile_panel.dart';
import 'login_page.dart';
import 'edit_profil_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class KontenDetailPage extends StatefulWidget {
  final Map<String, dynamic> konten;
  final String currentMenu;
  final int selectedIndex;
  final String? username;
  final String? avatarUrl;
  final Map<String, dynamic>? data;
  final Future<void> Function()? reloadData;
  //final Future<void> Function(int)? uploadAvatarWeb;
  final Future<void> Function(int)? uploadAvatarMobile;

  const KontenDetailPage({
    super.key,
    required this.konten,
    required this.currentMenu,
    required this.selectedIndex,
    this.username,
    this.avatarUrl,
    this.data,
    this.reloadData,
    //this.uploadAvatarWeb,
    this.uploadAvatarMobile,
  });

  @override
  State<KontenDetailPage> createState() => _KontenDetailPage();
}

class _KontenDetailPage extends State<KontenDetailPage> {
  String username = '';
  String email = '';
  String role = '';
  String? avatarUrl;
  Map<String, dynamic>? data;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';
    int userId = prefs.getInt('id_user') ?? 0;
    role = prefs.getString('role') ?? '';

    if (role != 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
      return;
    }

    final result = await ApiService.getDashboardData(token, userId: userId);
    if (!mounted) return;

    if (result['status'] == true && result['data'] != null) {
      final fetchedData = result['data'] as Map<String, dynamic>;
      setState(() {
        data = fetchedData;
        username = fetchedData['username'] ?? '';
        avatarUrl = (fetchedData['avatar'] != null && fetchedData['avatar'] != "")
          ? ApiService.avatarBaseUrl + fetchedData['avatar']
          : null;
        email = fetchedData['email'] ?? '';
      });
    }
  }

  Future<void> updateStatus(String newStatus) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';

    int idArtwork = int.tryParse(widget.konten['id_artwork'].toString()) ?? 0;

    final result = await ApiService.updateArtworkStatus(
      token: token,
      idArtwork: idArtwork,
      status: newStatus,
    );

    if (!mounted) return;

    if (result['status'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Status berhasil diperbarui menjadi: $newStatus"),
          backgroundColor: Colors.green,
        ),
      );

      if (widget.reloadData != null) {
        await widget.reloadData!();
      }

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal mengubah status"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void showUploaderModal(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// Avatar
              CircleAvatar(
                radius: 40,
                backgroundImage: data['avatar'] != null
                    ? NetworkImage(ApiService.avatarBaseUrl + data['avatar'])
                    : null,
                child: data['avatar'] == null
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
              const SizedBox(height: 10),

              /// Username
              Text(
                data['username'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),

              /// Bio
              Text(
                data['bio'] ?? "-",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 10),

              /// Total post
              Text(
                "Total Post: ${data['total_post']}",
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tutup"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final konten = widget.konten;

    List<dynamic> images = [];
    if (konten["images"] is List) {
      images = konten["images"]
          .map((e) =>
              // "http://192.168.6.16:3000/uploads/artworks/preview/${e['preview_url']}")
              // "https://murally-ultramicroscopical-mittie.ngrok-free.dev/uploads/artworks/preview/${e['preview_url']}")
              // "http://localhost:3000/uploads/artworks/preview/${e['preview_url']}")
              "http://192.168.137.42:3000/uploads/artworks/preview/${e['preview_url']}")
          .toList();
    }

    // Convert tag list
    List tags = [];
    if (konten["tags"] is List) {
      tags = konten["tags"].map((e) => e['tag_name']).toList();
    }

    return Scaffold(
      drawer: AdminDrawer(
        currentMenu: widget.currentMenu,
        username: username,
        avatarUrl: avatarUrl,
        selectedIndex: widget.selectedIndex,
        onItemSelected: (_) {},
      ),

      appBar: AdminAppBar(
        title: "Detail Konten",
        username: username,
        avatarUrl: avatarUrl,
        onProfileTap: () => showProfilePanel(
          context,
          avatarUrl: avatarUrl,
          data: data ?? {},
          reloadData: loadUserData,
          //uploadAvatarWeb: widget.uploadAvatarWeb,
          uploadAvatarMobile: widget.uploadAvatarMobile,
          editPageBuilder: (d) => EditProfilePage(userData: d),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// 🔥 SECTION 1 – Title + Status Badge
          Row(
            children: [
              // 🔙 BACK BUTTON
              InkWell(
                onTap: () => Navigator.pop(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.arrow_back, size: 22),
                    SizedBox(width: 6),
                    Text(
                      "  ",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  konten['title'] ?? "Untitled Content",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: getStatusColor(konten['status']),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  konten['status'] ?? "unknown",
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          /// 🔥 SECTION 2 – Uploader Info
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: konten['avatar'] != null
                  ? NetworkImage(ApiService.avatarBaseUrl + konten['avatar'])
                  : null,
              child: konten['avatar'] == null
                  ? const Icon(Icons.person)
                  : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Uploader: ${konten['username'] ?? '-'}",
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text("Uploaded: ${konten['created_at'] ?? '-'}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  final int uploaderId = int.tryParse(
                    konten['id_user'].toString(),
                  ) ?? 0;

                  final result = await ApiService.getUploaderProfile(uploaderId);

                  if (result['success'] == true) {
                    showUploaderModal(context, result['data']);
                  }
                },
                child: const Text("Lihat Profil"),
              )
            ],
          ),

          const Divider(height: 30),

          /// 🔥 SECTION 3 – Description / Bio
          /// /// 🔥 SECTION 6 – Action Buttons
          Row(
            children: [
            /// KIRI: LABEL / TITLE
              Expanded(
                child: Text(
                  "Deskripsi / Bio",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

               /// KANAN: ACTION BUTTON (X / V)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    heroTag: "rejectBtn",
                    backgroundColor: Colors.red,
                    mini: true,
                    onPressed: () => updateStatus("rejected"),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                  FloatingActionButton(
                    heroTag: "accBtn",
                    backgroundColor: Colors.green,
                    mini: true,
                    onPressed: () => updateStatus("published"),
                    child: const Icon(Icons.check, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ],
          ),
          
          Text(
            konten['description'] ?? "-",
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),

          const SizedBox(height: 20),

          /// 🔥 SECTION 4 – Tags
          if (tags.isNotEmpty) ...[
            const Text("Tags",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              children: tags
                  .map((t) => Container(
                        margin: const EdgeInsets.only(right: 8, bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text("#$t"),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],

          /// 🔥 SECTION 5 – Images Gallery
          const Text("Gambar Konten",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: images.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemBuilder: (_, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  images[index],
                  fit: BoxFit.cover,
                ),
              );
            },
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Color getStatusColor(String? status) {
    switch (status) {
      case "pending":
        return Colors.orange;
      case "published":
        return Colors.green;
      case "rejected":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
