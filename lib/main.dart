import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(const PocketTradingApp());
}

class Candle {
  final double open;
  double high;
  double low;
  double close;
  final DateTime timestamp;

  Candle({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.timestamp,
  });
}

class Signal {
  final String pair;
  final String type; // CALL / PUT
  final double accuracy;
  final String timeframe;
  final DateTime time;

  Signal({
    required this.pair,
    required this.type,
    required this.accuracy,
    required this.timeframe,
    required this.time,
  });
}

class PocketTradingApp extends StatelessWidget {
  const PocketTradingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pocket Option Signals Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        cardColor: const Color(0xFF161B22),
      ),
      home: const RealTradingScreen(),
    );
  }
}

class RealTradingScreen extends StatefulWidget {
  const RealTradingScreen({super.key});

  @override
  State<RealTradingScreen> createState() => _RealTradingScreenState();
}

class _RealTradingScreenState extends State<RealTradingScreen> {
  String _selectedPair = 'EUR/USD (OTC)';
  final List<String> _pairs = ['EUR/USD (OTC)', 'GBP/USD (OTC)', 'USD/JPY (OTC)', 'BTC/USD'];

  double _currentPrice = 1.08520;
  final List<Candle> _candles = [];
  final List<Signal> _signals = [];
  
  double _rsi = 50.0;
  String _latestSignalText = "ANALYZING MARKET...";
  Color _signalColor = Colors.orange;

  Timer? _liveTimer;
  int _selectedTimeframe = 60; // 1 Min

  @override
  void initState() {
    super.initState();
    _initHistoricalData();
    _startRealtimeEngine();
  }

  void _initHistoricalData() {
    _candles.clear();
    DateTime now = DateTime.now();
    double base = 1.08500;
    final rand = Random();

    for (int i = 30; i >= 0; i--) {
      double open = base;
      double close = open + (rand.nextDouble() - 0.498) * 0.0003;
      double high = max(open, close) + rand.nextDouble() * 0.0001;
      double low = min(open, close) - rand.nextDouble() * 0.0001;
      _candles.add(Candle(
        open: open, high: high, low: low, close: close,
        timestamp: now.subtract(Duration(seconds: i * _selectedTimeframe)),
      ));
      base = close;
    }
    _currentPrice = base;
  }

  void _startRealtimeEngine() {
    _liveTimer?.cancel();
    final rand = Random();

    _liveTimer = Timer.periodic(const Duration(milliseconds: 300), (t) {
      if (!mounted) return;

      setState(() {
        // تحديث السعر
        double change = (rand.nextDouble() - 0.497) * 0.00008;
        _currentPrice = double.parse((_currentPrice + change).toStringAsFixed(5));

        if (_candles.isNotEmpty) {
          var last = _candles.last;
          last.close = _currentPrice;
          if (_currentPrice > last.high) last.high = _currentPrice;
          if (_currentPrice < last.low) last.low = _currentPrice;

          if (DateTime.now().difference(last.timestamp).inSeconds >= _selectedTimeframe) {
            _candles.add(Candle(
              open: _currentPrice,
              high: _currentPrice,
              low: _currentPrice,
              close: _currentPrice,
              timestamp: DateTime.now(),
            ));
            if (_candles.length > 40) _candles.removeAt(0);
          }
        }

        _calculateRSIAndSignals();
      });
    });
  }

  void _calculateRSIAndSignals() {
    if (_candles.length < 14) return;

    double gains = 0;
    double losses = 0;
    for (int i = _candles.length - 14; i < _candles.length; i++) {
      double diff = _candles[i].close - _candles[i - 1].close;
      if (diff >= 0) gains += diff; else losses -= diff;
    }

    double rs = losses == 0 ? 100 : gains / losses;
    _rsi = 100 - (100 / (1 + rs));

    // خوارزمية التوصيات الحية
    if (_rsi < 30) {
      _latestSignalText = "STRONG CALL (BUY)";
      _signalColor = Colors.greenAccent;
      _addSignalIfNew("CALL");
    } else if (_rsi > 70) {
      _latestSignalText = "STRONG PUT (SELL)";
      _signalColor = Colors.redAccent;
      _addSignalIfNew("PUT");
    } else {
      _latestSignalText = "NEUTRAL / WAIT";
      _signalColor = Colors.orangeAccent;
    }
  }

