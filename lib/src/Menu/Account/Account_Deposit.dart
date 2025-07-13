import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mobile_app/constants.dart' as config;

class Account_Deposit extends StatefulWidget {
  const Account_Deposit({super.key});

  @override
  State<Account_Deposit> createState() => _Account_DepositState();
}

class _Account_DepositState extends State<Account_Deposit> {
  int total = 0;
  List<Map<String, dynamic>> yearlyData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDepositData();
  }

  Future<void> fetchDepositData() async {
    try {
      final response = await http.get(Uri.parse('${config.apiUrl}/account'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          total = data['total'].toInt();
          yearlyData = List<Map<String, dynamic>>.from(data['yearly']);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatNumber(num value) {
    return value.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FA),
      appBar: AppBar(
        title: const Text('ยอดเงินประจำปี'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20), // ขยับขวา 30px
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            color: Colors.white,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTotalCard(),
            const SizedBox(height: 20),
            _buildYearlyList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 6),
          )
        ],
      ),
      child: Column(
        children: [
          const Text(
            'ยอดรวมทั้งหมด',
            style: TextStyle(
              fontSize: 18,
              color: Colors.blueGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${formatNumber(total)} ฿',
            style: const TextStyle(
              fontSize: 40,
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearlyList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'รายละเอียดรายปี',
          style: TextStyle(
            fontSize: 16,
            color: Colors.blueGrey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...yearlyData.map(
              (entry) => Card(
            color: Colors.white,
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.blue),
              title: Text(
                'ปี ${entry['year_ad']}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: Text(
                '${formatNumber(entry['total_amount'])} ฿',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
