import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class UploadBottomSheet extends StatefulWidget {
  final VoidCallback? onUploaded;

  const UploadBottomSheet({super.key, this.onUploaded});

  @override
  State<UploadBottomSheet> createState() => _UploadBottomSheetState();
}

class _UploadBottomSheetState extends State<UploadBottomSheet> {
  final TextEditingController titleC = TextEditingController();
  final TextEditingController descC = TextEditingController();
  final TextEditingController priceC = TextEditingController();
  final TextEditingController tagC = TextEditingController();

  List<String> tags = [];
  List<XFile> images = []; 
  Uint8List? mainPreview;

  bool uploading = false;

  // PICK MULTI IMAGES (max 5)
  // Future pickImages() async {
  //   final picker = ImagePicker();
  //   final results = await picker.pickMultiImage();

  //     if (results.isEmpty) return;

  //     if (results.length > 5) {
  //       ScaffoldMessenger.of(context).shiSnackBar(
  //         const SnackBar(content: Text("Max 5 gambar!")),
  //       );
  //       return;
  //     }

  //     if (results.length > 5) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text("Max 5 gambar!")),
  //       );
  //     return;
  //   }

  //   images = results;

  //   if (images.isNotEmpty) {
  //     mainPreview = await images.first.readAsBytes();
  //   }

  //   setState(() {});
  //   }
  Future pickImages() async {
    final picker = ImagePicker();

    try {
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (picked == null) return;

      if (images.length >= 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Max 5 gambar!")),
        );
        return;
      }

      images.add(picked);
      mainPreview = await picked.readAsBytes();

      setState(() {});
    } catch (e) {
      debugPrint("ERROR PICK IMAGE: $e");
    }
  }

  // SUBMIT UPLOAD
  Future submitUpload() async {
    if (titleC.text.isEmpty || images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Judul & gambar wajib diisi!")),
      );
      return;
    }

    setState(() => uploading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString("token") ?? "";
    int userId = prefs.getInt("id_user") ?? 0;

    final response = await ApiService.uploadArtwork(
      token: token,
      userId: userId,
      title: titleC.text,
      description: descC.text,
      price: priceC.text,
      tags: tags,
      images: images,
    );

    setState(() => uploading = false);

    if (response['status'] == true) {
      if (mounted) Navigator.pop(context); // tutup dulu

      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onUploaded?.call();
      });
      
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal upload: ${response['message']}")),
      );
    }
  }

  // PREVIEW BUILDER WEB + MOBILE
  // Widget buildPreview(XFile file) {
  //   return FutureBuilder(
  //     future: file.readAsBytes(),
  //     builder: (context, snap) {
  //       if (!snap.hasData) {
  //         return Container(
  //           width: 120,
  //           height: 120,
  //           color: Colors.grey[200],
  //         );
  //       }

  //       return Image.memory(
  //         snap.data!,
  //         width: 120,
  //         height: 120,
  //         fit: BoxFit.cover,
  //       );
  //     },
  //   );
  // }
  
  Widget buildPreview(XFile file) {
    return Image.file(
      File(file.path),
      width: 120,
      height: 120,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 22,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text("Upload Konten",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 15),

            // TITLE
            TextField(
              controller: titleC,
              decoration: const InputDecoration(
                labelText: "Judul Konten",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            // PRICE
            TextField(
              controller: priceC,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Harga",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            // DESCRIPTION
            TextField(
              controller: descC,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Deskripsi",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            // TAG INPUT
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: tagC,
                    decoration: const InputDecoration(
                      labelText: "Tambah Tag",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    if (tagC.text.isNotEmpty) {
                      setState(() {
                        tags.add(tagC.text.trim());
                        tagC.clear();
                      });
                    }
                  },
                  child: const Text("Add"),
                )
              ],
            ),

            Wrap(
              spacing: 8,
              children: tags
                  .map((t) => Chip(
                        label: Text(t),
                        onDeleted: () {
                          setState(() => tags.remove(t));
                        },
                      ))
                  .toList(),
            ),

            const SizedBox(height: 15),

            // MAIN PREVIEW
            mainPreview == null
                ? const Center(child: Text("Belum ada gambar dipilih"))
                : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      mainPreview!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),

            const SizedBox(height: 15),

            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  debugPrint("BUTTON DIPENCET");
                  pickImages();
                },
                icon: const Icon(Icons.image),
                label: const Text("Pilih Maksimal 5 Gambar"),
              ),
            ),

            const SizedBox(height: 20),

            if (images.isNotEmpty)
              SizedBox(
                height: 120,
                child: GridView.builder(
                  scrollDirection: Axis.horizontal,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return buildPreview(images[index]);
                  },
                ),
              ),

            const SizedBox(height: 20),

            uploading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: submitUpload,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    child: const Text("Upload"),
                  ),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
}
