import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/constants.dart' as config;

class HistoryPage extends StatefulWidget {
  final String idUser;

  const HistoryPage({super.key, required this.idUser});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  Map<String, List<Map<String, dynamic>>> groupedDeposits = {};
  bool isLoading = true;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    fetchDepositHistory();
  }

  Future<void> fetchDepositHistory() async {
    setState(() => isLoading = true);

    String url = '${config.apiUrl}/deposit-history?id_user=${widget.idUser}';

    if (selectedDate != null) {
      final dateStr =
          '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}';
      url += '&date=$dateStr';
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final List data = result['data'];

        Map<String, List<Map<String, dynamic>>> grouped = {};

        for (var item in data) {
          final date = DateTime.parse(item['date_deposit']);
          final dateKey = formatDateOnlyTH(date);
          final time =
              '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

          grouped.putIfAbsent(dateKey, () => []).add({
            'id': item['id_DepositAm'],
            'time': time,
            'amount': item['amount_Deposit'],
            'id_status': item['id_status'],
            'status_name': item['status_name'],
          });
        }

        setState(() {
          groupedDeposits = grouped;
          isLoading = false;
        });
      } else {
        throw Exception('โหลดข้อมูลไม่สำเร็จ');
      }
    } catch (e) {
      print('Error fetching: $e');
      setState(() => isLoading = false);
    }
  }

  String formatDateOnlyTH(DateTime date) {
    const months = [
      '',
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    return '${date.day} ${months[date.month]} ${date.year + 543}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HistoryAppBar(),
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : groupedDeposits.isEmpty
                  ? const Center(child: Text('ไม่มีข้อมูลการฝากถอน'))
                  : GroupedDepositList(groupedDeposits: groupedDeposits),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HistoryAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: const Text(
        'ประวัติการฝากถอน',
        style: TextStyle(color: Colors.white),
      ),
      centerTitle: true,
      backgroundColor: Colors.blue[700],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class GroupedDepositList extends StatelessWidget {
  final Map<String, List<Map<String, dynamic>>> groupedDeposits;

  const GroupedDepositList({super.key, required this.groupedDeposits});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: groupedDeposits.entries.map((entry) {
        final dateLabel = entry.key;
        final transactions = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                dateLabel,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
            ),
            ...transactions.map((tx) => DepositCard(
              time: tx['time'],
              amount: (tx['amount'] as num).toDouble(),
              status: tx['status_name'] ?? 'ไม่ระบุ',
              idStatus: tx['id_status'] ?? '',
            )),
            const SizedBox(height: 24),
          ],
        );
      }).toList(),
    );
  }
}

class DepositCard extends StatelessWidget {
  final String time;
  final double amount;
  final String status;
  final String idStatus;

  const DepositCard({
    super.key,
    required this.time,
    required this.amount,
    required this.status,
    required this.idStatus,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    switch (idStatus) {
      case 'S001':
        bgColor = Colors.green[600]!;
        break;
      case 'S002':
        bgColor = Colors.orange[600]!;
        break;
      case 'S003':
        bgColor = Colors.red[600]!;
        break;
      default:
        bgColor = Colors.grey;
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_downward, color: Colors.blue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ฝาก ฿${amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'เวลา $time',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            )
          ],
        ),
      ),
    );
  }
}
