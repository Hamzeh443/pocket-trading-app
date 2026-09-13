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

class PocketTradingApp extends StatelessWidget {
  const PocketTradingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pocket Option Simulator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0E14),
        cardColor: const Color(0xFF151922),
      ),
      home: const ProDashboardScreen(),
    );
  }
}

class ProDashboardScreen extends StatefulWidget {
  const ProDashboardScreen({super.key});

  @override
  State<ProDashboardScreen> createState() => _ProDashboardScreenState();
}

class _ProDashboardScreenState extends State<ProDashboardScreen> {
  String _selectedPair = 'EUR/USD';
  final List<String> _pairs = ['EUR/USD', 'GBP/USD', 'USD/JPY', 'BTC/USD', 'ETH/USD'];
  
  double _currentPrice = 1.0850;
  final List<Candle> _candles = [];
  final List<double> _closePrices = [];
  double _rsi = 50.0;
  
  // Recommendations: 'BUY', 'SELL', or 'NONE'
  String _activeSignal = 'NONE';
  
  int _timeframeSeconds = 60; // Default 1M = 60s
  int _candleSecondsLeft = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initHistory();
    _startPocketOptionEngine();
  }

  void _initHistory() {
    _candles.clear();
    _closePrices.clear();
    double base = 1.0850;
    final rand = Random();
    DateTime now = DateTime.now();

    for (int i = 10; i >= 1; i--) {
      double o = base + (rand.nextDouble() - 0.5) * 0.0015;
      double c = o + (rand.nextDouble() - 0.49) * 0.0015;
      double h = max(o, c) + rand.nextDouble() * 0.0005;
      double l = min(o, c) - rand.nextDouble() * 0.0005;
      DateTime t = now.subtract(Duration(seconds: i * _timeframeSeconds));
      _candles.add(Candle(open: o, high: h, low: l, close: c, timestamp: t));
      _closePrices.add(c);
      base = c;
    }
    _currentPrice = _candles.last.close;
    _candleSecondsLeft = _timeframeSeconds;
  }

  void _startPocketOptionEngine() {
    final rand = Random();
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _candleSecondsLeft--;

        // Simulated price tick inside current candle
        double delta = (rand.nextDouble() - 0.49) * 0.0003;
        _currentPrice = double.parse((_currentPrice + delta).toStringAsFixed(5));

        if (_candles.isNotEmpty) {
          var currentCandle = _candles.last;
          currentCandle.close = _currentPrice;
          if (_currentPrice > currentCandle.high) currentCandle.high = _currentPrice;
          if (_currentPrice < currentCandle.low) currentCandle.low = _currentPrice;
        }

        _calculateRSIAndSignals();

        // Candle Expiry / New Candle Creation
        if (_candleSecondsLeft <= 0) {
          _candleSecondsLeft = _timeframeSeconds;
          _closePrices.add(_currentPrice);
          if (_closePrices.length > 30) _closePrices.removeAt(0);

          // Open New Candle
          _candles.add(Candle(
            open: _currentPrice,
            high: _currentPrice,
            low: _currentPrice,
            close: _currentPrice,
            timestamp: DateTime.now(),
          ));

          if (_candles.length > 20) {
            _candles.removeAt(0);
          }
        }
      });
    });
  }

  void _calculateRSIAndSignals() {
    List<double> prices = List.from(_closePrices)..add(_currentPrice);
    if (prices.length < 5) return;

    double gains = 0, losses = 0;
    for (int i = 1; i < prices.length; i++) {
      double diff = prices[i] - prices[i - 1];
      if (diff >= 0) gains += diff; else losses += diff.abs();
    }

    if (losses == 0) {
      _rsi = 100;
    } else {
      double rs = gains / losses;
      _rsi = double.parse((100 - (100 / (1 + rs))).toStringAsFixed(2));
    }

    if (_rsi <= 30) {
      _activeSignal = 'BUY';
    } else if (_rsi >= 70) {
      _activeSignal = 'SELL';
    } else {
      _activeSignal = 'NONE';
    }
  }

  void _setTimeframe(int seconds) {
    setState(() {
      _timeframeSeconds = seconds;
      _initHistory();
    });
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
        backgroundColor: const Color(0xFF151922),
        title: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedPair,
            dropdownColor: const Color(0xFF151922),
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            items: _pairs.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedPair = val;
                  _initHistory();
                });
              }
            },
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blueAccent),
            ),
            child: Center(
              child: Text(
                '\$$_currentPrice',
                style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // Timeframe Bar & Candle Timer
          Container(
            color: const Color(0xFF151922),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _tfButton('S10', 10),
                    const SizedBox(width: 6),
                    _tfButton('M1', 60),
                    const SizedBox(width: 6),
                    _tfButton('M5', 300),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: Text(
                    'Timer: ${_candleSecondsLeft}s',
                    style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
          ),
          
          // Candlestick Chart Area with Signals
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF151922),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: CustomPaint(
                size: Size.infinite,
                painter: CandlestickPainter(_candles, _activeSignal),
              ),
            ),
          ),

          // RSI Indicator Widget
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF151922),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('RSI Indicator (14)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(
                      '$_rsi',
                      style: TextStyle(
                        color: _rsi >= 70 ? Colors.redAccent : (_rsi <= 30 ? Colors.greenAccent : Colors.amber),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _rsi / 100,
                  backgroundColor: Colors.grey[800],
                  color: _rsi >= 70 ? Colors.redAccent : (_rsi <= 30 ? Colors.greenAccent : Colors.amber),
                ),
              ],
            ),
          ),

          // Trading Control Panel (Pocket Option style)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.arrow_upward, color: Colors.white),
                    label: const Text('HIGHER / CALL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.arrow_downward, color: Colors.white),
                    label: const Text('LOWER / PUT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _tfButton(String label, int seconds) {
    bool selected = _timeframeSeconds == seconds;
    return GestureDetector(
      onTap: () => _setTimeframe(seconds),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.blueAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? Colors.blueAccent : Colors.grey[700]!),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }
}

