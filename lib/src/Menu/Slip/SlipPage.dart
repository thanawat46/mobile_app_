import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'DetailsSlipPage.dart';
import 'package:mobile_app/constants.dart' as config;

class Slippage extends StatefulWidget {
  const Slippage({super.key});

  @override
  State<Slippage> createState() => _SlippageState();
}

class _SlippageState extends State<Slippage> {
  String searchQuery = "";
  bool isLoading = true;
  DateTime? selectedDate;
  List<Map<String, dynamic>> slipData = [];

  @override
  void initState() {
    super.initState();
    fetchSlipData();
  }

  Future<void> fetchSlipData() async {
    setState(() => isLoading = true);
    String apiUrl = '${config.apiUrl}/getslips';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      print("📡 เรียก API: $apiUrl");
      print("📥 ตอบกลับ: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);

        final List<Map<String, dynamic>> data = jsonData
            .where((item) =>
        item['id_slip'] != null &&
            item['first_name'] != null &&
            item['last_name'] != null &&
            item['date'] != null &&
            item['status_name'] != null)
            .map((item) {
          final fullDate = DateTime.parse(item['date']);
          return {
            "id_slip": item['id_slip'].toString(), // ✅ ใช้ id_slip แทน slip_number
            "name": "${item['first_name']} ${item['last_name']}",
            "date":
            "${fullDate.year}-${fullDate.month.toString().padLeft(2, '0')}-${fullDate.day.toString().padLeft(2, '0')}",
            "time":
            "${fullDate.hour.toString().padLeft(2, '0')}:${fullDate.minute.toString().padLeft(2, '0')}:${fullDate.second.toString().padLeft(2, '0')}",
            "status": item['status_name'],
          };
        }).toList();

        print("✅ จำนวนสลิปที่โหลดได้: ${data.length}");
        setState(() {
          slipData = data;
          isLoading = false;
        });
      } else {
        throw Exception('❌ โหลดข้อมูลล้มเหลว: ${response.statusCode}');
      }
    } catch (e) {
      print("❗ เกิดข้อผิดพลาด: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = slipData.where((data) {
      final matchesName =
      data["name"].toLowerCase().contains(searchQuery.toLowerCase());
      final matchesDate = selectedDate == null ||
          data["date"] ==
              "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";
      return matchesName && matchesDate;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        title: const Text(
          "สลิปเงินฝาก",
          style: TextStyle(color: Colors.white),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            color: Colors.white,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SlipSearchBar(
              onSearchChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              selectedDate: selectedDate,
              onDateSelected: (date) {
                setState(() {
                  selectedDate = date;
                });
              },
            ),
            const SizedBox(height: 16),
            const SlipTableHeader(),
            const SizedBox(height: 8),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredData.isEmpty
                  ? const Center(child: Text("ไม่มีข้อมูลที่ตรงกับเงื่อนไข"))
                  : SlipListView(data: filteredData),
            ),
          ],
        ),
      ),
    );
  }
}

class SlipSearchBar extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const SlipSearchBar({
    super.key,
    required this.onSearchChanged,
    required this.onDateSelected,
    required this.selectedDate,
  });

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    offset: Offset(0, 2))
              ],
            ),
            child: TextField(
              onChanged: onSearchChanged,
              decoration: const InputDecoration(
                hintText: "ค้นหา",
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              backgroundColor: Colors.blue[700],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon:
            const Icon(Icons.calendar_today, size: 18, color: Colors.white),
            label: Text(
              selectedDate != null
                  ? formatDate(selectedDate!)
                  : "เลือกวันที่",
              style: const TextStyle(color: Colors.white),
            ),
            onPressed: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (pickedDate != null) {
                onDateSelected(pickedDate);
              }
            },
          ),
        ),
      ],
    );
  }
}

class SlipTableHeader extends StatelessWidget {
  const SlipTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D47A1),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text("ชื่อ",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 2,
            child: Text("วัน",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 2,
            child: Text("เวลา",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 2,
            child: Text("สถานะ",
                textAlign: TextAlign.right,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class SlipListView extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const SlipListView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            onTap: () {
              print("➡️ เปิดดูสลิป: ${item["id_slip"]}");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DetailsSlipPage(idSlip: item["id_slip"].toString()),
                ),
              );
            },
            title: Text(item["name"],
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Row(
              children: [
                Expanded(
                    child: Text(item["date"], textAlign: TextAlign.start)),
                Expanded(
                    child: Text(item["time"], textAlign: TextAlign.center)),
                Expanded(
                  child: Text(
                    item["status"],
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: item["status"] == "อนุมัติแล้ว"
                          ? Colors.green
                          : item["status"] == "รอดำเนินการ"
                          ? Colors.orange
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
