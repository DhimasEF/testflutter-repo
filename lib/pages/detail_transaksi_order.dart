import 'package:flutter/material.dart';
import '../widgets/user_drawer.dart';
import '../widgets/user_appbar.dart';
import '../widgets/profile_panel.dart';
import 'edit_profil_page.dart';
import 'login_page.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// WAJIB UNTUK WEB — File diganti jadi XFile
import 'package:image_picker/image_picker.dart';

class DetailTransaksiOrderPage extends StatefulWidget {
  final Map<String, dynamic> order;
  final String? username;
  final String? avatarUrl;
  final Map<String, dynamic>? data;
  final Future<void> Function()? reloadData;
  //final Future<void> Function(int)? uploadAvatarWeb;
  final Future<void> Function(int)? uploadAvatarMobile;
  final int idOrder;

  const DetailTransaksiOrderPage({
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
  _DetailTransaksiOrderPageState createState() =>
      _DetailTransaksiOrderPageState();
}

class _DetailTransaksiOrderPageState extends State<DetailTransaksiOrderPage> {
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

  // ======================================================
  // LOAD USER DATA
  // ======================================================
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
  // SUBMIT PAYMENT (pakai XFile)
  // ======================================================
  Future submitPayment(int totalPrice, XFile bukti) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Mengirim pembayaran...")),
    );

    final result = await ApiService.uploadPaymentProof(
      idOrder: widget.idOrder,
      amount: totalPrice,
      file: bukti,
    );

    if (!mounted) return;

    if (result["status"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Pembayaran berhasil dikirim!")),
      );

      widget.reloadData?.call();
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["message"] ?? "Gagal mengirim")),
      );
    }
  }

  // ======================================================
  // PAYMENT DIALOG
  // ======================================================
  void showPaymentDialog(int totalPrice) {
    XFile? buktiFile;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text("Pembayaran"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Nominal Pembayaran:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey.shade200,
                    ),
                    child: Text(
                      "Rp $totalPrice",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  Text("Upload Bukti Pembayaran:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),

                  GestureDetector(
                    onTap: () async {
                      final ImagePicker picker = ImagePicker();
                      final picked = await picker.pickImage(
                        source: ImageSource.gallery,
                      );

                      if (picked != null) {
                        setStateDialog(() {
                          buktiFile = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueAccent),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.upload, color: Colors.blueAccent),
                          SizedBox(width: 10),
                          Text(
                            buktiFile == null
                                ? "Pilih File"
                                : "File dipilih ✓",
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (buktiFile == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Harap upload bukti pembayaran"),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(ctx);
                    await submitPayment(totalPrice, buktiFile!);
                  },
                  child: Text("Kirim Pembayaran"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ======================================================
  // BUILD UI
  // ======================================================
  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final items = order["items"] as List;

    final totalPrice = items.fold(0, (sum, item) {
      final p = item["price"];

      if (p == null) return sum;

      final priceText = p.toString()
          .replaceAll(".00", "")      // Hapus desimal
          .replaceAll(",", "")        // Hapus koma ribuan
          .replaceAll(RegExp(r'[^0-9]'), '');

      final value = int.tryParse(priceText) ?? 0;


      return sum + value;
    });

    return Scaffold(
      appBar: UserAppBar(
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

      drawer: UserDrawer(
        currentMenu: 'transaksi',
        username: username,
        avatarUrl: avatarUrl,
        selectedIndex: selectedIndex,
        onItemSelected: (i) => setState(() => selectedIndex = i),
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

            // ===========================
            // PAYMENT INFORMATION
            // ===========================
            Text(
              "Status Pembayaran:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 6),

            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey.shade100,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    (order["payment_status"] ?? "unknown").toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: order["payment_status"] == "paid"
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                  Text(
                    "Rp ${order["total_paid"] ?? 0}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),
            Divider(),

            Text(
              "Item dalam Order",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            ...items.map((art) {
              final img = art['images'].isNotEmpty
                  ? ApiService.baseUrlimage +
                      "/uploads/artworks/preview/" +
                      art['images'][0]
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
                          ? Image.network(
                              img,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                            )
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
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            Divider(height: 28),

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
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: order["payment_status"] == "paid"
                  ? null
                  : () => showPaymentDialog(totalPrice),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                "Bayar Sekarang",
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
