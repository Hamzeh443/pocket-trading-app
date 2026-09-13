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

class ActiveTrade {
  final String id;
  final String type; // BUY or SELL
  final double entryPrice;
  final double amount;
  final int durationSeconds;
  int remainingSeconds;
  final DateTime startTime;

  ActiveTrade({
    required this.id,
    required this.type,
    required this.entryPrice,
    required this.amount,
    required this.durationSeconds,
    required this.remainingSeconds,
    required this.startTime,
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
  final List<ActiveTrade> _activeTrades = [];
  bool _isBotActive = false;

  int _selectedDuration = 60; // بالثواني
  double _tradeAmount = 50.0;
  double _balance = 1000.0;

  Timer? _tickTimer;
  Timer? _tradeTimer;
  double _currentRsi = 50.0;

  @override
  void initState() {
    super.initState();
    _initCandles();
    _startEngine();
  }

  void _initCandles() {
    _candles.clear();
    DateTime now = DateTime.now();
    double price = 1.08500;
    final rand = Random();

    // إنشاء 40 شمعة سابقة بناءً على الوقت المحدد
    for (int i = 40; i >= 0; i--) {
      double open = price;
      double close = open + (rand.nextDouble() - 0.495) * 0.0004;
      double high = max(open, close) + rand.nextDouble() * 0.0002;
      double low = min(open, close) - rand.nextDouble() * 0.0002;
      _candles.add(Candle(
        open: open, high: high, low: low, close: close,
        timestamp: now.subtract(Duration(seconds: i * _selectedDuration))
      ));
      price = close;
    }
    _currentPrice = price;
    _calculateRSI();
  }

  void _startEngine() {
    _tickTimer?.cancel();
    _tradeTimer?.cancel();

    final rand = Random();
    
    // محرك الأسعار المباشر (تحديث كل 250 ميلي ثانية لتحريك النقطة بنعومة)
    _tickTimer = Timer.periodic(const Duration(milliseconds: 250), (t) {
      if (!mounted) return;
      
      setState(() {
        double delta = (rand.nextDouble() - 0.495) * 0.00010;
        _currentPrice = double.parse((_currentPrice + delta).toStringAsFixed(5));

        if (_candles.isNotEmpty) {
          var last = _candles.last;
          last.close = _currentPrice;
          if (_currentPrice > last.high) last.high = _currentPrice;
          if (_currentPrice < last.low) last.low = _currentPrice;

          // إنشاء شمعة جديدة فقط عند انتهاء المدة المحددة (TIME)
          if (DateTime.now().difference(last.timestamp).inSeconds >= _selectedDuration) {
            _candles.add(Candle(
              open: _currentPrice,
              high: _currentPrice,
              low: _currentPrice,
              close: _currentPrice,
              timestamp: DateTime.now(),
            ));
            if (_candles.length > 50) _candles.removeAt(0);
          }
        }
        _calculateRSI();
      });
    });

    // محرك متابعة الصفقات والمؤقت التنازلي (كل ثانية)
    _tradeTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      
      setState(() {
        for (int i = _activeTrades.length - 1; i >= 0; i--) {
          var trade = _activeTrades[i];
          trade.remainingSeconds--;

          if (trade.remainingSeconds <= 0) {
            // انتهاء الصفقة وحساب النتيجة
            bool won = false;
            if (trade.type == 'BUY' && _currentPrice > trade.entryPrice) won = true;
            if (trade.type == 'SELL' && _currentPrice < trade.entryPrice) won = true;

            if (won) {
              double profit = trade.amount * 1.85; // عائد 85%
              _balance += profit;
              _showResultSnackBar('PROFIT +\$${profit.toStringAsFixed(2)}', Colors.green);
            } else {
              _showResultSnackBar('LOSS -\$${trade.amount.toStringAsFixed(2)}', Colors.red);
            }

            _activeTrades.removeAt(i);
          }
        }
      });
    });
  }

  void _calculateRSI() {
    if (_candles.length < 15) return;
    double gains = 0;
    double losses = 0;

    for (int i = _candles.length - 14; i < _candles.length; i++) {
      double diff = _candles[i].close - _candles[i - 1].close;
      if (diff >= 0) {
        gains += diff;
      } else {
        losses -= diff;
      }
    }

    if (losses == 0) {
      _currentRsi = 100;
    } else {
      double rs = gains / losses;
      _currentRsi = 100 - (100 / (1 + rs));
    }
  }

  void _executeTrade(String type) {
    if (_balance < _tradeAmount) {
      _showResultSnackBar('Insufficient Balance!', Colors.orange);
      return;
    }

    setState(() {
      _balance -= _tradeAmount;
      _activeTrades.add(ActiveTrade(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        entryPrice: _currentPrice,
        amount: _tradeAmount,
        durationSeconds: _selectedDuration,
        remainingSeconds: _selectedDuration,
        startTime: DateTime.now(),
      ));
    });
  }

