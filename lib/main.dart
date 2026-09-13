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
      title: 'Pocket Option Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF090C10),
        cardColor: const Color(0xFF161B22),
      ),
      home: const NativeTradingScreen(),
    );
  }
}

class NativeTradingScreen extends StatefulWidget {
  const NativeTradingScreen({super.key});

  @override
  State<NativeTradingScreen> createState() => _NativeTradingScreenState();
}

class _NativeTradingScreenState extends State<NativeTradingScreen> {
  String _selectedPair = 'EUR/USD (OTC)';
  final List<String> _pairs = ['EUR/USD (OTC)', 'GBP/USD (OTC)', 'USD/JPY (OTC)', 'BTC/USD'];

  double _currentPrice = 1.08500;
  final List<Candle> _candles = [];
  bool _isBotActive = false;

  int _selectedDuration = 60;
  double _tradeAmount = 50.0;
  double _balance = 1000.0;

  double _zoomLevel = 1.0;
  double _panOffset = 0.0;
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _initCandles();
    _startLivePriceEngine();
  }

  void _initCandles() {
    _candles.clear();
    DateTime now = DateTime.now();
    double price = _currentPrice;
    final rand = Random();

    for (int i = 40; i >= 0; i--) {
      double open = price;
      double close = open + (rand.nextDouble() - 0.49) * 0.0006;
      double high = max(open, close) + rand.nextDouble() * 0.0002;
      double low = min(open, close) - rand.nextDouble() * 0.0002;
      _candles.add(Candle(
        open: open, high: high, low: low, close: close,
        timestamp: now.subtract(Duration(seconds: i * 3))
      ));
      price = close;
    }
    _currentPrice = price;
  }

  void _startLivePriceEngine() {
    _tickTimer?.cancel();
    final rand = Random();
    
    // التحديث السريع جداً كل 200 ميلي ثانية لتحريك الشموع مثل Pocket Option تماماً
    _tickTimer = Timer.periodic(const Duration(milliseconds: 200), (t) {
      if (!mounted) return;
      
      setState(() {
        double delta = (rand.nextDouble() - 0.495) * 0.00015;
        _currentPrice = double.parse((_currentPrice + delta).toStringAsFixed(5));

        if (_candles.isNotEmpty) {
          var last = _candles.last;
          last.close = _currentPrice;
          if (_currentPrice > last.high) last.high = _currentPrice;
          if (_currentPrice < last.low) last.low = _currentPrice;

          // إنشاء شمعة جديدة كل 3 ثوانٍ
          if (DateTime.now().difference(last.timestamp).inSeconds >= 3) {
            _candles.add(Candle(
              open: _currentPrice,
              high: _currentPrice,
              low: _currentPrice,
              close: _currentPrice,
              timestamp: DateTime.now(),
            ));
            if (_candles.length > 60) _candles.removeAt(0);
          }
        }
      });
    });
  }

  void _executeTrade(String type) {
    if (_balance < _tradeAmount) return;

    setState(() {
      _balance -= _tradeAmount;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$type TRADE EXECUTED | \$${_tradeAmount.toStringAsFixed(0)} | ${_selectedDuration}s',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: type == 'BUY' ? Colors.green : Colors.red,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        title: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedPair,
            dropdownColor: const Color(0xFF161B22),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            items: _pairs.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedPair = val;
                  _initCandles();
                });
              }
            },
          ),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.greenAccent, size: 16),
                const SizedBox(width: 6),
                Text(
                  '\$${_balance.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF161B22),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('LIVE PRICE: ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(
                      '$_currentPrice',
                      style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text('AUTOBOT: ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    Switch(
                      value: _isBotActive,
                      activeColor: Colors.blueAccent,
                      onChanged: (v) => setState(() => _isBotActive = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: GestureDetector(
              onScaleUpdate: (details) {
                setState(() {
                  _zoomLevel = (_zoomLevel * details.scale).clamp(0.5, 3.0);
                  _panOffset += details.focalPointDelta.dx;
                });
              },
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E1117),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                ),
                child: ClipRect(
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: PocketChartPainter(_candles, _currentPrice, _zoomLevel, _panOffset),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF161B22),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TIME', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          DropdownButton<int>(
                            isExpanded: true,
                            value: _selectedDuration,
                            dropdownColor: const Color(0xFF161B22),
                            items: const [
                              DropdownMenuItem(value: 5, child: Text('5 sec')),
                              DropdownMenuItem(value: 15, child: Text('15 sec')),
                              DropdownMenuItem(value: 60, child: Text('1 min')),
                              DropdownMenuItem(value: 300, child: Text('5 min')),
                            ],
                            onChanged: (v) => setState(() => _selectedDuration = v!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('AMOUNT USD', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          DropdownButton<double>(
                            isExpanded: true,
                            value: _tradeAmount,
                            dropdownColor: const Color(0xFF161B22),
                            items: const [
                              DropdownMenuItem(value: 10.0, child: Text('\$10')),
                              DropdownMenuItem(value: 50.0, child: Text('\$50')),
                              DropdownMenuItem(value: 100.0, child: Text('\$100')),
                              DropdownMenuItem(value: 500.0, child: Text('\$500')),
                            ],
                            onChanged: (v) => setState(() => _tradeAmount = v!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E676),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _executeTrade('BUY'),
                        child: const Text('HIGHER / CALL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5252),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _executeTrade('SELL'),
                        child: const Text('LOWER / PUT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class PocketChartPainter extends CustomPainter {
  final List<Candle> candles;
  final double currentPrice;
  final double zoom;
  final double pan;

  PocketChartPainter(this.candles, this.currentPrice, this.zoom, this.pan);

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    double maxH = candles.map((c) => c.high).reduce(max);
    double minL = candles.map((c) => c.low).reduce(min);
    if (maxH == minL) maxH += 0.001;

    double baseWidth = (size.width / 25) * zoom;

    for (int i = 0; i < candles.length; i++) {
      var c = candles[i];
      bool isGreen = c.close >= c.open;
      Paint paint = Paint()
        ..color = isGreen ? const Color(0xFF00E676) : const Color(0xFFFF5252)
        ..strokeWidth = 1.5;

      double x = size.width - ((candles.length - i) * baseWidth) + pan;

      if (x < -20 || x > size.width + 20) continue;

      double highY = size.height - ((c.high - minL) / (maxH - minL) * (size.height - 40)) - 20;
      double lowY = size.height - ((c.low - minL) / (maxH - minL) * (size.height - 40)) - 20;
      double openY = size.height - ((c.open - minL) / (maxH - minL) * (size.height - 40)) - 20;
      double closeY = size.height - ((c.close - minL) / (maxH - minL) * (size.height - 40)) - 20;

      canvas.drawLine(Offset(x, highY), Offset(x, lowY), paint);

      double topY = min(openY, closeY);
      double bodyHeight = (openY - closeY).abs();
      if (bodyHeight < 2.0) bodyHeight = 2.0;

      canvas.drawRect(
        Rect.fromLTWH(x - (baseWidth * 0.35), topY, baseWidth * 0.7, bodyHeight),
        paint..style = PaintingStyle.fill,
      );
    }

    // رسم خط السعر المباشر
    double lastY = size.height - ((currentPrice - minL) / (maxH - minL) * (size.height - 40)) - 20;
    Paint linePaint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, lastY), Offset(size.width, lastY), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
