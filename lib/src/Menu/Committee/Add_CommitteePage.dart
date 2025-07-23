import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/constants.dart' as config;

class Add_Committee extends StatefulWidget {
  const Add_Committee({super.key});

  @override
  State<Add_Committee> createState() => _Add_CommitteeState();
}

class _Add_CommitteeState extends State<Add_Committee> {
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> positions = [];
  Map<String, dynamic>? selectedUser;
  Map<String, dynamic>? selectedPosition;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    fetchUsers();
    fetchPositions();
  }

  Future<void> fetchUsers() async {
    final url = Uri.parse('${config.apiUrl}/users-committee');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      setState(() {
        users = data
            .map<Map<String, dynamic>>((u) => {
          "id": u["id_user"],
          "first_name": u["first_name"],
          "last_name": u["last_name"],
          "address": u["address"],
        })
            .toList();
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("โหลดรายชื่อผู้ใช้ไม่สำเร็จ")),
        );
      }
    }
  }

  Future<void> fetchPositions() async {
    final url = Uri.parse('${config.apiUrl}/positions');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      setState(() {
        positions = data
            .map<Map<String, dynamic>>((p) => {
          "id": p["id_position"],
          "name": p["position_name"],
        })
            .toList();
        if (positions.isNotEmpty) selectedPosition = positions[0];
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("โหลดตำแหน่งไม่สำเร็จ")),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (selectedUser == null || selectedPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณาเลือกผู้ใช้และตำแหน่ง")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final body = {
      "user_id": selectedUser!["id"],
      "position_id": selectedPosition!["id"],
    };

    final url = Uri.parse('${config.apiUrl}/committee/add');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("เพิ่มกรรมการเรียบร้อยแล้ว")),
        );
        Navigator.pop(context, true);
      }
    } else if (response.statusCode == 409) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ผู้ใช้นี้เป็นกรรมการอยู่แล้ว")),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("เกิดข้อผิดพลาดในการเพิ่มกรรมการ")),
        );
      }
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("เพิ่มกรรมการ"),
        backgroundColor: Colors.blue[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: users.isEmpty || positions.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("เลือกรายชื่อผู้ใช้",
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(
                  vertical: 8, horizontal: 12),
              child: const Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: Text("ชื่อ-นามสกุล",
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(
                      flex: 2,
                      child: Text("บ้านเลขที่",
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 1, child: SizedBox()),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final isSelected = selectedUser != null &&
                      selectedUser!["id"] == user["id"];
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.lightBlue[50]
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 3,
                            child: Text(
                                "${user["first_name"]} ${user["last_name"]}")),
                        Expanded(
                            flex: 2,
                            child: Text(user["address"] ?? "-")),
                        Expanded(
                          flex: 1,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                selectedUser = user;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected
                                  ? Colors.green
                                  : Colors.blue[900],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                            child:
                            Text(isSelected ? "เลือกแล้ว" : "เลือก"),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Map<String, dynamic>>(
              value: selectedPosition,
              decoration:
              const InputDecoration(labelText: "ตำแหน่ง"),
              items: positions.map((pos) {
                return DropdownMenuItem(
                  value: pos,
                  child: Text(pos["name"]),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedPosition = value);
                }
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitForm,
                icon: const Icon(Icons.save),
                label: const Text("บันทึก"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-add-committee', // ป้องกัน tag ซ้ำ
        backgroundColor: Colors.blue[900],
        onPressed: () {
          // ใส่สิ่งที่คุณอยากให้ทำตอนกดปุ่ม เช่น รีเฟรชหน้า หรือกลับ
          Navigator.pop(context);
        },
        child: const Icon(Icons.arrow_back),
      ),
    );
  }
}