  void _showResultSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _tradeTimer?.cancel();
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
          // شريط السعر العلوي
          Container(
            color: const Color(0xFF161B22),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('PRICE: ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(
                      '$_currentPrice',
                      style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text('RSI(14): ${_currentRsi.toStringAsFixed(1)} ',
                        style: TextStyle(
                          color: _currentRsi > 70 ? Colors.redAccent : (_currentRsi < 30 ? Colors.greenAccent : Colors.orangeAccent),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        )),
                  ],
                ),
              ],
            ),
          ),

          // منطقة الشارت والصفقات النشطة
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF0E1117),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size.infinite,
                    painter: PocketChartPainter(_candles, _currentPrice, _activeTrades),
                  ),
                  if (_activeTrades.isNotEmpty)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _activeTrades.map((t) => Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: t.type == 'BUY' ? Colors.green.withOpacity(0.8) : Colors.red.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${t.type} \$${t.amount.toInt()} | EXPIRE: ${t.remainingSeconds}s',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        )).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // منطقة مؤشر RSI السفلي
          Expanded(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0E1117),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: CustomPaint(
                size: Size.infinite,
                painter: RsiPainter(_candles),
              ),
            ),
          ),

          // لوحة التحكم المزدوجة (الوقت والمبلغ والأزرار)
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
                          const Text('TIME (Candle & Trade)', style: TextStyle(color: Colors.grey, fontSize: 11)),
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
                            onChanged: (v) {
                              if (v != null) {
                                setState(() {
                                  _selectedDuration = v;
                                  _initCandles(); // إعادة التضمين بحسب الفريم الجديد
                                });
                              }
                            },
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
  final List<ActiveTrade> activeTrades;

  PocketChartPainter(this.candles, this.currentPrice, this.activeTrades);

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    double maxH = candles.map((c) => c.high).reduce(max);
    double minL = candles.map((c) => c.low).reduce(min);
    if (maxH == minL) {
      maxH += 0.0005;
      minL -= 0.0005;
    }

    double candleWidth = size.width / (candles.length + 1);

    for (int i = 0; i < candles.length; i++) {
      var c = candles[i];
      bool isGreen = c.close >= c.open;
      Paint candlePaint = Paint()
        ..color = isGreen ? const Color(0xFF00E676) : const Color(0xFFFF5252)
        ..strokeWidth = 1.5;

      double x = (i + 0.5) * candleWidth;

      double highY = size.height - ((c.high - minL) / (maxH - minL) * (size.height - 40)) - 20;
      double lowY = size.height - ((c.low - minL) / (maxH - minL) * (size.height - 40)) - 20;
      double openY = size.height - ((c.open - minL) / (maxH - minL) * (size.height - 40)) - 20;
      double closeY = size.height - ((c.close - minL) / (maxH - minL) * (size.height - 40)) - 20;

      canvas.drawLine(Offset(x, highY), Offset(x, lowY), candlePaint);

      double topY = min(openY, closeY);
      double bodyHeight = (openY - closeY).abs();
      if (bodyHeight < 2.0) bodyHeight = 2.0;

      canvas.drawRect(
        Rect.fromLTWH(x - (candleWidth * 0.35), topY, candleWidth * 0.7, bodyHeight),
        candlePaint..style = PaintingStyle.fill,
      );
    }

    // رسم خط ونقطة السعر المباشر
    double lastY = size.height - ((currentPrice - minL) / (maxH - minL) * (size.height - 40)) - 20;
    
    Paint linePaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.6)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, lastY), Offset(size.width, lastY), linePaint);

    Paint dotPaint = Paint()..color = Colors.cyanAccent;
    Paint dotGlow = Paint()..color = Colors.cyanAccent.withOpacity(0.3);
    
    double lastX = (candles.length - 0.5) * candleWidth;
    canvas.drawCircle(Offset(lastX, lastY), 7, dotGlow);
    canvas.drawCircle(Offset(lastX, lastY), 3.5, dotPaint);

    // رسم خطوط الصفقات الحية المفتوحة
    for (var trade in activeTrades) {
      double tradeY = size.height - ((trade.entryPrice - minL) / (maxH - minL) * (size.height - 40)) - 20;
      Paint tradeLinePaint = Paint()
        ..color = trade.type == 'BUY' ? Colors.greenAccent : Colors.redAccent
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      
      canvas.drawLine(Offset(0, tradeY), Offset(size.width, tradeY), tradeLinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class RsiPainter extends CustomPainter {
  final List<Candle> candles;
  RsiPainter(this.candles);

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.length < 15) return;

    // خطوط 70 و 30
    Paint gridPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;
    
    double y70 = size.height - (0.7 * size.height);
    double y30 = size.height - (0.3 * size.height);

    canvas.drawLine(Offset(0, y70), Offset(size.width, y70), gridPaint);
    canvas.drawLine(Offset(0, y30), Offset(size.width, y30), gridPaint);

    // رسم مسار RSI
    List<double> rsiValues = [];
    for (int i = 14; i < candles.length; i++) {
      double gains = 0;
      double losses = 0;
      for (int j = i - 13; j <= i; j++) {
        double diff = candles[j].close - candles[j - 1].close;
        if (diff >= 0) gains += diff; else losses -= diff;
      }
      double rsi = losses == 0 ? 100 : 100 - (100 / (1 + (gains / losses)));
      rsiValues.add(rsi);
    }

    if (rsiValues.isEmpty) return;

    Paint rsiPaint = Paint()
      ..color = Colors.orangeAccent
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    Path path = Path();
    double stepX = size.width / (rsiValues.length - 1);

    for (int i = 0; i < rsiValues.length; i++) {
      double x = i * stepX;
      double y = size.height - ((rsiValues[i] / 100) * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, rsiPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
