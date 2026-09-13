import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(const PocketOptionApp());
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
  final String pair;
  final String type; // CALL or PUT
  final double entryPrice;
  final int amount;
  int secondsLeft;

  ActiveTrade({
    required this.pair,
    required this.type,
    required this.entryPrice,
    required this.amount,
    required this.secondsLeft,
  });
}

class PocketOptionApp extends StatelessWidget {
  const PocketOptionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pocket Option Simulator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF090D14),
        cardColor: const Color(0xFF131B26),
      ),
      home: const PocketDashboardScreen(),
    );
  }
}

class PocketDashboardScreen extends StatefulWidget {
  const PocketDashboardScreen({super.key});

  @override
  State<PocketDashboardScreen> createState() => _PocketDashboardScreenState();
}

class _PocketDashboardScreenState extends State<PocketDashboardScreen> {
  String _selectedPair = 'EUR/USD (OTC)';
  final List<String> _pairs = ['EUR/USD (OTC)', 'BTC/USDT', 'GBP/USD', 'ETH/USDT'];

  double _currentPrice = 1.0850;
  List<Candle> _candles = [];
  List<double> _emaValues = [];
  double _rsi = 50.0;
  
  int _investment = 10;
  double _balance = 10000.0;
  bool _audioAlert = true;

  String _signalText = "NEUTRAL / ANALYZING";
  Color _signalColor = Colors.orangeAccent;

  Timer? _marketTimer;
  Timer? _tradeTimer;
  List<ActiveTrade> _activeTrades = [];

  @override
  void initState() {
    super.initState();
    _generateInitialCandles();
    _startMarketEngine();
  }

  void _generateInitialCandles() {
    _candles.clear();
    double price = _currentPrice;
    DateTime now = DateTime.now().subtract(const Duration(minutes: 30));

    for (int i = 0; i < 30; i++) {
      double change = (Random().nextDouble() - 0.49) * 0.0008;
      double open = price;
      double close = open + change;
      double high = max(open, close) + Random().nextDouble() * 0.0003;
      double low = min(open, close) - Random().nextDouble() * 0.0003;

      _candles.add(Candle(
        open: open,
        high: high,
        low: low,
        close: close,
        timestamp: now.add(Duration(minutes: i)),
      ));
      price = close;
    }
    _currentPrice = price;
    _recalculateIndicators();
  }

