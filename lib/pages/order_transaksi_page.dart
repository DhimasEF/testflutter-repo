import 'package:flutter/material.dart';
import '../widgets/user_drawer.dart';
import '../widgets/user_appbar.dart';
import '../widgets/profile_panel.dart';
import 'login_page.dart';
import 'edit_profil_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
// import '../services/profile_service.dart';
import 'detail_transaksi_order.dart';// pastikan path sesuai

class OrderTransaksiPage extends StatefulWidget {
  final String? username;
  final String? avatarUrl;
  final Map<String, dynamic>? data;
  final Future<void> Function()? reloadData;
  //final Future<void> Function(int)? uploadAvatarWeb;
  // final Future<void> Function(int) uploadAvatarMobile;

  const OrderTransaksiPage({
    super.key,
    this.username,
    this.avatarUrl,
    this.data,
    this.reloadData,
    //this.uploadAvatarWeb,
    // required this.uploadAvatarMobile,
  });

  @override
  _OrderTransaksiPageState createState() => _OrderTransaksiPageState();
}

class _OrderTransaksiPageState extends State<OrderTransaksiPage> {
  String username = '';
  String email = '';
  String role = '';
  String? avatarUrl;
  Map<String, dynamic>? data;

   bool isLoadingOrders = true;

  /// hasil akhir → list order yg sudah dikelompokkan
  List<Map<String, dynamic>> groupedOrders = [];

  int selectedIndex = 2;  // posisi menu (Kelola Transaksi)

  @override
  void initState() {
    super.initState();
    loadUserData().then((_) {
      loadOrders();
    });
  }

  Future<void> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';
    int userId = prefs.getInt('id_user') ?? 0;
    role = prefs.getString('role') ?? '';

    if (role != 'user') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
      return;
    }

    // Ambil data lengkap dari API
    final result = await ApiService.getDashboardData(token, userId: userId);
    if (!mounted) return;

    if (result['status'] == true && result['data'] != null) {
      final fetchedData = result['data'] as Map<String, dynamic>; // <-- aman
      setState(() {
        data = fetchedData;                         // <-- pastikan data bukan null
        username = fetchedData['username'] ?? '';
        avatarUrl = (fetchedData['avatar'] != null && fetchedData['avatar'] != "")
          ? ApiService.avatarBaseUrl + fetchedData['avatar']
          : null;
        email = fetchedData['email'] ?? '';
      });
    }
  }

  Future<void> loadOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int userId = prefs.getInt('id_user') ?? 0;

    final result = await ApiService.getMyAllOrders(userId);

    if (!mounted) return;

    if (result['status'] == true) {
      List<dynamic> rawData = result['data'];

      /// GROUP BY id_order
      Map<String, dynamic> map = {};

      for (var item in rawData) {
        final orderId = item['id_order'].toString();

        // Parse images
        dynamic rawImg = item['images'];
        List<String> parsedImages = [];

        if (rawImg is String) {
          parsedImages = rawImg.isNotEmpty ? rawImg.split(",") : [];
        } else if (rawImg is List) {
          parsedImages = rawImg.map((e) => e.toString()).toList();
        }

        if (!map.containsKey(orderId)) {
          map[orderId] = {
            "id_order": item['id_order'],
            "id_buyer": item['id_buyer'],
            "order_status": item['order_status'],
            "payment_status": item['payment_status'], // 🔥 FIX
            "total_price": item['total_price'],
            "total_paid": item['total_paid'],
            "note": item['note'],
            "created_at": item['created_at'],
            "items": [],
          };
        }


        map[orderId]["items"].add({
          "id_artwork": item["id_artwork"],
          "title": item["title"],
          "price": item["price"],
          "images": parsedImages
        });
      }

      // ✔ pindahkan setState di luar loop!
      setState(() {
        groupedOrders = List<Map<String, dynamic>>.from(map.values);
        isLoadingOrders = false;
      });

    } else {
      setState(() => isLoadingOrders = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UserAppBar(
        title: "Order Transaksi",
        username: username,
        avatarUrl: avatarUrl,
        onProfileTap: () => showProfilePanel(
          context,
          avatarUrl: avatarUrl,
          data: data ?? {},                  // <-- kasih default kosong supaya aman
          reloadData: loadUserData,          // <-- pakai function dari state
          //uploadAvatarWeb: widget.uploadAvatarWeb, // <-- ambil dari widget
          // uploadAvatarMobile: widget.uploadAvatarMobile, // <-- ambil dari widget
          editPageBuilder: (d) => EditProfilePage(userData: d),
        ),
      ),
      drawer: UserDrawer(
        currentMenu: 'transaksi',
        username: username,
        avatarUrl: avatarUrl,
        selectedIndex: selectedIndex,
        onItemSelected: (i) {
          setState(() => selectedIndex = i);
        },
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
                  final items = order['items'] as List;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 18),
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
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          
                          /// ORDER HEADER
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Order #${order['id_order']}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  order['payment_status'].toString().toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              )
                            ],
                          ),

                          const SizedBox(height: 6),
                          Text(
                            "Tanggal: ${order['created_at']}",
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),

                          const Divider(height: 22),

                          /// ITEM LIST
                          ...items.map((art) {
                            final img = art['images'].isNotEmpty
                                ? ApiService.baseUrlimage + "/uploads/artworks/preview/" + art['images'][0]
                                : null;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
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
                                            child: const Icon(Icons.image_not_supported),
                                          ),
                                  ),

                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          art['title'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Rp ${art['price']}",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),

                          const SizedBox(height: 6),

                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetailTransaksiOrderPage(
                                      order: order,     
                                      idOrder: int.parse(order["id_order"].toString()),
                                    ),
                                  ),
                                );
                              },
                              child: const Text("Lihat Detail"),
                            ),
                          ),

                        ],
                      ),
                    ),
                  );
                },
              )
    );
  }
}