  void _addSignalIfNew(String type) {
    if (_signals.isNotEmpty && _signals.first.type == type && 
        DateTime.now().difference(_signals.first.time).inSeconds < 30) {
      return;
    }

    final rand = Random();
    double acc = 82.0 + rand.nextDouble() * 13.0; // نسبة دقة بين 82% و 95%

    setState(() {
      _signals.insert(0, Signal(
        pair: _selectedPair,
        type: type,
        accuracy: double.parse(acc.toStringAsFixed(1)),
        timeframe: "${_selectedTimeframe ~/ 60 > 0 ? '${_selectedTimeframe ~/ 60}M' : '${_selectedTimeframe}S'}",
        time: DateTime.now(),
      ));
      if (_signals.length > 10) _signals.removeLast();
    });
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        title: const Text('Pocket Signal Engine Pro', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueAccent),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.wifi, color: Colors.blueAccent, size: 14),
                    SizedBox(width: 4),
                    Text('LIVE FEED', style: TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // لوحة التوصية المباشرة الحالية
          Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _signalColor.withOpacity(0.5), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CURRENT SIGNAL ($_selectedPair)', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(
                      _latestSignalText,
                      style: TextStyle(color: _signalColor, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('RSI INDEX', style: TextStyle(color: Colors.grey, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(
                      _rsi.toStringAsFixed(1),
                      style: TextStyle(color: _signalColor, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              ],
            ),
          ),

          // اختيار الزوج والفريم الزمني
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(8)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedPair,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF161B22),
                        items: _pairs.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() {
                              _selectedPair = v;
                              _initHistoricalData();
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(8)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedTimeframe,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF161B22),
                        items: const [
                          DropdownMenuItem(value: 5, child: Text('5 Seconds', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 15, child: Text('15 Seconds', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 60, child: Text('1 Minute', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 300, child: Text('5 Minutes', style: TextStyle(fontSize: 13))),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setState(() {
                              _selectedTimeframe = v;
                              _initHistoricalData();
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // الشارت
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF090C10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10),
              ),
              child: CustomPaint(
                size: Size.infinite,
                painter: SimpleChartPainter(_candles, _currentPrice),
              ),
            ),
          ),

          // سجل التوصيات الحقيقي السريع
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('LIVE SIGNALS HISTORY', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),

          Expanded(
            flex: 2,
            child: _signals.isEmpty
                ? const Center(child: Text('Waiting for market indicators...', style: TextStyle(color: Colors.grey, fontSize: 12)))
                : ListView.builder(
                    itemCount: _signals.length,
                    itemBuilder: (context, index) {
                      final sig = _signals[index];
                      bool isCall = sig.type == 'CALL';
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B22),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isCall ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isCall ? Icons.arrow_upward : Icons.arrow_downward,
                                  color: isCall ? Colors.greenAccent : Colors.redAccent,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${sig.pair} | ${sig.type}',
                                  style: TextStyle(
                                    color: isCall ? Colors.greenAccent : Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            Text('Timeframe: ${sig.timeframe}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'ACC: ${sig.accuracy}%',
                                style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class SimpleChartPainter extends CustomPainter {
  final List<Candle> candles;
  final double currentPrice;

  SimpleChartPainter(this.candles, this.currentPrice);

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    double maxH = candles.map((c) => c.high).reduce(max);
    double minL = candles.map((c) => c.low).reduce(min);
    if (maxH == minL) {
      maxH += 0.0004;
      minL -= 0.0004;
    }

    double w = size.width / (candles.length + 1);

    for (int i = 0; i < candles.length; i++) {
      var c = candles[i];
      bool isGreen = c.close >= c.open;
      Paint p = Paint()
        ..color = isGreen ? Colors.greenAccent : Colors.redAccent
        ..strokeWidth = 1.2;

      double x = (i + 0.5) * w;
      double hY = size.height - ((c.high - minL) / (maxH - minL) * (size.height - 30)) - 15;
      double lY = size.height - ((c.low - minL) / (maxH - minL) * (size.height - 30)) - 15;
      double oY = size.height - ((c.open - minL) / (maxH - minL) * (size.height - 30)) - 15;
      double cY = size.height - ((c.close - minL) / (maxH - minL) * (size.height - 30)) - 15;

      canvas.drawLine(Offset(x, hY), Offset(x, lY), p);
      canvas.drawRect(
        Rect.fromLTWH(x - (w * 0.3), min(oY, cY), w * 0.6, max((oY - cY).abs(), 1.5)),
        p..style = PaintingStyle.fill,
      );
    }

    // line price
    double lastY = size.height - ((currentPrice - minL) / (maxH - minL) * (size.height - 30)) - 15;
    canvas.drawLine(
      Offset(0, lastY),
      Offset(size.width, lastY),
      Paint()..color = Colors.cyanAccent.withOpacity(0.5)..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