  void _startMarketEngine() {
    _marketTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _tickMarket();
    });

    _tradeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _tickTrades();
    });
  }

  void _tickMarket() {
    if (_candles.isEmpty) return;

    DateTime now = DateTime.now();
    double change = (Random().nextDouble() - 0.495) * 0.0004;
    double newPrice = _candles.last.close + change;

    var lastCandle = _candles.last;

    if (now.difference(lastCandle.timestamp).inSeconds >= 60) {
      _candles.add(Candle(
        open: newPrice,
        high: newPrice,
        low: newPrice,
        close: newPrice,
        timestamp: now,
      ));
      if (_candles.length > 30) _candles.removeAt(0);
    } else {
      lastCandle.close = newPrice;
      if (newPrice > lastCandle.high) lastCandle.high = newPrice;
      if (newPrice < lastCandle.low) lastCandle.low = newPrice;
    }

    setState(() {
      _currentPrice = newPrice;
      _recalculateIndicators();
    });
  }

  void _recalculateIndicators() {
    if (_candles.length < 14) return;

    // Calculate RSI (14)
    double gains = 0;
    double losses = 0;
    for (int i = _candles.length - 14; i < _candles.length; i++) {
      double diff = _candles[i].close - _candles[i - 1].close;
      if (diff >= 0) gains += diff; else losses -= diff;
    }
    double rs = losses == 0 ? 100 : gains / losses;
    _rsi = 100 - (100 / (1 + rs));

    // Calculate EMA (9)
    double k = 2 / (9 + 1);
    _emaValues.clear();
    double ema = _candles.first.close;
    _emaValues.add(ema);

    for (int i = 1; i < _candles.length; i++) {
      ema = (_candles[i].close * k) + (ema * (1 - k));
      _emaValues.add(ema);
    }

    // Generate Signals
    if (_rsi < 32) {
      _signalText = "STRONG CALL (OVERSOLD)";
      _signalColor = Colors.greenAccent;
    } else if (_rsi > 68) {
      _signalText = "STRONG PUT (OVERBOUGHT)";
      _signalColor = Colors.redAccent;
    } else {
      _signalText = "NEUTRAL / HOLD";
      _signalColor = Colors.orangeAccent;
    }
  }

  void _executeTrade(String type) {
    if (_balance < _investment) return;

    setState(() {
      _balance -= _investment;
      _activeTrades.add(ActiveTrade(
        pair: _selectedPair,
        type: type,
        entryPrice: _currentPrice,
        amount: _investment,
        secondsLeft: 60,
      ));
    });
  }

  void _tickTrades() {
    if (_activeTrades.isEmpty) return;

    setState(() {
      for (int i = _activeTrades.length - 1; i >= 0; i--) {
        var trade = _activeTrades[i];
        trade.secondsLeft--;

        if (trade.secondsLeft <= 0) {
          bool win = (trade.type == 'CALL' && _currentPrice > trade.entryPrice) ||
                     (trade.type == 'PUT' && _currentPrice < trade.entryPrice);

          if (win) {
            _balance += trade.amount * 1.92;
          }
          _activeTrades.removeAt(i);
        }
      }
    });
  }

  @override
  void dispose() {
    _marketTimer?.cancel();
    _tradeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF131B26),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('DEMO', style: TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            Text('\$${_balance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_audioAlert ? Icons.volume_up : Icons.volume_off, color: _audioAlert ? Colors.greenAccent : Colors.grey),
            onPressed: () => setState(() => _audioAlert = !_audioAlert),
          )
        ],
      ),
      body: Column(
        children: [
          // Pair Selector & Signal Header Bar
          Container(
            color: const Color(0xFF182230),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPair,
                    dropdownColor: const Color(0xFF182230),
                    items: _pairs.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)))).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _selectedPair = v;
                          _generateInitialCandles();
                        });
                      }
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _signalColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _signalColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt, color: Colors.yellowAccent, size: 14),
                      const SizedBox(width: 4),
                      Text(_signalText, style: TextStyle(color: _signalColor, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Chart Screen
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF090D14),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: CustomPaint(
                size: Size.infinite,
                painter: PocketChartPainter(_candles, _emaValues, _currentPrice),
              ),
            ),
          ),

          // Active Trades Panel
          if (_activeTrades.isNotEmpty)
            Container(
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _activeTrades.length,
                itemBuilder: (context, index) {
                  var t = _activeTrades[index];
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131B26),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: t.type == 'CALL' ? Colors.greenAccent : Colors.redAccent),
                    ),
                    child: Row(
                      children: [
                        Text('${t.type} \$${t.amount}', style: TextStyle(color: t.type == 'CALL' ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(width: 8),
                        Text('${t.secondsLeft}s', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                },
              ),
            ),

          // Control Dashboard
          Container(
            color: const Color(0xFF131B26),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('RSI (14): ${_rsi.toStringAsFixed(1)}', style: TextStyle(color: _signalColor, fontWeight: FontWeight.bold, fontSize: 12)),
                    Row(
                      children: [
                        const Text('Investment: ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, size: 20),
                          onPressed: () => setState(() => _investment = max(1, _investment - 5)),
                        ),
                        Text('\$$_investment', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          onPressed: () => setState(() => _investment += 5),
                        ),
                      ],
                    )
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
                        ),
                        onPressed: () => _executeTrade('CALL'),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_upward, color: Colors.black, size: 20),
                            SizedBox(width: 6),
                            Text('HIGHER (CALL)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5252),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => _executeTrade('PUT'),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_downward, color: Colors.white, size: 20),
                            SizedBox(width: 6),
                            Text('LOWER (PUT)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
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
  final List<double> ema;
  final double currentPrice;

  PocketChartPainter(this.candles, this.ema, this.currentPrice);

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    double maxH = candles.map((c) => c.high).reduce(max);
    double minL = candles.map((c) => c.low).reduce(min);
    if (maxH == minL) { maxH += 0.001; minL -= 0.001; }

    double w = size.width / (candles.length + 1);

    // Draw Candlesticks
    for (int i = 0; i < candles.length; i++) {
      var c = candles[i];
      bool isGreen = c.close >= c.open;
      Paint p = Paint()
        ..color = isGreen ? const Color(0xFF00E676) : const Color(0xFFFF5252)
        ..strokeWidth = 1.2;

      double x = (i + 0.5) * w;
      double hY = size.height - ((c.high - minL) / (maxH - minL) * (size.height - 40)) - 20;
      double lY = size.height - ((c.low - minL) / (maxH - minL) * (size.height - 40)) - 20;
      double oY = size.height - ((c.open - minL) / (maxH - minL) * (size.height - 40)) - 20;
      double cY = size.height - ((c.close - minL) / (maxH - minL) * (size.height - 40)) - 20;

      canvas.drawLine(Offset(x, hY), Offset(x, lY), p);
      canvas.drawRect(
        Rect.fromLTWH(x - (w * 0.3), min(oY, cY), w * 0.6, max((oY - cY).abs(), 2.0)),
        p..style = PaintingStyle.fill,
      );
    }

    // Draw EMA 9 Yellow Line
    if (ema.length == candles.length) {
      Paint emaPaint = Paint()
        ..color = Colors.amberAccent
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      Path path = Path();
      for (int i = 0; i < ema.length; i++) {
        double x = (i + 0.5) * w;
        double y = size.height - ((ema[i] - minL) / (maxH - minL) * (size.height - 40)) - 20;
        if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
      }
      canvas.drawPath(path, emaPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
