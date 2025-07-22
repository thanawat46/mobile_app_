import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/constants.dart' as config;

import 'Add_CommitteePage.dart';

class CommitteePage extends StatefulWidget {
  const CommitteePage({super.key});

  @override
  State<CommitteePage> createState() => _CommitteePageState();
}

class _CommitteePageState extends State<CommitteePage> {
  List<Map<String, String>> committeeData = [];
  String searchText = "";
  String currentUserPosition = 'ประธาน';

  final positionMap = {
    'ประธาน': 'SO001',
    'รองประธาน': 'SO002',
    'กรรมการ': 'SO003',
  };

  @override
  void initState() {
    super.initState();
    fetchCommitteeData();
  }

  Future<void> fetchCommitteeData() async {
    final url = Uri.parse('${config.apiUrl}/committee');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      setState(() {
        committeeData = data.map<Map<String, String>>((item) {
          return {
            "id": item['id_Committee'],
            "name": "${item['first_name']} ${item['last_name']}",
            "position": item['position_name'] ?? 'ไม่ทราบตำแหน่ง',
          };
        }).toList();
      });
    }
  }

  Future<void> updateCommitteePosition(String id, String newPositionId) async {
    final url = Uri.parse('${config.apiUrl}/committee/$id');
    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"position_id": newPositionId}),
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("อัปเดตตำแหน่งเรียบร้อยแล้ว")));
      fetchCommitteeData();
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> filtered = committeeData
        .where((item) => item["name"]!.contains(searchText))
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        title: const Text("รายชื่อคณะกรรมการ", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CommitteeSearchBar(onChanged: (value) {
              setState(() => searchText = value);
            }),
            const SizedBox(height: 16),
            const CommitteeHeaderRow(),
            const SizedBox(height: 8),
            Expanded(
              child: CommitteeList(
                filtered: filtered,
                currentUserPosition: currentUserPosition,
                positionMap: positionMap,
                onUpdatePosition: updateCommitteePosition,
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0D47A1),
        onPressed: () async {
          final shouldRefresh = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Add_Committee()),
          );

          if (shouldRefresh == true) {
            fetchCommitteeData(); // 🔁 เรียกโหลดข้อมูลใหม่
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );

  }
}

class CommitteeSearchBar extends StatelessWidget {
  final Function(String) onChanged;
  const CommitteeSearchBar({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
          decoration: const InputDecoration(
            hintText: "ค้นหาชื่อกรรมการ",
            prefixIcon: Icon(Icons.search),
            border: InputBorder.none,
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class CommitteeHeaderRow extends StatelessWidget {
  const CommitteeHeaderRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Color(0xFF0D47A1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Expanded(flex: 1, child: Text("ชื่อ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text("ตำแหน่ง", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text("เพิ่มเติม", textAlign: TextAlign.right, style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}

class CommitteeList extends StatelessWidget {
  final List<Map<String, String>> filtered;
  final String currentUserPosition;
  final Map<String, String> positionMap;
  final Function(String id, String newPositionId) onUpdatePosition;

  const CommitteeList({
    super.key,
    required this.filtered,
    required this.currentUserPosition,
    required this.positionMap,
    required this.onUpdatePosition,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final person = filtered[index];
        final name = person["name"]!;
        final currentPosition = person["position"]!;
        final id = person["id"]!;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[100],
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Expanded(flex: 3, child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text(currentPosition)),
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.search, color: Colors.orange),
                    onPressed: () {
                      if (currentUserPosition == 'ประธาน' || currentUserPosition == 'รองประธาน') {
                        String selectedPosition = ['ประธาน', 'รองประธาน', 'กรรมการ'].contains(currentPosition)
                            ? currentPosition
                            : 'กรรมการ';

                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text("เปลี่ยนตำแหน่งของ $name"),
                            content: DropdownButtonFormField<String>(
                              value: selectedPosition,
                              items: ['ประธาน', 'รองประธาน', 'กรรมการ']
                                  .map((pos) => DropdownMenuItem(value: pos, child: Text(pos)))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) selectedPosition = value;
                              },
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("ยกเลิก"),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  final newPositionId = positionMap[selectedPosition]!;
                                  onUpdatePosition(id, newPositionId);
                                },
                                child: const Text("ยืนยัน"),
                              ),
                            ],
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("คุณไม่มีสิทธิ์เปลี่ยนตำแหน่ง")),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
