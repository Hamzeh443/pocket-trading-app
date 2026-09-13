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

  Timer? _tickTimer;
  DateTime _lastCandleTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initCandles();
    _startLivePriceEngine();
  }

  void _initCandles() {
    _candles.clear();
    DateTime now = DateTime.now();
    double price = 1.08500;
    final rand = Random();

    for (int i = 30; i >= 0; i--) {
      double open = price;
      double close = open + (rand.nextDouble() - 0.49) * 0.0004;
      double high = max(open, close) + rand.nextDouble() * 0.0002;
      double low = min(open, close) - rand.nextDouble() * 0.0002;
      _candles.add(Candle(
        open: open, high: high, low: low, close: close,
        timestamp: now.subtract(Duration(seconds: i * 2))
      ));
      price = close;
    }
    _currentPrice = price;
    _lastCandleTime = DateTime.now();
  }

  void _startLivePriceEngine() {
    _tickTimer?.cancel();
    final rand = Random();
    
    // تحديث سريع جداً كل 100 ميلي ثانية لإجبار النقطة والشموع على الحركة مستمرة
    _tickTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) return;
      
      setState(() {
        double delta = (rand.nextDouble() - 0.495) * 0.00012;
        _currentPrice = double.parse((_currentPrice + delta).toStringAsFixed(5));

        if (_candles.isNotEmpty) {
          var last = _candles.last;
          last.close = _currentPrice;
          if (_currentPrice > last.high) last.high = _currentPrice;
          if (_currentPrice < last.low) last.low = _currentPrice;

          // إضافة شمعة جديدة كل ثانيتين
          if (DateTime.now().difference(_lastCandleTime).inSeconds >= 2) {
            _candles.add(Candle(
              open: _currentPrice,
              high: _currentPrice,
              low: _currentPrice,
              close: _currentPrice,
              timestamp: DateTime.now(),
            ));
            _lastCandleTime = DateTime.now();
            if (_candles.length > 40) _candles.removeAt(0);
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
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0E1117),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10),
              ),
              child: CustomPaint(
                size: Size.infinite,
                painter: PocketChartPainter(_candles, _currentPrice),
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

  PocketChartPainter(this.candles, this.currentPrice);

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    double maxH = candles.map((c) => c.high).reduce(max);
    double minL = candles.map((c) => c.low).reduce(min);
    if (maxH == minL) {
      maxH += 0.0005;
      minL -= 0.0005;
    }

    double candleWidth = size.width / (candles.length + 2);

    for (int i = 0; i < candles.length; i++) {
      var c = candles[i];
      bool isGreen = c.close >= c.open;
      Paint candlePaint = Paint()
        ..color = isGreen ? const Color(0xFF00E676) : const Color(0xFFFF5252)
        ..strokeWidth = 1.5;

      double x = (i + 1) * candleWidth;

      double highY = size.height - ((c.high - minL) / (maxH - minL) * (size.height - 60)) - 30;
      double lowY = size.height - ((c.low - minL) / (maxH - minL) * (size.height - 60)) - 30;
      double openY = size.height - ((c.open - minL) / (maxH - minL) * (size.height - 60)) - 30;
      double closeY = size.height - ((c.close - minL) / (maxH - minL) * (size.height - 60)) - 30;

      // رسم فتيل الشمعة
      canvas.drawLine(Offset(x, highY), Offset(x, lowY), candlePaint);

      // رسم جسم الشمعة
      double topY = min(openY, closeY);
      double bodyHeight = (openY - closeY).abs();
      if (bodyHeight < 2.0) bodyHeight = 2.0;

      canvas.drawRect(
        Rect.fromLTWH(x - (candleWidth * 0.35), topY, candleWidth * 0.7, bodyHeight),
        candlePaint..style = PaintingStyle.fill,
      );
    }

    // رسم السعر والنقطة المتحركة المباشرة
    double lastY = size.height - ((currentPrice - minL) / (maxH - minL) * (size.height - 60)) - 30;
    
    // خط السعر الأفقي
    Paint linePaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.6)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, lastY), Offset(size.width, lastY), linePaint);

    // النقطة المباشرة المضيئة في آخر السعر
    Paint dotPaint = Paint()..color = Colors.cyanAccent;
    Paint dotGlow = Paint()..color = Colors.cyanAccent.withOpacity(0.3);
    
    double lastX = candles.length * candleWidth;
    canvas.drawCircle(Offset(lastX, lastY), 8, dotGlow);
    canvas.drawCircle(Offset(lastX, lastY), 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
