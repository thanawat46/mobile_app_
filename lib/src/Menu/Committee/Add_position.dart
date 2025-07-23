import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/constants.dart' as config;

class AddPositionPage extends StatefulWidget {
  const AddPositionPage({Key? key}) : super(key: key);

  @override
  State<AddPositionPage> createState() => _AddPositionPageState();
}

class _AddPositionPageState extends State<AddPositionPage> {
  final TextEditingController _positionController = TextEditingController();
  List<String> positionList = [];

  @override
  void initState() {
    super.initState();
    fetchPositions();
  }

  Future<void> fetchPositions() async {
    try {
      final res = await http.get(Uri.parse('${config.apiUrl}/positions'));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          positionList = data.map((e) => e['position_name'].toString()).toList();
        });
      } else {
        debugPrint('โหลดตำแหน่งไม่สำเร็จ: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาด: $e');
    }
  }

  String generateIdPosition() {
    final nextNumber = positionList.length + 1;
    return 'SO${nextNumber.toString().padLeft(3, '0')}';
  }

  Future<void> addPosition() async {
    final newPosition = _positionController.text.trim();
    if (newPosition.isEmpty || positionList.contains(newPosition)) return;

    final newId = generateIdPosition();

    try {
      final res = await http.post(
        Uri.parse('${config.apiUrl}/positions-add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_position': newId,
          'position_name': newPosition,
        }),
      );

      if (res.statusCode == 201) {
        setState(() {
          positionList.add(newPosition);
          _positionController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เพิ่มตำแหน่งเรียบร้อย')),
        );
      } else if (res.statusCode == 409) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('รหัสตำแหน่งนี้มีอยู่แล้ว')),
        );
      } else {
        debugPrint('เพิ่มไม่สำเร็จ: ${res.body}');
      }
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดตอนเพิ่มตำแหน่ง: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('เพิ่มตำแหน่งกรรมการ', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0D47A1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            PositionInputSection(
              controller: _positionController,
              onSave: addPosition,
            ),
            const SizedBox(height: 24),
            PositionListSection(positionList: positionList),
          ],
        ),
      ),
    );
  }
}

class PositionInputSection extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSave;

  const PositionInputSection({
    Key? key,
    required this.controller,
    required this.onSave,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'ชื่อตำแหน่ง',
            labelStyle: const TextStyle(color: Color(0xFF0D47A1)),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF0D47A1)),
              borderRadius: BorderRadius.circular(10),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear, color: Color(0xFF0D47A1)),
              onPressed: () => controller.clear(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save),
            label: const Text('บันทึกตำแหน่ง'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PositionListSection extends StatelessWidget {
  final List<String> positionList;

  const PositionListSection({Key? key, required this.positionList}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.list, color: Color(0xFF0D47A1)),
              SizedBox(width: 8),
              Text(
                'รายการตำแหน่งทั้งหมด',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF0D47A1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: positionList.length,
              itemBuilder: (context, index) {
                final position = positionList[index];
                return Hero(
                  tag: 'position-$index',
                  child: Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF0D47A1),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        position,
                        style: const TextStyle(
                          color: Color(0xFF0D47A1),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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
