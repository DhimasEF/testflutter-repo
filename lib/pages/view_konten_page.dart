import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/user_drawer.dart';
import '../widgets/user_appbar.dart';
import '../widgets/profile_panel.dart';
import '../services/api_service.dart';
import 'konten_detail_user_page.dart';
import 'edit_profil_page.dart';
import 'login_page.dart';

// ======================================
// HELPER
// ======================================
String capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1).toLowerCase();
}

// ======================================
// PAGE
// ======================================
class ViewKontenPage extends StatefulWidget {
  const ViewKontenPage({super.key});

  @override
  State<ViewKontenPage> createState() => _ViewKontenPageState();
}

class _ViewKontenPageState extends State<ViewKontenPage> {
  // User
  String username = "";
  String role = "";
  String? avatarUrl;
  Map<String, dynamic>? data;

  // Artwork
  List<dynamic> artwork = [];
  List<dynamic> filtered = [];
  List<dynamic> myOrders = [];
  bool loading = true;

  String filter = "all";
  String search = "";
  int selectedIndex = 1;

  bool _active = true; // <- tambahkan ini agar async stop jika dispose

  @override
  void initState() {
    super.initState();
    loadUserData();
    loadMyOrders().then((_) {
      if (!mounted) return;
      loadArtwork();
    });
  }

  @override
  void dispose() {
    _active = false;
    super.dispose();
  }

  // ======================================
  // LOAD MY ORDERS
  // ======================================
  Future<void> loadMyOrders() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int userId = prefs.getInt("id_user") ?? 0;

      final result = await ApiService.getMyOrders(userId);

      if (!_active || !mounted) return;

      if (result is List) {
        setState(() {
          myOrders = result;
          applyFilter();
        });
      }
    } catch (_) {}
  }

  // ======================================
  // LOAD USER DATA
  // ======================================
  Future<void> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String token = prefs.getString('token') ?? '';
    int userId = prefs.getInt('id_user') ?? 0;
    role = prefs.getString('role') ?? '';

    if (role != "user") {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
        );
      }
      return;
    }

    final result =
        await ApiService.getDashboardData(token, userId: userId);

    if (!_active || !mounted) return;

    if (result['status'] == true) {
      final d = result['data'] as Map<String, dynamic>;
      setState(() {
        data = d;
        username = d['username'] ?? '';
        avatarUrl = (d['avatar'] != null && d['avatar'] != "")
            ? ApiService.avatarBaseUrl + d['avatar']
            : null;
      });
    }
  }

  // ======================================
  // LOAD ARTWORK
  // ======================================
  Future<void> loadArtwork() async {
    if (!_active || !mounted) return;

    setState(() => loading = true);

    try {
      final data = await ApiService.getAllArtwork();

      if (!_active || !mounted) return;

      setState(() {
        artwork = data is List ? data : [];
        filtered = artwork;
        loading = false;
      });
    } catch (e) {
      if (!_active || !mounted) return;

      setState(() => loading = false);
    }
  }

  // ======================================
  // FILTER + SEARCH
  // ======================================
  void applyFilter() {
    if (!mounted) return;

    List<dynamic> result = artwork;

    if (filter == "available") {
      result = result.where((a) => a["status"] == "published").toList();
    } else if (filter == "sold") {
      result = result.where((a) => a["status"] == "sold").toList();
    } else if (filter == "my") {
      List<int> ids = myOrders.map((o) {
        return int.tryParse(o['id_artwork'].toString()) ?? -1;
      }).toList();
      result = result.where((a) => ids.contains(a['id_artwork'])).toList();
    }

    if (search.isNotEmpty) {
      result = result.where((a) {
        final title = (a["title"] ?? "").toString().toLowerCase();
        return title.contains(search.toLowerCase());
      }).toList();
    }

    if (!mounted) return;
    setState(() => filtered = result);
  }

  // ======================================
  // BUILD ITEM
  // ======================================
  Widget buildContentItem(Map item) {
    List<String> images = [];
    if (item["images"] is List) {
      images = (item["images"] as List)
          .map((e) =>
              "http://192.168.6.16:3000/uploads/artworks/preview/${e['preview_url']}")
          .toList();
    }

    String status = item['status'] ?? "draft";
    Color statusColor =
        status == "sold" ? Colors.orange : Colors.green;
    IconData statusIcon =
        status == "sold" ? Icons.shopping_bag : Icons.check_circle;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          Positioned.fill(
            child: images.isNotEmpty
                ? Image.network(images[0], fit: BoxFit.cover)
                : Container(color: Colors.grey.shade300),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["title"] ?? "(Tanpa judul)",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.image,
                            size: 14, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          images.length.toString(),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(statusIcon,
                              size: 11, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            capitalize(status),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize:8,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item["price"] != null
                      ? "Rp ${item['price']}"
                      : "Rp -",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (status != "sold")
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(Icons.shopping_cart,
                    size: 18, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  // ======================================
  // UI
  // ======================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UserAppBar(
        title: "Marketplace",
        username: username,
        avatarUrl: avatarUrl,
        onProfileTap: () => showProfilePanel(
          context,
          avatarUrl: avatarUrl,
          data: data ?? {},
          reloadData: loadUserData,
          //uploadAvatarWeb: null,
          uploadAvatarMobile: null,
          editPageBuilder: (d) => EditProfilePage(userData: d),
        ),
      ),
      drawer: UserDrawer(
        currentMenu: "marketplace",
        username: username,
        avatarUrl: avatarUrl,
        selectedIndex: selectedIndex,
        onItemSelected: (i) => setState(() => selectedIndex = i),
      ),
      body: Column(
        children: [
          // SEARCH
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Cari artwork...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) {
                search = v;
                applyFilter();
              },
            ),
          ),
          // FILTER BUTTONS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        filter = "all";
                        applyFilter();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: filter == "all" ? Colors.blue : Colors.grey[300],
                      foregroundColor: filter == "all" ? Colors.white : Colors.black,
                    ),
                    child: const Text("All"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        filter = "available";
                        applyFilter();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          filter == "available" ? Colors.green : Colors.grey[300],
                      foregroundColor:
                          filter == "available" ? Colors.white : Colors.black,
                    ),
                    child: const Text("Available"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        filter = "my";
                        applyFilter();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          filter == "my" ? Colors.orange : Colors.grey[300],
                      foregroundColor:
                          filter == "my" ? Colors.white : Colors.black,
                    ),
                    child: const Text("My Orders"),
                  ),
                ),
              ],
            ),
          ),
          // LIST
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(child: Text("Tidak ada konten ditemukan"))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.78,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemBuilder: (_, i) {
                          final item = filtered[i];
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
                      ),
          ),
        ],
      ),
    );
  }
}
