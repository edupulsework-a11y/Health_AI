import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../../core/api_keys.dart';
import '../../core/theme.dart';

class MaternityScreen extends StatefulWidget {
  const MaternityScreen({super.key});

  @override
  State<MaternityScreen> createState() => _MaternityScreenState();
}

class _MaternityScreenState extends State<MaternityScreen> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  int _currentWeek = 12;
  bool _isDelivered = false;
  String _aiAdvice = "Setting up your tracker...";

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    // Logic to fetch current pregnancy week from Supabase
    setState(() {
      _aiAdvice = "Baby is now the size of a Lime! Lungs and kidneys are developing rapidly.";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maternity & Baby Bloom'),
        backgroundColor: Colors.pink[50],
        foregroundColor: Colors.pink[800],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pregnancy Hero Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pink[400]!, Colors.pink[200]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.pink.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pregnancy Journey', style: TextStyle(color: Colors.white, fontSize: 16)),
                          Text('Week $_currentWeek', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white24,
                        child: Text('🤰', style: TextStyle(fontSize: 30)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: _currentWeek / 40,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 12,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            // AI Insights
            const Text('AI Pregnancy Guide', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.pink[100]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.pink),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(_aiAdvice, style: const TextStyle(fontSize: 14, height: 1.5)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Daily Logs
            const Text('Health Logs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildLogTile('Weight', '65 kg', Icons.monitor_weight_outlined),
                const SizedBox(width: 12),
                _buildLogTile('BP', '110/70', Icons.favorite_border),
              ],
            ),
            const SizedBox(height: 30),
            
            // Post-Delivery Section Toggle
            ListTile(
              onTap: () => setState(() => _isDelivered = !_isDelivered),
              tileColor: Colors.blue[50],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              leading: const Icon(Icons.child_friendly_outlined, color: Colors.blue),
              title: const Text('Switch to Baby Tracking', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: Switch(
                value: _isDelivered,
                onChanged: (v) => setState(() => _isDelivered = v),
                activeColor: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogTile(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.pink[300]),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
