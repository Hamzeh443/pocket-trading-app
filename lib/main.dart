import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'dart:async';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PocketTradingApp());
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
      home: const LiveTradingScreen(),
    );
  }
}

class LiveTradingScreen extends StatefulWidget {
  const LiveTradingScreen({super.key});

  @override
  State<LiveTradingScreen> createState() => _LiveTradingScreenState();
}

class _LiveTradingScreenState extends State<LiveTradingScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isBotActive = false;

  int _selectedDuration = 60;
  double _tradeAmount = 50.0;
  double _balance = 1000.0;

  @override
  void initState() {
    super.initState();

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF090C10))
      ..setUserAgent("Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36")
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      );

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      final androidController = controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
      androidController.setGeolocationPermissionsPromptCallbacks(
        onShowPrompt: (request) async {
          return const GeolocationPermissionsResponse(allow: true, retain: true);
        },
      );
    }

    controller.loadRequest(Uri.parse('https://po.trade/smart-chart'));

    _controller = controller;
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
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.candlestick_chart, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text('Pocket Option Real-Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.verified, color: Colors.greenAccent, size: 16),
                    SizedBox(width: 6),
                    Text('100% Pocket Feed Synced', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.blueAccent),
                  ),
              ],
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
