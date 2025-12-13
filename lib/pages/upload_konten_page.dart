import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/creator_drawer.dart';
import '../widgets/creator_appbar.dart';
import '../widgets/profile_panel.dart';
import '../widgets/upload_bottom_sheet.dart';
import 'edit_profil_page.dart';
import 'login_page.dart';
import '../services/api_service.dart';
import 'konten_detail_page.dart';


// ============================================================
//  IMAGE SLIDESHOW (FADE ANIMATION)
// ============================================================
class ImageSlideshow extends StatefulWidget {
  final List<String> images;

  const ImageSlideshow({super.key, required this.images});

  @override
  _ImageSlideshowState createState() => _ImageSlideshowState();
}

class _ImageSlideshowState extends State<ImageSlideshow> {
  int index = 0;

  @override
  void initState() {
    super.initState();

    if (widget.images.length > 1) {
      Future.doWhile(() async {
        await Future.delayed(const Duration(seconds: 3));

        if (!mounted) return false;

        setState(() => index = (index + 1) % widget.images.length);
        return true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),
      child: Image.network(
        widget.images[index],
        fit: BoxFit.cover,
        key: ValueKey(index),
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade300,
        ),
      ),
    );
  }
}

String capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1).toLowerCase();
}


// ============================================================
//  MAIN PAGE
// ============================================================
class UploadKontenPage extends StatefulWidget {
  final String? username;
  final String? avatarUrl;
  final Map<String, dynamic>? data;
  final Future<void> Function()? reloadData;
  final Future<void> Function(int)? uploadAvatarWeb;

  const UploadKontenPage({
    super.key,
    this.username,
    this.avatarUrl,
    this.data,
    this.reloadData,
    this.uploadAvatarWeb,
  });

  @override
  State<UploadKontenPage> createState() => _UploadKontenPageState();
}


// ============================================================
//  STATE
// ============================================================
class _UploadKontenPageState extends State<UploadKontenPage> {
  String username = "";
  String email = "";
  String role = "";
  String? avatarUrl;
  Map<String, dynamic>? data;

  int selectedIndex = 1;

  List<dynamic> allContent = [];
  List<dynamic> myContent = [];
  bool loading = true;

  String filter = "all";


  // ------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    loadUserData();
    loadContent();
  }


  // ------------------------------------------------------------
  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final userId = prefs.getInt('id_user') ?? 0;
    role = prefs.getString('role') ?? '';

    if (!mounted) return;

    if (role != 'creator') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
      return;
    }

    final result = await ApiService.getDashboardData(token, userId: userId);

    if (!mounted) return;

    if (result['status'] == true) {
      final d = result['data'] ?? {};
      setState(() {
        username = d['username'] ?? '';
        avatarUrl = (d['avatar'] != null && d['avatar'] != "")
          ? ApiService.avatarBaseUrl + d['avatar']
          : null;
        email = d['email'] ?? '';
        data = Map<String, dynamic>.from(d);
      });
    }
  }


  // ------------------------------------------------------------
  Future<void> loadContent() async {
    if (!mounted) return;
    setState(() => loading = true);

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('id_user') ?? 0;

    try {
      final listAll = await ApiService.getAllArtwork();
      final listMine = await ApiService.getMyArtwork(userId);

      if (!mounted) return;

      setState(() {
        allContent = (listAll is List) ? listAll : [];
        myContent = (listMine is List) ? listMine : [];
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
    }
  }


  // ------------------------------------------------------------
  void openUploadModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return UploadBottomSheet(
          onUploaded: () => loadContent(),
        );
      },
    );
  }



  // ============================================================
  //  CONTENT ITEM CARD — WITH DETAIL BUTTON
  // ============================================================
  Widget buildContentItem(Map item) {
    List<String> images = [];

    if (item["images"] != null && item["images"] is List) {
      images = (item["images"] as List)
          .map((e) =>
              "http://192.168.6.16:3000/uploads/artworks/preview/${e['preview_url']}")
          .toList();
    }

    String status = (item['status'] ?? 'draft').toString().toLowerCase();
    String price = item['price']?.toString() ?? "Rp -";

    // Warna badge berdasarkan status
    // Pilih warna
    Color statusColor = {
      "published": Colors.green,
      "draft": Colors.grey,
      "rejected": Colors.red,
      "sold": Colors.orange,
    }[status] ?? Colors.grey;

    // Pilih icon
    IconData statusIcon = {
      "published": Icons.check_circle,
      "draft": Icons.pending,
      "rejected": Icons.close,
      "sold": Icons.shopping_bag,
    }[status] ?? Icons.help;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: images.isNotEmpty
                ? Image.network(images[0], fit: BoxFit.cover)
                : Container(color: Colors.grey.shade300),
          ),

          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.70),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // ======= INFORMASI BAWAH =======
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Judul
                Text(
                  item["title"] ?? "(tanpa judul)",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 4),

                // ICON GAMBAR + STATUS BADGE
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // jumlah gambar
                    Row(
                      children: [
                        Icon(Icons.image, color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          images.length.toString(),
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    // Badge status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusIcon,
                            size: 11,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            capitalize(status),        // ← kapital huruf awal
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,   // ← italic
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),

                const SizedBox(height: 4),

                // HARGA
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item["price"] != null ? "Rp ${item['price']}" : "Rp -",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 255, 255, 255),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Icon open
          Positioned(
            right: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white24,
              ),
              child: const Icon(
                Icons.open_in_new,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ============================================================
  //  LIST VIEW
  // ============================================================
  Widget buildContentList() {
    final list = filter == "mine" ? myContent : allContent;

    if (loading) return const Center(child: CircularProgressIndicator());
    if (list.isEmpty) return const Center(child: Text("Belum ada konten"));

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,            // jumlah kolom
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.78,       // biar proporsional seperti card
      ),
      itemBuilder: (_, i) {
        final item = list[i];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => KontenDetailPage(
                  konten: item,
                  currentMenu: 'konten',
                  selectedIndex: selectedIndex,
                  username: username,
                  avatarUrl: avatarUrl,
                  data: data,
                  reloadData: loadUserData,
                ),
              ),
            );
          },
          child: buildContentItem(item),
        );
      },
    );
  }

  // ============================================================
  //  PAGE BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CreatorAppBar(
        title: "Kelola Konten",
        username: username,
        avatarUrl: avatarUrl,
        onProfileTap: () => showProfilePanel(
          context,
          avatarUrl: avatarUrl,
          data: data ?? {},
          reloadData: loadUserData,
          uploadAvatarWeb: widget.uploadAvatarWeb,
          editPageBuilder: (d) => EditProfilePage(userData: d),
        ),
      ),

      drawer: CreatorDrawer(
        currentMenu: 'konten',
        username: username,
        avatarUrl: avatarUrl,
        selectedIndex: selectedIndex,
        onItemSelected: (i) => setState(() => selectedIndex = i),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: openUploadModal,
        child: const Icon(Icons.add),
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FilterChip(
                  label: const Text("Semua Konten"),
                  selected: filter == "all",
                  onSelected: (_) => setState(() => filter = "all"),
                ),
                FilterChip(
                  label: const Text("Konten Saya"),
                  selected: filter == "mine",
                  onSelected: (_) => setState(() => filter = "mine"),
                ),
              ],
            ),
          ),
          Expanded(child: buildContentList()),
        ],
      ),
    );
  }
}
