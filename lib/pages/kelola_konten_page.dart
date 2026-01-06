import 'package:flutter/material.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/admin_appbar.dart';
import '../widgets/profile_panel.dart';
import 'login_page.dart';
import 'edit_profil_page.dart';
import 'konten_detail_admin_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class KelolaKontenPage extends StatefulWidget {
  final String? username;
  final String? avatarUrl;
  final Map<String, dynamic>? data;
  final Future<void> Function()? reloadData;
  //final Future<void> Function(int)? uploadAvatarWeb;
  // final Future<void> Function(int) uploadAvatarMobile;

  const KelolaKontenPage({
    super.key,
    this.username,
    this.avatarUrl,
    this.data,
    this.reloadData,
    //this.uploadAvatarWeb,
    // required this.uploadAvatarMobile,
  });

  @override
  _KelolaKontenPageState createState() => _KelolaKontenPageState();
}

class _KelolaKontenPageState extends State<KelolaKontenPage> {
  String username = '';
  String email = '';
  String role = '';
  String? avatarUrl;
  Map<String, dynamic>? data;

  int selectedIndex = 1;

  List<dynamic> allContents = [];      
  List<dynamic> filteredContents = []; 
  bool isLoading = true;

  String selectedFilter = "All";
  String capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
    loadAllContents();
  }

  Future<void> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';
    int userId = prefs.getInt('id_user') ?? 0;
    role = prefs.getString('role') ?? '';

    if (!mounted) return;

    if (role != 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
      return;
    }

    final result = await ApiService.getDashboardData(token, userId: userId);

    if (!mounted) return;   // <-- WAJIB

    if (result['status'] == true && result['data'] != null) {
      final fetchedData = result['data'] as Map<String, dynamic>;

      if (!mounted) return; // <-- WAJIB

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

  Future<void> loadAllContents() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    final result = await ApiService.getAllContentsAdmin();

    if (!mounted) return; // <-- WAJIB

    allContents = result ?? [];
    applyFilter();
    
    if (!mounted) return; // <-- WAJIB
    setState(() => isLoading = false);
  }

  void applyFilter() {
    if (!mounted) return; // <-- WAJIB

    if (selectedFilter == "All") {
      filteredContents = allContents;
    } else {
      filteredContents = allContents.where((item) {
        return (item["status"] ?? "")
            .toLowerCase() == selectedFilter.toLowerCase();
      }).toList();
    }

    if (!mounted) return; // <-- WAJIB

    setState(() {});
  }

  Widget _buildStatusBadge(String status) {
    Color color;

    switch (status.toLowerCase()) {
      case "published":
        color = Colors.green;
        break;
      case "draft":
        color = Colors.orange;
        break;
      case "sold":
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFilterButton(String filter, IconData icon) {
    bool active = selectedFilter == filter;

    return InkWell(
      onTap: () {
        setState(() {
          selectedFilter = filter;
          applyFilter();
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: active ? Colors.blue.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? Colors.blue : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Icon(
          icon,
          size: 24,
          color: active ? Colors.blue : Colors.grey,
        ),
      ),
    );
  }

  Widget buildAdminContentItem(Map item) {
    List<String> images = [];

    if (item["images"] is List) {
      images = (item["images"] as List)
          .map((e) =>
              "http://192.168.6.16:3000/uploads/artworks/preview/${e['preview_url']}")
          .toList();
    }

    String status = (item['status'] ?? 'draft').toLowerCase();

    Color statusColor = {
      "published": Colors.green,
      "draft": Colors.grey,
      "rejected": Colors.red,
      "sold": Colors.orange,
    }[status] ?? Colors.grey;

    IconData statusIcon = {
      "published": Icons.check_circle,
      "draft": Icons.pending,
      "rejected": Icons.close,
      "sold": Icons.shopping_bag,
    }[status] ?? Icons.help;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          // IMAGE
          Positioned.fill(
            child: images.isNotEmpty
                ? Image.network(images[0], fit: BoxFit.cover)
                : Container(color: Colors.grey.shade300),
          ),

          // GRADIENT
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // CONTENT
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
                            color: Colors.white70,
                            fontSize: 11,
                          ),
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
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
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

                Row(
                  children: [
                    const Icon(Icons.comment,
                        size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      "${item['total_comment'] ?? 0}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ADMIN ICON
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.admin_panel_settings,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdminAppBar(
        title: "Kelola Konten",
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

      drawer: AdminDrawer(
        currentMenu: 'konten',
        username: username,
        avatarUrl: avatarUrl,
        selectedIndex: selectedIndex,
        onItemSelected: (i) {
          setState(() => selectedIndex = i);
        },
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ===============================
                // FILTER ICON MINIMALIS
                // ===============================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildFilterButton("All", Icons.grid_view),
                      _buildFilterButton("draft", Icons.edit_note),
                      _buildFilterButton("published", Icons.public),
                      _buildFilterButton("sold", Icons.shopping_bag),
                    ],
                  ),
                ),


                Expanded(
                  child: filteredContents.isEmpty
                      ? const Center(child: Text("Tidak ada konten."))
                      : LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = 2;

                          if (constraints.maxWidth > 1400) {
                            crossAxisCount = 5;
                          } else if (constraints.maxWidth > 1100) {
                            crossAxisCount = 4;
                          } else if (constraints.maxWidth > 800) {
                            crossAxisCount = 3;
                          }

                          return GridView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredContents.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.78,
                            ),
                            itemBuilder: (_, i) {
                              final item = filteredContents[i];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => KontenDetailPage(
                                        konten: item,
                                        username: username,
                                        avatarUrl: avatarUrl,
                                        selectedIndex: 1,
                                        currentMenu: "konten",
                                      ),
                                    ),
                                  ).then((changed) {
                                    if (changed == true) {
                                      loadAllContents(); // 🔥 RELOAD API
                                    }
                                  });
                                },
                                child: buildAdminContentItem(item),
                              );
                            },
                          );
                        },
                      ),
                ),
              ],
            ),
    );
  }
}
