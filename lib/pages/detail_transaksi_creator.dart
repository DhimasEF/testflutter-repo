import 'package:flutter/material.dart';
import '../widgets/creator_drawer.dart';
import '../widgets/creator_appbar.dart';
import '../widgets/profile_panel.dart';
import 'edit_profil_page.dart';
import 'login_page.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DetailCreatorTransaksiPage extends StatefulWidget {
  final Map<String, dynamic> order; // ← menerima data Order langsung
  final String? username;
  final String? avatarUrl;
  final Map<String, dynamic>? data;
  final Future<void> Function()? reloadData;
  //final Future<void> Function(int)? uploadAvatarWeb;
  final Future<void> Function(int)? uploadAvatarMobile;
  final int idOrder;

  const DetailCreatorTransaksiPage({
    super.key,
    required this.order,
    this.username,
    this.avatarUrl,
    this.data,
    this.reloadData,
    //this.uploadAvatarWeb,
    this.uploadAvatarMobile,
    required this.idOrder,
  });

  @override
  _DetailCreatorTransaksiPageState createState() =>
      _DetailCreatorTransaksiPageState();
}

class _DetailCreatorTransaksiPageState
    extends State<DetailCreatorTransaksiPage> {
    String username = '';
    String email = '';
    String role = '';
    String? avatarUrl;
    Map<String, dynamic>? data;

    int selectedIndex = 2;

    @override
    void initState() {
      super.initState();
      loadUserData();
    }

    void showPaymentProofModal(
      BuildContext context, {
      required String imageUrl,
      required int idOrder,
    }) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text("Bukti Pembayaran"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // IMAGE
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          height: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 220,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image, size: 60),
                          ),
                        )
                      : Container(
                          height: 220,
                          color: Colors.grey.shade100,
                          alignment: Alignment.center,
                          child: const Text(
                            "Bukti pembayaran belum tersedia",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                ),

                const SizedBox(height: 20),

                // BUTTONS
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          minimumSize: const Size(0, 45),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          await handleRejectPayment(idOrder);
                        },
                        child: const Text("Tolak"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(0, 45),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          await handleAcceptPayment(idOrder);
                        },
                        child: const Text("ACC"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    }

    Future<void> handleAcceptPayment(int idOrder) async {
    final res = await ApiService.acceptPayment(idOrder);

    if (res['status'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pembayaran di-ACC")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? "Gagal ACC")),
      );
    }
  }

  Future<void> handleRejectPayment(int idOrder) async {
    final res = await ApiService.rejectPayment(idOrder);

    if (res['status'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pembayaran ditolak")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? "Gagal menolak")),
      );
    }
  }

  // ======================================================
  // LOAD USER DATA
  // ======================================================
  Future<void> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';
    int userId = prefs.getInt('id_user') ?? 0;

    role = prefs.getString('role') ?? '';

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
      final d = result['data'];

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

  // ======================================================
  // UI
  // ======================================================
  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final items = order["items"] as List;

    final totalPrice = items.fold(0, (sum, item) {
      final p = item["price"];

      // Kalau null → jadikan 0
      if (p == null) return sum;

      // Konversi ke string untuk dibersihkan
      final s = p.toString().replaceAll(RegExp(r'[^0-9]'), '');

      // coba parse → kalau gagal jadi 0
      final value = int.tryParse(s) ?? 0;

      return sum + value;
    });

    return Scaffold(
      appBar: CreatorAppBar(
        title: "Detail Transaksi",
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

      // ======================================================
      // BODY DETAIL ORDER
      // ======================================================
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------------------------
            // HEADER ORDER
            // -------------------------
            Text(
              "Order #${order['id_order']}",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              "Tanggal: ${order['created_at']}",
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            SizedBox(height: 6),

            Container(
              padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                order["order_status"].toString().toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
            ),

            SizedBox(height: 20),
            Divider(),

            // -------------------------
            // LIST ITEM
            // -------------------------
            Text(
              "Item dalam Order",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            ...items.map((art) {
              final img = art['images'].isNotEmpty
                  ? ApiService.baseUrlimage + "/uploads/artworks/preview/" + art['images'][0]
                  : null;

              return Container(
                padding: EdgeInsets.all(14),
                margin: EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: Offset(0, 3)),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: img != null
                          ? Image.network(img,
                              width: 70, height: 70, fit: BoxFit.cover)
                          : Container(
                              width: 70,
                              height: 70,
                              color: Colors.grey.shade200,
                              child: Icon(Icons.image_not_supported),
                            ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            art["title"],
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Rp ${art["price"]}",
                            style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            Divider(height: 28),

            // -------------------------
            // TOTAL HARGA
            // -------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total Harga",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Rp $totalPrice",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent),
                ),
              ],
            ),

            SizedBox(height: 20),

            // -------------------------
            // ACTION BUTTON
            // -------------------------
            ElevatedButton(
              onPressed: () {
                debugPrint("ORDER DATA => ${widget.order}");
                debugPrint("NOTE => ${widget.order['note']}");

                final note = widget.order['note'];
                showPaymentProofModal(
                  context,
                  imageUrl: note != null && note.toString().isNotEmpty
                      ? ApiService.baseUrlimage + "/uploads/payment/" + note
                      : "",
                  idOrder: widget.idOrder,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "Lihat Bukti Pembayaran",
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 14),

            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                "Batalkan Order",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),

            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
