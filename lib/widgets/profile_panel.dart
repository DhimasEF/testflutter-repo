import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/profile_service.dart';

Future<void> showProfilePanel(
  BuildContext context, {
  required String? avatarUrl,
  required Map<String, dynamic> data,
  required Future<void> Function()? reloadData,
  //required Future<void> Function(int)? uploadAvatarWeb,
  // required Future<void> Function(int) uploadAvatarMobile,
  required Widget Function(Map<String, dynamic>) editPageBuilder,
}) {
  return showGeneralDialog(
    context: context,
    barrierLabel: "Profil Admin",
    barrierDismissible: true,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, anim1, anim2) {
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            bottomLeft: Radius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.75,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Profil Admin",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // AVATAR + EDIT BUTTON
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: avatarUrl != null
                        ? NetworkImage('$avatarUrl?t=${DateTime.now().millisecondsSinceEpoch}')
                        : const AssetImage('assets/default.jpg') as ImageProvider,
                    ),
                    //if (uploadAvatarWeb != null)
                    // if (uploadAvatarMobile != null)
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: InkWell(
                          onTap: () async {
                            SharedPreferences prefs = await SharedPreferences.getInstance();
                            int userId = prefs.getInt('id_user') ?? 0;

                            final newAvatar = await ProfileService.uploadAvatar(userId);

                            Navigator.pop(context);

                            if (newAvatar != null && reloadData != null) {
                              await reloadData();
                            }
                          },
                          // onTap: () async {
                          //   SharedPreferences prefs =
                          //       await SharedPreferences.getInstance();
                          //   int userId = prefs.getInt('id_user') ?? 0;

                          //   //await uploadAvatarWeb(userId);
                          //   await uploadAvatarMobile(userId);
                          //   Navigator.pop(context);

                          //   if (reloadData != null) reloadData();
                          // },
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 20),
                Divider(),

                // INFORMASI USER
                infoRow("Nama", data["name"]),
                infoRow("Email", data["email"]),
                infoRow("Username", data["username"]),
                infoRow("Role", data["role"]),
                infoRow("Bio", data["bio"]),

                const SizedBox(height: 20),

                // TOMBOL EDIT PROFIL
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit Profil"),
                  onPressed: () async {
                    Navigator.pop(context);

                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => editPageBuilder(data),
                      ),
                    );

                    if (updated == true && reloadData != null) {
                      reloadData();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, anim1, anim2, child) {
      return SlideTransition(
        position:
            Tween(begin: const Offset(1, 0), end: const Offset(0, 0)).animate(anim1),
        child: child,
      );
    },
  );
}

/// fungsi untuk satu baris informasi
Widget infoRow(String label, dynamic value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        Flexible(
          child: Text(
            value != null ? value.toString() : "-",
            textAlign: TextAlign.right,
          ),
        ),
      ],
    ),
  );
}
