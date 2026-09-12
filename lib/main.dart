import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

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
  final List<double> prices = [];
  double currentPrice = 1.08520;
  double rsiValue = 54.2;
  String tradeSignal = 'WAITING';
  bool isAutoTrading = false;
  
  double virtualBalance = 1000.0;
  int wins = 9;
  int losses = 3;

  final List<Map<String, String>> recentTrades = [
    {'pair': 'EUR/USD', 'type': 'CALL', 'price': '1.08510', 'result': 'WIN', 'profit': '+$8.50'},
    {'pair': 'EUR/USD', 'type': 'PUT', 'price': '1.08535', 'result': 'WIN', 'profit': '+$8.50'},
    {'pair': 'EUR/USD', 'type': 'CALL', 'price': '1.08490', 'result': 'LOSS', 'profit': '-$10.00'},
  ];

  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _startEngine();
  }

  void _startEngine() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        double change = (Random().nextDouble() - 0.495) * 0.00015;
        currentPrice += change;
        prices.add(currentPrice);
        if (prices.length > 30) prices.removeAt(0);

        if (prices.length % 3 == 0) {
          rsiValue = 25 + Random().nextDouble() * 50;
          if (rsiValue > 68) {
            tradeSignal = 'PUT (بيع)';
          } else if (rsiValue < 32) {
            tradeSignal = 'CALL (شراء)';
          } else {
            tradeSignal = 'NEUTRAL (محايد)';
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
    double winRate = totalTrades > 0 ? (wins / totalTrades) * 100 : 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        title: const Text('POCKET BOT PRO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.cyanAccent)),
        actions: [
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
                _buildStatCard('الرصيد', '\$${virtualBalance.toStringAsFixed(2)}', Colors.white),
                const SizedBox(width: 8),
                _buildStatCard('النجاح', '${winRate.toStringAsFixed(0)}%', Colors.greenAccent),
                const SizedBox(width: 8),
                _buildStatCard('الصفقات', '$wins / $losses', Colors.orangeAccent),
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
                      Text(currentPrice.toStringAsFixed(5), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(tradeSignal, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: tradeSignal.contains('CALL') ? Colors.greenAccent : (tradeSignal.contains('PUT') ? Colors.redAccent : Colors.grey))),
                      Text('RSI: ${rsiValue.toStringAsFixed(1)}', style: const TextStyle(color: Colors.orange, fontSize: 11)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(12)),
              child: prices.length < 2
                  ? const Center(child: CircularProgressIndicator())
                  : CustomPaint(
                      painter: ChartPainter(prices),
                    ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('آخر صفقات محاكاة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                  const Divider(color: Colors.white10),
                  ...recentTrades.map((t) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${t['pair']} (${t['type']})', style: TextStyle(color: t['type'] == 'CALL' ? Colors.greenAccent : Colors.redAccent, fontSize: 12)),
                        Text('${t['result']} (${t['profit']})', style: TextStyle(color: t['result'] == 'WIN' ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
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

  Widget _buildStatCard(String title, String val, Color col) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: col)),
          ],
        ),
      ),
    );
  }
}

class ChartPainter extends CustomPainter {
  final List<double> prices;
  ChartPainter(this.prices);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    double minP = prices.reduce(min);
    double maxP = prices.reduce(max);
    if (minP == maxP) maxP += 0.0001;

    final path = Path();
    double dx = size.width / (prices.length - 1);

    for (int i = 0; i < prices.length; i++) {
      double x = i * dx;
      double y = size.height - ((prices[i] - minP) / (maxP - minP) * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
