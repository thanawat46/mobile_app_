import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'Add_announcement_page.dart';
import 'package:mobile_app/constants.dart' as config;

class AnnouncementPage extends StatefulWidget {
  const AnnouncementPage({Key? key}) : super(key: key);

  @override
  State<AnnouncementPage> createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<AnnouncementPage> {
  List<dynamic> announcements = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAnnouncements();
  }

  Future<void> fetchAnnouncements() async {
    try {
      final response = await http.get(Uri.parse('${config.apiUrl}/announcements'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          announcements = data['data'];
          isLoading = false;
        });
      } else {
        throw Exception("ไม่สามารถโหลดข้อมูลประกาศได้");
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาด: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ประกาศข่าวสาร"),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D47A1)))
          : announcements.isEmpty
          ? const Center(child: Text("ไม่มีประกาศ"))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: announcements.length,
        itemBuilder: (context, index) {
          final item = announcements[index];
          return AnnouncementCard(item: item);
        },
      ),
      floatingActionButton: SizedBox(
        width: 60,
        height: 60,
        child: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddAnnouncementPage()),
            );

            if (result == true) {
              setState(() {
                isLoading = true;
              });
              fetchAnnouncements();
            }
          },
          backgroundColor: const Color(0xFF0D47A1),
          child: const Icon(Icons.add_photo_alternate, color: Colors.white, size: 32), // ✅ ปรับขนาด icon ด้วย
        ),
      ),

    );
  }
}

class AnnouncementCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const AnnouncementCard({Key? key, required this.item}) : super(key: key);

  String formatDate(String dateStr) {
    final dateTime = DateTime.parse(dateStr);
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              item["image_url"],
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const SizedBox(
                  height: 150,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item["description"],
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text("ประกาศเมื่อ: ${formatDate(item["created_at"])}",
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
