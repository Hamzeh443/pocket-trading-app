import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const PocketTradingApp());
}

class PocketTradingApp extends StatelessWidget {
  const PocketTradingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        cardColor: const Color(0xFF161B22),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<FlSpot> candleData = [];
  double currentPrice = 1.08520;
  double rsiValue = 54.2;
  double ema12 = 1.08510;
  
  String tradeSignal = 'WAITING';
  bool isAutoTrading = false;
  
  double virtualBalance = 1000.0;
  int wins = 9;
  int losses = 3;

  final List<Map<String, dynamic>> recentTrades = [
    {'pair': 'EUR/USD', 'type': 'CALL', 'price': '1.08510', 'result': 'WIN', 'profit': '+$8.50'},
    {'pair': 'EUR/USD', 'type': 'PUT', 'price': '1.08535', 'result': 'WIN', 'profit': '+$8.50'},
    {'pair': 'EUR/USD', 'type': 'CALL', 'price': '1.08490', 'result': 'LOSS', 'profit': '-$10.00'},
  ];

  Timer? _ticker;
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    _startEngine();
  }

  void _startEngine() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _counter++;
        double change = (Random().nextDouble() - 0.495) * 0.00015;
        currentPrice += change;
        candleData.add(FlSpot(_counter.toDouble(), currentPrice));
        if (candleData.length > 25) candleData.removeAt(0);

        ema12 = currentPrice * 0.15 + ema12 * 0.85;

        if (_counter % 3 == 0) {
          rsiValue = 25 + Random().nextDouble() * 50;
          if (rsiValue > 68) {
            tradeSignal = 'PUT (بيع)';
          } else if (rsiValue < 32) {
            tradeSignal = 'CALL (شراء)';
          } else {
            tradeSignal = 'NEUTRAL (محياد)';
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int totalTrades = wins + losses;
    double winRate = (wins / totalTrades) * 100;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.bolt, color: Colors.cyanAccent),
            SizedBox(width: 8),
            Text('POCKET BOT PRO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isAutoTrading ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isAutoTrading ? Colors.green : Colors.red),
            ),
            child: Row(
              children: [
                CircleAvatar(radius: 4, backgroundColor: isAutoTrading ? Colors.greenAccent : Colors.redAccent),
                const SizedBox(width: 6),
                Text(isAutoTrading ? 'LIVE AUTO' : 'OFFLINE', style: TextStyle(color: isAutoTrading ? Colors.greenAccent : Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Switch(
            value: isAutoTrading,
            activeColor: Colors.cyanAccent,
            onChanged: (val) => setState(() => isAutoTrading = val),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                _buildStatCard('الرصيد التجريبي', '\$${virtualBalance.toStringAsFixed(2)}', Colors.white, Icons.account_balance_wallet),
                const SizedBox(width: 8),
                _buildStatCard('نسبة النجاح', '${winRate.toStringAsFixed(0)}%', Colors.greenAccent, Icons.pie_chart),
                const SizedBox(width: 8),
                _buildStatCard('الصفقات', '$wins / $losses', Colors.orangeAccent, Icons.show_chart),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('EUR/USD (OTC)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(currentPrice.toStringAsFixed(5), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('إشارة البوت: $tradeSignal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: tradeSignal.contains('CALL') ? Colors.greenAccent : (tradeSignal.contains('PUT') ? Colors.redAccent : Colors.grey))),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildBadge('RSI: ${rsiValue.toStringAsFixed(1)}', Colors.orange),
                          const SizedBox(width: 4),
                          _buildBadge('EMA: ${ema12.toStringAsFixed(5)}', Colors.purpleAccent),
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 250,
              padding: const EdgeInsets.only(right: 12, left: 4, top: 16, bottom: 8),
              decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(12)),
              child: candleData.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true, drawVerticalLine: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: candleData,
                            isCurved: true,
                            color: Colors.cyanAccent,
                            barWidth: 2.5,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(show: true, color: Colors.cyanAccent.withOpacity(0.08)),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('آخر صفقات البوت المحاكية', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                  const Divider(color: Colors.white10),
                  ...recentTrades.map((t) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${t['pair']} (${t['type']})', style: TextStyle(color: t['type'] == 'CALL' ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold)),
                        Text('Price: ${t['price']}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                        Text('${t['result']} (${t['profit']})', style: TextStyle(color: t['result'] == 'WIN' ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )).toList()
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String val, Color col, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: col),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: col)),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
