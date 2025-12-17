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
  final Future<void> Function(int)? uploadAvatarMobile;

  const KelolaKontenPage({
    super.key,
    this.username,
    this.avatarUrl,
    this.data,
    this.reloadData,
    //this.uploadAvatarWeb,
    this.uploadAvatarMobile,
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
          uploadAvatarMobile: widget.uploadAvatarMobile,
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
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filteredContents.length,
                          itemBuilder: (context, index) {
                            final item = filteredContents[index];

                            final title = item["title"] ?? "-";
                            final user = item["username"] ?? "-";

                            final images = item["images"] ?? [];
                            String? thumb;

                            if (images.isNotEmpty && images[0] is Map) {
                              thumb = images[0]["preview_url"];
                            }

                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: thumb != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(
                                          // "http://192.168.6.16:3000/uploads/artworks/preview/$thumb",
                                          // "https://murally-ultramicroscopical-mittie.ngrok-free.dev/uploads/artworks/preview/$thumb",
                                          "http://localhost:3000/uploads/artworks/preview/$thumb",
                                          width: 70,
                                          height: 70,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Container(
                                        width: 70,
                                        height: 70,
                                        color: Colors.grey.shade300,
                                        child: const Icon(Icons.image_not_supported),
                                      ),

                                title: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                subtitle: Text("By: $user"),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),

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
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
