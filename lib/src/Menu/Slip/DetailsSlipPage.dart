import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_app/constants.dart' as config;

import 'SlipPage.dart';

class DetailsSlipPage extends StatefulWidget {
  final String idSlip;

  const DetailsSlipPage({super.key, required this.idSlip});

  @override
  State<DetailsSlipPage> createState() => _DetailsSlipPageState();
}

class _DetailsSlipPageState extends State<DetailsSlipPage> {
  bool isLoading = true;
  bool hasError = false;
  Map<String, dynamic> slipData = {};

  @override
  void initState() {
    super.initState();
    fetchSlipDetails();
  }

  Future<void> fetchSlipDetails() async {
    final url = '${config.apiUrl}/getslips-Details?id_slip=${widget.idSlip}';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          slipData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load data");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text("รายละเอียดสลิปเงินฝาก"),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        centerTitle: true,
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
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : hasError
            ? const Center(
          child: Text(
            "ไม่สามารถดึงข้อมูลได้ กรุณาลองใหม่",
            style: TextStyle(color: Colors.red),
          ),
        )
            : slipData.isEmpty
            ? const Center(child: Text("ไม่พบข้อมูล"))
            : SlipDetailCard(data: slipData),
      ),
    );
  }
}

class SlipDetailCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const SlipDetailCard({super.key, required this.data});

  String formatDateTime(String rawDate) {
    final dt = DateTime.tryParse(rawDate);
    if (dt == null) return rawDate;
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} "
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _updateStatus(BuildContext context, String status) async {
    final url = Uri.parse('${config.apiUrl}/update-slip-status');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id_slip": data["id_slip"],
        "new_status": status,
      }),
    );

    if (response.statusCode == 200) {
      final message = status == "S001" ? "อนุมัติเรียบร้อยแล้ว" : "ไม่อนุมัติรายการแล้ว";

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("สำเร็จ", style: TextStyle(color: Colors.blue)),
          content: Text(message),
        ),
      );
      await Future.delayed(const Duration(seconds: 1));
      if (context.mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ไม่สามารถอัปเดตสถานะได้")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = data["image_url"];

    return Card(
      color: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl != null && imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) => const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "ไม่สามารถโหลดรูปภาพได้",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "ไม่พบรูปภาพ",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 16),
              SlipDetailRow(
                icon: Icons.person,
                label: "ชื่อ",
                value: "${data["first_name"]} ${data["last_name"]}",
                iconColor: Colors.blue.shade800,
              ),
              SlipDetailRow(
                icon: Icons.calendar_today,
                label: "วันที่",
                value: formatDateTime(data["date"]),
                iconColor: Colors.indigo.shade700,
              ),
              SlipDetailRow(
                icon: Icons.confirmation_number,
                label: "หมายเลขสลิป",
                value: data["slip_number"].toString(),
                iconColor: Colors.cyan.shade700,
              ),
              SlipDetailRow(
                icon: Icons.attach_money,
                label: "จำนวนเงิน",
                value: "${data["amount_slip"]} บาท",
                iconColor: Colors.green.shade700,
              ),
              SlipDetailRow(
                icon: Icons.check_circle,
                label: "สถานะ",
                value: data["status_name"],
                iconColor: Colors.blue.shade600,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateStatus(context, "S001"),
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text("อนุมัติ", style: TextStyle(fontSize: 16 , color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateStatus(context, "S003"),
                      icon: const Icon(Icons.close, color: Colors.white),
                      label: const Text("ไม่อนุมัติ", style: TextStyle(fontSize: 16 , color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SlipDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const SlipDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "$label: $value",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
