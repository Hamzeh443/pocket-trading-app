import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(const PocketTradingApp());
}

class PocketTradingApp extends StatelessWidget {
  const PocketTradingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pocket Trading Bot',
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
  double _currentPrice = 1.0850;
  final List<double> _priceHistory = [];
  double _rsi = 50.0;
  String _signal = 'NEUTRAL';
  Color _signalColor = Colors.grey;
  bool _isAutoBotActive = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startPriceSimulation();
  }

  void _startPriceSimulation() {
    final random = Random();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) return;
      setState(() {
        double delta = (random.nextDouble() - 0.49) * 0.0015;
        _currentPrice = double.parse((_currentPrice + delta).toStringAsFixed(5));
        _priceHistory.add(_currentPrice);
        if (_priceHistory.length > 20) {
          _priceHistory.removeAt(0);
        }
        _calculateRSI();
      });
    });
  }

  void _calculateRSI() {
    if (_priceHistory.length < 5) return;
    
    double gains = 0;
    double losses = 0;

    for (int i = 1; i < _priceHistory.length; i++) {
      double diff = _priceHistory[i] - _priceHistory[i - 1];
      if (diff >= 0) {
        gains += diff;
      } else {
        losses += diff.abs();
      }
    }

    if (losses == 0) {
      _rsi = 100;
    } else {
      double rs = gains / losses;
      _rsi = double.parse((100 - (100 / (1 + rs))).toStringAsFixed(2));
    }

    if (_rsi >= 70) {
      _signal = 'SELL (OVERBOUGHT)';
      _signalColor = Colors.redAccent;
    } else if (_rsi <= 30) {
      _signal = 'BUY (OVERSOLD)';
      _signalColor = Colors.greenAccent;
    } else {
      _signal = 'HOLD (NEUTRAL)';
      _signalColor = Colors.amber;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pocket Trading Bot', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF161B22),
        actions: [
          Row(
            children: [
              const Text('Bot Status: ', style: TextStyle(fontSize: 12)),
              Switch(
                value: _isAutoBotActive,
                activeColor: Colors.greenAccent,
                onChanged: (val) {
                  setState(() {
                    _isAutoBotActive = val;
                  });
                },
              ),
            ],
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('EUR/USD Live Price', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text('\$$_currentPrice', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('RSI (14)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('$_rsi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _signalColor)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _rsi / 100,
                      backgroundColor: Colors.grey[800],
                      color: _signalColor,
                      minHeight: 8,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: _signalColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _signalColor),
                      ),
                      child: Text(
                        'SIGNAL: $_signal',
                        style: TextStyle(color: _signalColor, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
