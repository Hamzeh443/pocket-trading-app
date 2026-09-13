import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(const PocketTradingApp());
}

class Candle {
  final double open;
  final double high;
  final double low;
  final double close;

  Candle({required this.open, required this.high, required this.low, required this.close});
}

class PocketTradingApp extends StatelessWidget {
  const PocketTradingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pocket Trading Pro',
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
  String _signal = 'NEUTRAL';
  Color _signalColor = Colors.grey;

  String _timeframe = '1M';
  double _tradeAmount = 10.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initCandles();
    _startLiveFeed();
  }

  void _initCandles() {
    double base = 1.0850;
    final rand = Random();
    for (int i = 0; i < 15; i++) {
      double o = base + (rand.nextDouble() - 0.5) * 0.002;
      double c = o + (rand.nextDouble() - 0.48) * 0.002;
      double h = max(o, c) + rand.nextDouble() * 0.001;
      double l = min(o, c) - rand.nextDouble() * 0.001;
      _candles.add(Candle(open: o, high: h, low: l, close: c));
      _closePrices.add(c);
      base = c;
    }
    _currentPrice = _candles.last.close;
  }

  void _startLiveFeed() {
    final rand = Random();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) return;
      setState(() {
        double lastClose = _candles.isNotEmpty ? _candles.last.close : 1.0850;
        double o = lastClose;
        double c = o + (rand.nextDouble() - 0.49) * 0.0015;
        double h = max(o, c) + rand.nextDouble() * 0.0008;
        double l = min(o, c) - rand.nextDouble() * 0.0008;

        _currentPrice = double.parse(c.toStringAsFixed(5));
        _candles.add(Candle(open: o, high: h, low: l, close: c));
        _closePrices.add(c);

        if (_candles.length > 20) {
          _candles.removeAt(0);
          _closePrices.removeAt(0);
        }

        _calculateRSI();
      });
    });
  }

  void _calculateRSI() {
    if (_closePrices.length < 5) return;
    double gains = 0, losses = 0;
    for (int i = 1; i < _closePrices.length; i++) {
      double diff = _closePrices[i] - _closePrices[i - 1];
      if (diff >= 0) gains += diff; else losses += diff.abs();
    }
    if (losses == 0) {
      _rsi = 100;
    } else {
      double rs = gains / losses;
      _rsi = double.parse((100 - (100 / (1 + rs))).toStringAsFixed(2));
    }

    if (_rsi >= 70) {
      _signal = 'STRONG SELL (OVERBOUGHT)';
      _signalColor = Colors.redAccent;
    } else if (_rsi <= 30) {
      _signal = 'STRONG BUY (OVERSOLD)';
      _signalColor = Colors.greenAccent;
    } else {
      _signal = 'NEUTRAL / HOLD';
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
                  _candles.clear();
                  _closePrices.clear();
                  _initCandles();
                });
              }
            },
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Center(child: Text('\$$_currentPrice', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))),
          )
        ],
      ),
      body: Column(
        children: [
          // Timeframe selector
          Container(
            color: const Color(0xFF151922),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['1M', '5M', '15M', '1H'].map((tf) {
                bool selected = _timeframe == tf;
                return GestureDetector(
                  onTap: () => setState(() => _timeframe = tf),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? Colors.blueAccent : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(tf, style: TextStyle(color: selected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Candlestick Chart Area
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF151922), borderRadius: BorderRadius.circular(12)),
              child: CustomPaint(
                size: Size.infinite,
                painter: CandlestickPainter(_candles),
              ),
            ),
          ),

          // RSI Indicator Widget
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF151922), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('RSI Indicator (14)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('$_rsi', style: TextStyle(color: _signalColor, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: _rsi / 100, backgroundColor: Colors.grey[800], color: _signalColor),
                const SizedBox(height: 8),
                Text(_signal, style: TextStyle(color: _signalColor, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),

          // Trading Control Panel
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.vertical(16)),
                    onPressed: () {},
                    child: const Text('CALL / BUY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.vertical(16)),
                    onPressed: () {},
                    child: const Text('PUT / SELL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class CandlestickPainter extends CustomPainter {
  final List<Candle> candles;
  CandlestickPainter(this.candles);

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
      Paint paint = Paint()..color = isGreen ? Colors.greenAccent : Colors.redAccent..strokeWidth = 1.5;

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
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
