import 'package:flutter/material.dart';
import '../widgets/creator_drawer.dart';
import '../widgets/creator_appbar.dart';
import '../widgets/profile_panel.dart';
import 'login_page.dart';
import 'edit_profil_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'detail_transaksi_creator.dart';

class CreatorTransaksiPage extends StatefulWidget {
  final String? username;
  final String? avatarUrl;
  final Map<String, dynamic>? data;
  final Future<void> Function()? reloadData;
  //final Future<void> Function(int)? uploadAvatarWeb;
  final Future<void> Function(int)? uploadAvatarMobile;

  const CreatorTransaksiPage({
    super.key,
    this.username,
    this.avatarUrl,
    this.data,
    this.reloadData,
    //this.uploadAvatarWeb,
    this.uploadAvatarMobile,
  });

  @override
  State<CreatorTransaksiPage> createState() => _CreatorTransaksiPageState();
}

class _CreatorTransaksiPageState extends State<CreatorTransaksiPage> {
  String username = '';
  String email = '';
  String role = '';
  String? avatarUrl;
  Map<String, dynamic>? data;

  bool isLoadingOrders = true;
  List<Map<String, dynamic>> groupedOrders = [];
  int selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    loadUserData().then((_) => loadOrders());
  }

  // ============================
  // LOAD USER DATA
  // ============================
  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final userId = prefs.getInt('id_user') ?? 0;
    role = prefs.getString('role') ?? '';

    if (role != 'creator') {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
      return;
    }

    final result = await ApiService.getDashboardData(token, userId: userId);

    if (!mounted) return;

    if (result['status'] == true) {
      final d = result['data'] as Map<String, dynamic>;

      setState(() {
        data = d;
        username = d['username'] ?? '';
        email = d['email'] ?? '';
        avatarUrl = (d['avatar'] != null && d['avatar'] != "")
            ? ApiService.avatarBaseUrl + d['avatar']
            : null;
      });
    }
  }

  // ============================
  // LOAD & GROUP ORDERS
  // ============================
  // ============================
  // LOAD & GROUP ORDERS (FIX)
  // ============================
  Future<void> loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('id_user') ?? 0;

    final result = await ApiService.getCreatorOrders(userId);

    if (!mounted) return;

    if (result['status'] == true && result['data'] is List) {
      final List rawData = result['data'];
      final Map<String, Map<String, dynamic>> map = {};

      for (final item in rawData) {
        final orderId = item['id_order'].toString();

        // ✅ FIX UTAMA ADA DI SINI
        List<String> images = [];

        if (item['images'] != null) {
          if (item['images'] is String) {
            final str = item['images'].toString();
            images = str.isNotEmpty ? str.split(',') : [];
          } else if (item['images'] is List) {
            images = (item['images'] as List)
                .map((e) => e.toString())
                .toList();
          }
        }

        map.putIfAbsent(orderId, () => {
          "id_order": item['id_order'],
          "order_status": item['order_status'] ?? "-",
          "payment_status": item['payment_status'], // optional
          "note": item['note'], // 🔥 INI KUNCI UTAMA
          "created_at": item['created_at'] ?? "-",
          "items": <Map<String, dynamic>>[],
        });

        map[orderId]!['items'].add({
          "id_artwork": item['id_artwork'],
          "title": item['title'] ?? "-",
          "price": item['price'] ?? 0,
          "images": images, // ← SUDAH List<String>
        });
      }

      setState(() {
        groupedOrders = map.values.toList();
        isLoadingOrders = false;
      });
    } else {
      setState(() => isLoadingOrders = false);
    }
  }


  // ============================
  // UI
  // ============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CreatorAppBar(
        title: "Kelola Transaksi",
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
      drawer: CreatorDrawer(
        currentMenu: 'transaksi',
        username: username,
        avatarUrl: avatarUrl,
        selectedIndex: selectedIndex,
        onItemSelected: (i) => setState(() => selectedIndex = i),
      ),
      body: isLoadingOrders
          ? const Center(child: CircularProgressIndicator())
          : groupedOrders.isEmpty
              ? const Center(child: Text("Belum ada order"))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: groupedOrders.length,
                  itemBuilder: (context, index) {
                    final order = groupedOrders[index];
                    final List items = order['items'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // HEADER
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Order #${order['id_order']}",
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  order['order_status']
                                      .toString()
                                      .toUpperCase(),
                                  style: const TextStyle(fontSize: 11),
                                ),
                              )
                            ],
                          ),

                          const SizedBox(height: 6),
                          Text(
                            "Tanggal: ${order['created_at']}",
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 12),
                          ),

                          const Divider(height: 22),

                          // ITEMS
                          ...items.map((art) {
                            final List images =
                                (art['images'] is List) ? art['images'] : [];

                            final String? img =
                                images.isNotEmpty && images[0] != ""
                                    ? "${ApiService.baseUrlimage ?? ""}/uploads/artworks/preview/${images[0]}"
                                    : null;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: img != null
                                        ? Image.network(
                                            img,
                                            width: 65,
                                            height: 65,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: 65,
                                            height: 65,
                                            color: Colors.grey.shade200,
                                            child: const Icon(
                                                Icons.image_not_supported),
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          art['title'],
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Rp ${art['price']}",
                                          style: TextStyle(
                                              color:
                                                  Colors.green.shade700),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            );
                          }).toList(),

                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        DetailCreatorTransaksiPage(
                                      order: order,
                                      idOrder: int.parse(
                                          order['id_order'].toString()),
                                    ),
                                  ),
                                );
                              },
                              child: const Text("Lihat Detail"),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
