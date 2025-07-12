import 'package:flutter/material.dart';

class CommitteePage extends StatefulWidget {
  const CommitteePage({super.key});

  @override
  State<CommitteePage> createState() => _CommitteePageState();
}

class _CommitteePageState extends State<CommitteePage> {
  List<Map<String, String>> committeeData = [
    {"name": "สมชาย ใจดี", "position": "ประธาน"},
    {"name": "สุดา วงศ์ไทย", "position": "รองประธาน"},
    {"name": "ณัฐพงศ์ แสงทอง", "position": "กรรมการ"},
  ];
  String searchText = "";

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
            // Search
            Card(
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
                  onChanged: (value) {
                    setState(() {
                      searchText = value;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.indigo[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Expanded(flex: 3, child: Text("ชื่อ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text("ตำแหน่ง", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  Expanded(flex: 1, child: Text("เพิ่มเติม", textAlign: TextAlign.right, style: TextStyle(color: Colors.white))),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // List
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final person = filtered[index];
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
                        Expanded(flex: 3, child: Text(person["name"]!, style: const TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(flex: 2, child: Text(person["position"]!)),
                        Expanded(
                          flex: 1,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: const Icon(Icons.search, color: Colors.orange),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("ดูข้อมูล ${person["name"]}")),
                                );
                              },
                            ),
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
