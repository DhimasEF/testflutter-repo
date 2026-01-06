import 'package:flutter/material.dart';
import '../widgets/creator_drawer.dart';
import '../widgets/creator_appbar.dart';

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
  // final Future<void> Function(int) uploadAvatarMobile;

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
    // required this.uploadAvatarMobile,
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
  // bool isFavorited = false;
  // int totalFavorite = 0;
  // bool isFavoriteLoading = false;
  int totalComment = 0;
  final TextEditingController commentCtrl = TextEditingController();
  List comments = [];
  int currentUserId = 0;
  late Map<String, dynamic> kontenState;
  bool hasChanged = false;

  @override
  void initState() {
    super.initState();
    kontenState = Map<String, dynamic>.from(widget.konten);

    // isFavorited = kontenState['is_favorited'] == true;
    // totalFavorite = kontenState['total_favorite'] ?? 0;

    // isFavoriteLoading = false;
    comments = [];
    totalComment = kontenState['total_comment'] ?? 0;;

    loadUserData();
    loadComments();
  }

  bool canDeleteComment(Map c) {
    return c['id_user'] == currentUserId ||
        role == 'admin' ||
        kontenState['id_user'] == currentUserId;
  }

  Future<void> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';
    int userId = prefs.getInt('id_user') ?? 0;
    role = prefs.getString('role') ?? '';
    currentUserId = userId;

    if (role != 'creator') {
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

  Future<void> loadComments() async {
    try {
      final res = await ApiService.getComments(kontenState['id_artwork']);
      setState(() {
        comments = res['data']['comments'] ?? [];
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  // Future<void> toggleFavorite() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   final token = prefs.getString('token') ?? '';

  //   try {
  //     final res = await ApiService.toggleFavorite(
  //       token,
  //       widget.konten['id_artwork'],
  //     );

  //     setState(() {
  //       isFavorited = res['favorited'] == true;
  //       totalFavorite = res['total_favorite'] ?? totalFavorite;
  //     });
  //   } catch (_) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("Gagal toggle favorite")),
  //     );
  //   }
  // }


  Future<void> deleteComment(int idComment, int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      await ApiService.deleteComment(token, idComment);
      setState(() {
        comments.removeAt(index);
        totalComment -= 1;
        kontenState['total_comment'] = totalComment;
        hasChanged = true; // 🔥 WAJIB
      });

    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal menghapus komentar")),
      );
    }
  }

  Future<void> submitComment() async {
    final text = commentCtrl.text.trim();
    if (text.isEmpty) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      await ApiService.addComment(
        token,
        kontenState['id_artwork'],
        text,
      );

      setState(() {
        totalComment += 1;
        kontenState['total_comment'] = totalComment;
        hasChanged = true; // 🔥 WAJIB
        commentCtrl.clear();
      });


      loadComments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal mengirim komentar")),
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
              // "http://10.0.2.2:3000/uploads/artworks/preview/${e['preview_url']}")
              "http://192.168.6.16:3000/uploads/artworks/preview/${e['preview_url']}")
              // "https://murally-ultramicroscopical-mittie.ngrok-free.dev/uploads/artworks/preview/${e['preview_url']}")
              // "http://localhost:3000/uploads/artworks/preview/${e['preview_url']}")
              // "http://192.168.137.188:3000/artworks/preview/${e['preview_url']}")
          .toList();
    }

    // Convert tag list
    List tags = [];
    if (konten["tags"] is List) {
      tags = konten["tags"].map((e) => e['tag_name']).toList();
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, hasChanged);
        return false;
      },
      child: Scaffold(
        drawer: CreatorDrawer(
          currentMenu: widget.currentMenu,
          username: username,
          avatarUrl: avatarUrl,
          selectedIndex: widget.selectedIndex,
          onItemSelected: (_) {},
        ),

        appBar: CreatorAppBar(
          title: "Detail Konten",
          username: username,
          avatarUrl: avatarUrl,
          onProfileTap: () => showProfilePanel(
            context,
            avatarUrl: avatarUrl,
            data: data ?? {},
            reloadData: loadUserData,
            //uploadAvatarWeb: widget.uploadAvatarWeb,
            // uploadAvatarMobile: widget.uploadAvatarMobile,
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
                  onTap: () => Navigator.pop(context, hasChanged),
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

            Row(
              children: [
                // IconButton(
                //   onPressed: isFavoriteLoading ? null : toggleFavorite,
                //   icon: AnimatedScale(
                //     scale: isFavorited ? 1.2 : 1.0,
                //     duration: const Duration(milliseconds: 150),
                //     child: Icon(
                //       isFavorited ? Icons.favorite : Icons.favorite_border,
                //       color: isFavorited ? Colors.red : Colors.grey,
                //     ),
                //   ),
                // ),
                // Text("$totalFavorite"),
                const SizedBox(width: 20),
                const Icon(Icons.comment, size: 18),
                const SizedBox(width: 4),
                Text("$totalComment"),
              ],
            ),

            const SizedBox(height: 12),

            /// 🔥 COMMENT INPUT
          TextField(
            controller: commentCtrl,
            decoration: InputDecoration(
              hintText: "Tulis komentar...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send),
                onPressed: submitComment,
              ),
            ),
          ),

          const SizedBox(height: 20),
          /// 🔥 COMMENT LIST
          ListView.builder(
            itemCount: comments.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final c = comments[index];

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: c['avatar'] != null
                      ? NetworkImage(ApiService.avatarBaseUrl + c['avatar'])
                      : null,
                  child: c['avatar'] == null ? const Icon(Icons.person) : null,
                ),
                title: Text(c['username']),
                subtitle: Text(c['comment_text']),
                trailing: canDeleteComment(c)
                    ? IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            deleteComment(c['id_comment'], index),
                      )
                    : null,
              );
            },
          ),

          const SizedBox(height: 30),
          ],
        ),
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
