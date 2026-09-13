import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
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

class Trade {
  final String id;
  final String pair;
  final String type; // BUY or SELL
  final double amount;
  final double entryPrice;
  final DateTime expiryTime;
  double? exitPrice;
  String status; // ACTIVE, WIN, LOSS

  Trade({
    required this.id,
    required this.pair,
    required this.type,
    required this.amount,
    required this.entryPrice,
    required this.expiryTime,
    this.status = 'ACTIVE',
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
      home: const MainTradingScreen(),
    );
  }
}

class MainTradingScreen extends StatefulWidget {
  const MainTradingScreen({super.key});

  @override
  State<MainTradingScreen> createState() => _MainTradingScreenState();
}

class _MainTradingScreenState extends State<MainTradingScreen> {
  String _selectedPair = 'EUR/USD (OTC)';
  final List<String> _pairs = ['EUR/USD (OTC)', 'GBP/USD (OTC)', 'USD/JPY (OTC)', 'BTC/USD'];
  
  double _currentPrice = 1.08500;
  final List<Candle> _candles = [];
  final List<Trade> _activeTrades = [];
  final List<Trade> _tradeHistory = [];

  double _rsi = 50.0;
  bool _isBotActive = false;
  
  int _selectedDuration = 60; // 1m default
  double _tradeAmount = 50.0;
  double _balance = 1000.0;

  double _zoomLevel = 1.0;
  double _panOffset = 0.0;

  WebSocket? _socket;
  StreamSubscription? _socketSub;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initCandles();
    _connectToPocketFeed();
    _startTradeMonitoring();
  }

  void _initCandles() {
    _candles.clear();
    DateTime now = DateTime.now();
    double price = _currentPrice;
    final rand = Random();

    for (int i = 50; i >= 0; i--) {
      double open = price;
      double close = open + (rand.nextDouble() - 0.48) * 0.0008;
      double high = max(open, close) + rand.nextDouble() * 0.0003;
      double low = min(open, close) - rand.nextDouble() * 0.0003;
      _candles.add(Candle(
        open: open, high: high, low: low, close: close,
        timestamp: now.subtract(Duration(seconds: i * 5))
      ));
      price = close;
    }
    _currentPrice = price;
  }

  Future<void> _connectToPocketFeed() async {
    try {
      await _socketSub?.cancel();
      await _socket?.close();

      _socket = await WebSocket.connect('wss://ws.binaryws.com/websockets/v3?app_id=1089');
      String symbol = _selectedPair.contains('GBP') ? 'frxGBPUSD' : (_selectedPair.contains('JPY') ? 'frxUSDJPY' : 'frxEURUSD');

      _socket?.add(jsonEncode({"ticks": symbol, "subscribe": 1}));
      _socketSub = _socket?.listen((msg) {
        var data = jsonDecode(msg);
        if (data['tick'] != null) {
          double price = (data['tick']['quote'] as num).toDouble();
          _updatePrice(price);
        }
      }, onError: (_) => _startSimulationFeed());
    } catch (_) {
      _startSimulationFeed();
    }
  }

  void _startSimulationFeed() {
    final rand = Random();
    Timer.periodic(const Duration(milliseconds: 800), (t) {
      if (!mounted) return;
      double change = (rand.nextDouble() - 0.495) * 0.0002;
      _updatePrice(_currentPrice + change);
    });
  }

  void _updatePrice(double price) {
    if (!mounted) return;
    setState(() {
      _currentPrice = double.parse(price.toStringAsFixed(5));
      if (_candles.isNotEmpty) {
        var last = _candles.last;
        last.close = _currentPrice;
        if (_currentPrice > last.high) last.high = _currentPrice;
        if (_currentPrice < last.low) last.low = _currentPrice;
      }
      _calculateRSI();
      if (_isBotActive) _checkBotTriggers();
    });
  }

  void _calculateRSI() {
    if (_candles.length < 14) return;
    double gains = 0, losses = 0;
    for (int i = _candles.length - 14; i < _candles.length; i++) {
      double diff = _candles[i].close - _candles[i].open;
      if (diff >= 0) gains += diff; else losses += diff.abs();
    }
    if (losses == 0) _rsi = 100;
    else {
      double rs = gains / losses;
      _rsi = double.parse((100 - (100 / (1 + rs))).toStringAsFixed(1));
    }
  }

  void _checkBotTriggers() {
    if (_rsi <= 25) {
      _executeTrade('BUY');
    } else if (_rsi >= 75) {
      _executeTrade('SELL');
    }
  }

  void _executeTrade(String type) {
    if (_balance < _tradeAmount) return;

    setState(() {
      _balance -= _tradeAmount;
      _activeTrades.add(Trade(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        pair: _selectedPair,
        type: type,
        amount: _tradeAmount,
        entryPrice: _currentPrice,
        expiryTime: DateTime.now().add(Duration(seconds: _selectedDuration)),
      ));
    });
  }

  void _startTradeMonitoring() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      DateTime now = DateTime.now();
      setState(() {
        for (int i = _activeTrades.length - 1; i >= 0; i--) {
          var trade = _activeTrades[i];
          if (now.isAfter(trade.expiryTime)) {
            trade.exitPrice = _currentPrice;
            bool isWin = trade.type == 'BUY' 
                ? _currentPrice > trade.entryPrice 
                : _currentPrice < trade.entryPrice;
            
            trade.status = isWin ? 'WIN' : 'LOSS';
            if (isWin) _balance += trade.amount * 1.92; // 92% Payout
            
            _tradeHistory.insert(0, trade);
            _activeTrades.removeAt(i);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    _socket?.close();
    _timer?.cancel();
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
                  _connectToPocketFeed();
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
                Text('\$${_balance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // Top Control Panel: RSI & Bot Switch
          Container(
            color: const Color(0xFF161B22),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('RSI (14): ', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    Text('$_rsi', style: TextStyle(
                      color: _rsi >= 70 ? Colors.redAccent : (_rsi <= 30 ? Colors.greenAccent : Colors.amber),
                      fontWeight: FontWeight.bold,
                    )),
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

          // Interactive Chart Container with Pinch-to-Zoom & Pan
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

          // Bottom Trading Control Panel
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
                          const Text('AMOUNT ($)', style: TextStyle(color: Colors.grey, fontSize: 11)),
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
        ..strokeWidth = 1.2;

      double x = size.width - ((candles.length - i) * baseWidth) + pan;

      if (x < -20 || x > size.width + 20) continue;

      double highY = size.height - ((c.high - minL) / (maxH - minL) * (size.height - 40)) - 20;
      double lowY = size.height - ((c.low - minL) / (maxH - minL) * (size.height - 40)) - 20;
      double openY = size.height - ((c.open - minL) / (maxH - minL) * (size.height - 40)) - 20;
      double closeY = size.height - ((c.close - minL) / (maxH - minL) * (size.height - 40)) - 20;

      // Draw Wick
      canvas.drawLine(Offset(x, highY), Offset(x, lowY), paint);

      // Draw Body
      double topY = min(openY, closeY);
      double bodyHeight = (openY - closeY).abs();
      if (bodyHeight < 1.5) bodyHeight = 1.5;

      canvas.drawRect(
        Rect.fromLTWH(x - (baseWidth * 0.35), topY, baseWidth * 0.7, bodyHeight),
        paint..style = PaintingStyle.fill,
      );
    }

    // Current Price Line
    double lastY = size.height - ((currentPrice - minL) / (maxH - minL) * (size.height - 40)) - 20;
    Paint linePaint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, lastY), Offset(size.width, lastY), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