class CandlestickPainter extends CustomPainter {
  final List<Candle> candles;
  final String activeSignal;

  CandlestickPainter(this.candles, this.activeSignal);

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    double maxH = candles.map((c) => c.high).reduce(max);
    double minL = candles.map((c) => c.low).reduce(min);
    if (maxH == minL) maxH += 0.001;

    double candleWidth = size.width / candles.length;

    for (int i = 0; i < candles.length; i++) {
      var c = candles[i];
      bool isGreen = c.close >= c.open;
      Paint paint = Paint()
        ..color = isGreen ? const Color(0xFF00E676) : const Color(0xFFFF5252)
        ..strokeWidth = 1.5;

      double x = i * candleWidth + (candleWidth / 2);

      double highY = size.height - ((c.high - minL) / (maxH - minL) * size.height);
      double lowY = size.height - ((c.low - minL) / (maxH - minL) * size.height);
      double openY = size.height - ((c.open - minL) / (maxH - minL) * size.height);
      double closeY = size.height - ((c.close - minL) / (maxH - minL) * size.height);

      // Draw Wick
      canvas.drawLine(Offset(x, highY), Offset(x, lowY), paint);

      // Draw Body
      double topY = min(openY, closeY);
      double bodyHeight = (openY - closeY).abs();
      if (bodyHeight < 2) bodyHeight = 2;

      canvas.drawRect(
        Rect.fromLTWH(x - (candleWidth * 0.3), topY, candleWidth * 0.6, bodyHeight),
        paint..style = PaintingStyle.fill,
      );

      // Draw Signal Arrow on the last active candle
      if (i == candles.length - 1 && activeSignal != 'NONE') {
        Paint arrowPaint = Paint()
          ..color = activeSignal == 'BUY' ? Colors.greenAccent : Colors.redAccent
          ..style = PaintingStyle.fill;

        Path path = Path();
        if (activeSignal == 'BUY') {
          // Green Up Arrow below candle low
          double arrowY = lowY + 18;
          path.moveTo(x, arrowY - 12);
          path.lineTo(x - 8, arrowY);
          path.lineTo(x + 8, arrowY);
        } else {
          // Red Down Arrow above candle high
          double arrowY = highY - 18;
          path.moveTo(x, arrowY + 12);
          path.lineTo(x - 8, arrowY);
          path.lineTo(x + 8, arrowY);
        }
        path.close();
        canvas.drawPath(path, arrowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
