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
      theme: ThemeData.dark(),
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
  double currentPrice = 1.08500;
  double rsiValue = 50.0;
  String tradeSignal = 'WAITING';
  bool isAutoTrading = false;
  Timer? _ticker;
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    _startLiveStreamSim();
  }

  void _startLiveStreamSim() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _counter++;
        double change = (Random().nextDouble() - 0.49) * 0.0002;
        currentPrice += change;
        candleData.add(FlSpot(_counter.toDouble(), currentPrice));
        if (candleData.length > 20) candleData.removeAt(0);

        // حساب مؤشر RSI مبسط
        if (_counter % 3 == 0) {
          rsiValue = 30 + Random().nextDouble() * 40;
          if (rsiValue > 65) {
            tradeSignal = 'SELL (PUT)';
          } else if (rsiValue < 35) {
            tradeSignal = 'BUY (CALL)';
          } else {
            tradeSignal = 'NEUTRAL';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pocket Option Bot Live'),
        backgroundColor: Colors.black87,
        actions: [
          Switch(
            value: isAutoTrading,
            activeColor: Colors.greenAccent,
            onChanged: (val) {
              setState(() {
                isAutoTrading = val;
              });
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.grey[900],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('EUR/USD (OTC)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('Price: ${currentPrice.toStringAsFixed(5)}', style: const TextStyle(color: Colors.greenAccent)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('RSI: ${rsiValue.toStringAsFixed(1)}', style: const TextStyle(color: Colors.orangeAccent)),
                        Text('Signal: $tradeSignal', style: TextStyle(color: tradeSignal.contains('BUY') ? Colors.green : (tradeSignal.contains('SELL') ? Colors.red : Colors.grey), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            Container(
              height: 280,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade800),
              ),
              child: candleData.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true),
                        titlesData: const FlTitlesData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: candleData,
                            isCurved: true,
                            color: Colors.cyanAccent,
                            barWidth: 2,
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isAutoTrading ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isAutoTrading ? Colors.green : Colors.red),
              ),
              child: Text(
                isAutoTrading ? 'التداول الآلي مفعل: سيتم تنفيذ الصفقات فور ظهور الإشارة' : 'التداول الآلي متوقف',
                textAlign: TextAlign.center,
                style: TextStyle(color: isAutoTrading ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
    );
  }
}
