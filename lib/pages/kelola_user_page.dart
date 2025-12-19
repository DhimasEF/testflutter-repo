import 'package:flutter/material.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/admin_appbar.dart';
import '../widgets/profile_panel.dart';
import 'login_page.dart';
import 'edit_profil_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class KelolaUserPage extends StatefulWidget {
  final String? username;
  final String? avatarUrl;
  final Map<String, dynamic>? data;
  final Future<void> Function()? reloadData;
  //final Future<void> Function(int)? uploadAvatarWeb;
  // final Future<void> Function(int) uploadAvatarMobile;

  const KelolaUserPage({
    super.key,
    this.username,
    this.avatarUrl,
    this.data,
    this.reloadData,
    //this.uploadAvatarWeb,
    // required this.uploadAvatarMobile,
  });

  @override
  _KelolaUserPageState createState() => _KelolaUserPageState();
}

class _KelolaUserPageState extends State<KelolaUserPage>
    with SingleTickerProviderStateMixin {
  String username = '';
  String email = '';
  String role = '';
  String? avatarUrl;
  Map<String, dynamic>? data;

  List<dynamic> userList = [];
  bool isLoadingUsers = true;
  int selectedIndex = 2;

  // Animasi modal
  late AnimationController modalController;
  late Animation<double> opacityAnim;
  late Animation<Offset> slideAnim;

  @override
  void initState() {
    super.initState();
    loadUserData();
    loadAllUsers();

    modalController = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );

    opacityAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: modalController, curve: Curves.easeOut),
    );

    slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: modalController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    modalController.dispose();
    super.dispose();
  }

  Future<void> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';
    int userId = prefs.getInt('id_user') ?? 0;
    role = prefs.getString('role') ?? '';

    if (role != 'admin') {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
        );
      }
      return;
    }

    final result = await ApiService.getDashboardData(token, userId: userId);
    if (!mounted) return;

    if (result['status'] == true) {
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

  Future<void> loadAllUsers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';

    final result = await ApiService.getAllUsers(token);
    if (!mounted) return;

    if (result['status'] == true) {
      setState(() {
        userList = result['data'];
        isLoadingUsers = false;
      });
    }
  }

  Future<void> resetPassword(int idUser) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString("token") ?? "";

    final res = await ApiService.resetPassword(token, idUser.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(res["status"] ? "Password Baru" : "Gagal"),
        content: Text(
          res["status"]
              ? "Password baru:\n${res["new_password"]}"
              : res["message"],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  //──────────────────────────────
  // DETAIL MODAL
  //──────────────────────────────
  void openUserDetail(Map<String, dynamic> user) async {
    modalController.forward(from: 0);

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: FadeTransition(
            opacity: opacityAnim,
            child: SlideTransition(
              position: slideAnim,
              child: Material(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                color: Colors.white,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 500,
                    minHeight: 250,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),

                          Center(
                            child: CircleAvatar(
                              radius: 40,
                              backgroundImage:
                                  (user['avatar'] != null && user['avatar'] != "")
                                      ? NetworkImage(ApiService.avatarBaseUrl + user['avatar'])
                                      : null,
                              child: (user['avatar'] == null || user['avatar'] == "")
                                  ? const Icon(Icons.person, size: 40)
                                  : null,
                            ),
                          ),

                          const SizedBox(height: 16),
                          Text("Username: ${user['username']}"),
                          Text("Nama: ${user['name']}"),
                          Text("Email: ${user['email']}"),
                          Text("Role: ${user['role']}"),

                          const SizedBox(height: 12),
                          const Text("Bio:",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(user['bio'] ?? '-'),

                          const Spacer(),

                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                resetPassword(
                                    int.parse(user['id_user'].toString()));
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text("Reset Password"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  //──────────────────────────────
  // BUILD PAGE
  //──────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdminAppBar(
        title: "Kelola User",
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
        currentMenu: 'user',
        username: username,
        avatarUrl: avatarUrl,
        selectedIndex: selectedIndex,
        onItemSelected: (i) {
          setState(() => selectedIndex = i);
        },
      ),

      body: isLoadingUsers
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: userList.length,
              itemBuilder: (context, index) {
                final u = userList[index];

                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          (u['avatar'] != null && u['avatar'] != "")
                              ? NetworkImage(
                                  ApiService.avatarBaseUrl + u['avatar'])
                              : null,
                      child: (u['avatar'] == null || u['avatar'] == "")
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(u['username']),
                    subtitle: Text(u['email']),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'detail') {
                          openUserDetail(u);
                        } else if (value == 'reset') {
                          resetPassword(int.parse(u['id_user']));
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'detail',
                          child: Text("Detail User"),
                        ),
                        PopupMenuItem(
                          value: 'reset',
                          child: Text("Reset Password"),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
