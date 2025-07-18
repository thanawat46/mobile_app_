import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:mobile_app/constants.dart' as config;
import '../Login/LoginPage.dart';

class Profilepage extends StatefulWidget {
  final String idUser;

  const Profilepage({Key? key, required this.idUser}) : super(key: key);

  @override
  State<Profilepage> createState() => _ProfileState();
}

class _ProfileState extends State<Profilepage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool showPin = false;
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final response = await http.get(
        Uri.parse("${config.apiUrl}/Profile/users/${widget.idUser}"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['message'] == 'พบผู้ใช้งาน') {
          setState(() {
            userData = data['data'];
            profileImageUrl = data['data']['profile_image'];
            isLoading = false;
          });
        } else {
          setState(() {
            userData = {"error": "ไม่พบข้อมูล"};
            isLoading = false;
          });
        }
      } else {
        setState(() {
          userData = {"error": "ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์"};
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        userData = {"error": "เกิดข้อผิดพลาด: $e"};
        isLoading = false;
      });
    }
  }

  Future<void> pickAndUploadImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (picked == null) return;

      final file = File(picked.path);
      if (!file.existsSync()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ไม่พบไฟล์รูปภาพที่เลือก")),
        );
        return;
      }

      final fileName = 'profile_${widget.idUser}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final destination = 'profile_images/$fileName';

      // แสดงโหลด
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(color: Color(0xFF0069FF)),
              SizedBox(width: 16),
              Text("กำลังอัปโหลด..."),
            ],
          ),
        ),
      );

      // ลบรูปเก่าถ้ามี
      if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
        try {
          final refToDelete = FirebaseStorage.instance.refFromURL(profileImageUrl!);
          await refToDelete.delete();
          print("ลบรูปเดิมแล้ว");
        } catch (e) {
          print("ลบรูปเดิมไม่สำเร็จ: $e");
        }
      }

      // อัปโหลดใหม่
      final ref = FirebaseStorage.instance.ref(destination);
      await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
      final downloadUrl = await ref.getDownloadURL();

      // ส่ง URL ไปเก็บใน Database
      final response = await http.post(
        Uri.parse('${config.apiUrl}/users/profile-image'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_user': widget.idUser,
          'profile_image': downloadUrl,
        }),
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // ปิด popup loading

      if (response.statusCode == 200) {
        setState(() {
          profileImageUrl = downloadUrl;
        });

        // แสดง popup สำเร็จ
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: const [
                Icon(Icons.check_circle, color: Color(0xFF0069FF), size: 28),
                SizedBox(width: 10),
                Text("สำเร็จ", style: TextStyle(color: Color(0xFF0069FF), fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text("เปลี่ยนรูปโปรไฟล์เรียบร้อยแล้ว"),
          ),
        );

        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.of(context).pop(); // ปิด popup สำเร็จ
      } else {
        throw Exception("อัปเดต URL ไปยัง backend ไม่สำเร็จ: ${response.body}");
      }
    } catch (e, s) {
      print("Upload error: $e");
      print(s);
      if (mounted) {
        Navigator.of(context).pop(); // ปิด popup โหลดถ้ามี
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("เกิดข้อผิดพลาดในการอัปโหลด: $e")),
        );
      }
    }
  }

  Future<void> updateProfileImageToDatabase(String imageUrl) async {
    try {
      final response = await http.post(
        Uri.parse('${config.apiUrl}/users/profile-image'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_user': widget.idUser,
          'profile_image': imageUrl,
        }),
      );

      if (response.statusCode == 200) {
        print("อัปเดตรูปโปรไฟล์ในฐานข้อมูลเรียบร้อยแล้ว");
      } else {
        print("เกิดข้อผิดพลาดในการอัปเดตโปรไฟล์: ${response.body}");
      }
    } catch (e) {
      print("ส่งข้อมูล URL รูปภาพผิดพลาด: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : userData!['error'] != null
          ? Center(child: Text(userData!['error'], style: TextStyle(color: Colors.white)))
          : Column(
        children: [
          const SizedBox(height: 60),
          GestureDetector(
            onTap: pickAndUploadImage,
            child: CircleAvatar(
              radius: 45,
              backgroundColor: Colors.white,
              backgroundImage:
              profileImageUrl != null ? NetworkImage(profileImageUrl!) : null,
              child: profileImageUrl == null
                  ? const Icon(Icons.person, size: 70, color: Colors.grey)
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          const Text("แตะเพื่อเปลี่ยนรูป", style: TextStyle(color: Colors.white)),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: ListView(
                children: [
                  UserInfoCard(icon: Icons.home, title: "บ้านเลขที่", value: userData?['address'] ?? "-"),
                  UserInfoCard(icon: Icons.group, title: "บทบาท", value: userData?['role'] ?? "-"),
                  UserInfoCard(icon: Icons.phone, title: "เบอร์โทรศัพท์", value: userData?['phone_number'] ?? "-"),
                  UserInfoCard(
                    icon: Icons.lock,
                    title: "รหัส PIN",
                    value: showPin ? (userData?['pin_user'] ?? "-") : "******",
                    trailing: IconButton(
                      icon: Icon(showPin ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => showPin = !showPin),
                    ),
                  ),
                  UserInfoCard(icon: Icons.badge, title: "รหัสสมาชิก", value: widget.idUser),
                  const SizedBox(height: 30),
                  const LogoutButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UserInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Widget? trailing;

  const UserInfoCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.value,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      icon: const Icon(Icons.logout, color: Colors.white),
      label: const Text("ออกจากระบบ", style: TextStyle(fontSize: 18, color: Colors.white)),
      onPressed: () {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: const [
                Icon(Icons.logout, color: Colors.red),
                SizedBox(width: 10),
                Text("ออกจากระบบ", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text("คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบ?", style: TextStyle(fontSize: 16)),
            actionsPadding: const EdgeInsets.only(bottom: 10, right: 10),
            actions: [
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
                child: const Text("ยกเลิก", style: TextStyle(fontSize: 16)),
                onPressed: () => Navigator.of(context).pop(),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("ออกจากระบบ", style: TextStyle(fontSize: 16)),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                        (route) => false,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
