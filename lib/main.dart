import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

void main() {
  runApp(const EURUSDTradingApp());
}

class EURUSDTradingApp extends StatelessWidget {
  const EURUSDTradingApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EURUSD Trading',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0a0e27),
        primaryColor: const Color(0xFF3b82f6),
      ),
      home: const TradingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Candle {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;

  Candle({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });
}

class Drawing {
  final String type;
  final Offset start;
  final Offset end;
  final int id;

  Drawing({
    required this.type,
    required this.start,
    required this.end,
    required this.id,
  });
}

class Position {
  final int id;
  final String type;
  final double entry;
  final double stopLoss;
  final double takeProfit;
  final double lots;
  final DateTime openTime;

  Position({
    required this.id,
    required this.type,
    required this.entry,
    required this.stopLoss,
    required this.takeProfit,
    required this.lots,
    required this.openTime,
  });
}

class TradingScreen extends StatefulWidget {
  const TradingScreen({Key? key}) : super(key: key);

  @override
  State<TradingScreen> createState() => _TradingScreenState();
}

class _TradingScreenState extends State<TradingScreen> {
  String timeframe = 'H1';
  String mode = 'live';
  bool isPlaying = false;
  int currentIndex = 0;
  String? drawingTool;
  List<Drawing> drawings = [];
  List<Position> positions = [];
  List<Candle> candles = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    candles = _generateCandles(200);
    currentIndex = candles.length - 1;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<Candle> _generateCandles(int count) {
    final random = Random();
    double lastClose = 1.0850;
    final now = DateTime.now();
    final List<Candle> result = [];

    final timeframes = {
      'M1': 60000,
      'M5': 300000,
      'M15': 900000,
      'M30': 1800000,
      'H1': 3600000,
      'H4': 14400000,
      'D1': 86400000,
    };

    final interval = timeframes[timeframe]!;

    for (int i = 0; i < count; i++) {
      final open = lastClose;
      final volatility = 0.0015;
      final change = (random.nextDouble() - 0.48) * volatility;
      final close = open + change;
      final high = max(open, close) + random.nextDouble() * volatility * 0.5;
      final low = min(open, close) - random.nextDouble() * volatility * 0.5;

      result.add(Candle(
        time: now.subtract(Duration(milliseconds: (count - i) * interval)),
        open: double.parse(open.toStringAsFixed(5)),
        high: double.parse(high.toStringAsFixed(5)),
        low: double.parse(low.toStringAsFixed(5)),
        close: double.parse(close.toStringAsFixed(5)),
      ));

      lastClose = close;
    }

    return result;
  }

  void _startBacktest() {
    if (mode != 'backtest' || isPlaying) return;

    setState(() => isPlaying = true);

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (currentIndex >= candles.length - 1) {
        timer.cancel();
        setState(() => isPlaying = false);
      } else {
        setState(() => currentIndex++);
      }
    });
  }

  void _stopBacktest() {
    _timer?.cancel();
    setState(() => isPlaying = false);
  }

  double _calculatePL(Position pos) {
    final currentPrice = candles.last.close;
    final priceDiff = pos.type == 'long'
        ? currentPrice - pos.entry
        : pos.entry - currentPrice;
    const pipValue = 10.0;
    final pips = priceDiff * 10000;
    return pips * pipValue * pos.lots;
  }

  void _showOrderDialog(String type) {
    final entryController = TextEditingController(
      text: candles.last.close.toStringAsFixed(5),
    );
    final slController = TextEditingController();
    final tpController = TextEditingController();
    final lotsController = TextEditingController(text: '0.01');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1f2937),
        title: Text('${type.toUpperCase()} Position'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: entryController,
              decoration: const InputDecoration(labelText: 'Entry Price'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: slController,
              decoration: const InputDecoration(labelText: 'Stop Loss'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tpController,
              decoration: const InputDecoration(labelText: 'Take Profit'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lotsController,
              decoration: const InputDecoration(labelText: 'Lots'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                positions.add(Position(
                  id: DateTime.now().millisecondsSinceEpoch,
                  type: type,
                  entry: double.parse(entryController.text),
                  stopLoss: double.parse(slController.text),
                  takeProfit: double.parse(tpController.text),
                  lots: double.parse(lotsController.text),
                  openTime: DateTime.now(),
                ));
              });
              Navigator.pop(context);
            },
            child: const Text('Place Order'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPrice = candles.isNotEmpty ? candles.last.close : 1.0850;
    final totalPL = positions.fold(0.0, (sum, pos) => sum + _calculatePL(pos));

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1f2937),
            child: Row(
              children: [
                const Text(
                  'EUR/USD',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3b82f6),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  currentPrice.toStringAsFixed(5),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Timeframes
                ...['M1', 'M5', 'M15', 'M30', 'H1', 'H4', 'D1'].map(
                  (tf) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: timeframe == tf
                            ? const Color(0xFF3b82f6)
                            : const Color(0xFF374151),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          timeframe = tf;
                          candles = _generateCandles(200);
                          currentIndex = candles.length - 1;
                        });
                      },
                      child: Text(tf),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Mode
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mode == 'live'
                        ? const Color(0xFF22c55e)
                        : const Color(0xFF374151),
                  ),
                  onPressed: () => setState(() => mode = 'live'),
                  child: const Text('Live'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mode == 'backtest'
                        ? const Color(0xFF9333ea)
                        : const Color(0xFF374151),
                  ),
                  onPressed: () => setState(() => mode = 'backtest'),
                  child: const Text('Backtesting'),
                ),
              ],
            ),
          ),

          // Drawing Tools
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF1f2937),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildDrawingButton('Trend', 'trend'),
                  _buildDrawingButton('Horizontal', 'horizontal'),
                  _buildDrawingButton('Vertical', 'vertical'),
                  _buildDrawingButton('Rectangle', 'rectangle'),
                  _buildDrawingButton('Circle', 'circle'),
                  _buildDrawingButton('Path', 'path'),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFef4444),
                    ),
                    onPressed: () {
                      setState(() {
                        drawings.clear();
                        drawingTool = null;
                      });
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete All'),
                  ),
                ],
              ),
            ),
          ),

          // Chart
          Expanded(
            child: CustomPaint(
              painter: ChartPainter(
                candles: candles,
                currentIndex: currentIndex,
                drawings: drawings,
                positions: positions,
                currentPrice: currentPrice,
              ),
              child: Container(),
            ),
          ),

          // Backtest Controls
          if (mode == 'backtest')
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF1f2937),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                    color: const Color(0xFF3b82f6),
                    onPressed: isPlaying ? _stopBacktest : _startBacktest,
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    onPressed: () {
                      if (currentIndex < candles.length - 1) {
                        setState(() => currentIndex++);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => setState(() => currentIndex = 0),
                  ),
                  Expanded(
                    child: Slider(
                      value: currentIndex.toDouble(),
                      min: 0,
                      max: (candles.length - 1).toDouble(),
                      onChanged: (value) {
                        setState(() => currentIndex = value.toInt());
                      },
                    ),
                  ),
                  Text('$currentIndex / ${candles.length - 1}'),
                ],
              ),
            ),

          // Trading Panel
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1f2937),
            child: Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22c55e),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () => _showOrderDialog('long'),
                  icon: const Icon(Icons.trending_up),
                  label: const Text('LONG'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFef4444),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () => _showOrderDialog('short'),
                  icon: const Icon(Icons.trending_down),
                  label: const Text('SHORT'),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Open Positions'),
                    Text(
                      '${positions.length}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 32),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Total P&L'),
                    Text(
                      '\$${totalPL.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: totalPL >= 0
                            ? const Color(0xFF22c55e)
                            : const Color(0xFFef4444),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Positions List
          if (positions.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              color: const Color(0xFF1f2937),
              child: ListView.builder(
                itemCount: positions.length,
                itemBuilder: (context, index) {
                  final pos = positions[index];
                  final pl = _calculatePL(pos);

                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF374151),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: pos.type == 'long'
                                ? const Color(0xFF22c55e)
                                : const Color(0xFFef4444),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            pos.type.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text('Entry: ${pos.entry.toStringAsFixed(5)}'),
                        const SizedBox(width: 16),
                        Text('SL: ${pos.stopLoss.toStringAsFixed(5)}'),
                        const SizedBox(width: 16),
                        Text('TP: ${pos.takeProfit.toStringAsFixed(5)}'),
                        const SizedBox(width: 16),
                        Text('Lots: ${pos.lots}'),
                        const Spacer(),
                        Text(
                          '\$${pl.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: pl >= 0
                                ? const Color(0xFF22c55e)
                                : const Color(0xFFef4444),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFef4444),
                          ),
                          onPressed: () {
                            setState(() {
                              positions.removeAt(index);
                            });
                          },
                          child: const Text('Close'),
                        ),
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

  Widget _buildDrawingButton(String label, String tool) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: drawingTool == tool
              ? const Color(0xFFfbbf24)
              : const Color(0xFF374151),
          foregroundColor:
              drawingTool == tool ? Colors.black : Colors.white,
        ),
        onPressed: () => setState(() => drawingTool = tool),
        child: Text(label),
      ),
    );
  }
}

class ChartPainter extends CustomPainter {
  final List<Candle> candles;
  final int currentIndex;
  final List<Drawing> drawings;
  final List<Position> positions;
  final double currentPrice;

  ChartPainter({
    required this.candles,
    required this.currentIndex,
    required this.drawings,
    required this.positions,
    required this.currentPrice,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final paint = Paint();
    final chartTop = 40.0;
    final chartBottom = size.height - 40;
    final chartLeft = 60.0;
    final chartRight = size.width - 60;
    final chartHeight = chartBottom - chartTop;
    final chartWidth = chartRight - chartLeft;

    // Background
    paint.color = const Color(0xFF0a0e27);
    canvas.drawRect(Offset.zero & size, paint);

    // Get visible candles
    final startIndex = max(0, currentIndex - 100);
    final visibleCandles = candles.sublist(startIndex, currentIndex + 1);

    if (visibleCandles.isEmpty) return;

    // Calculate price range
    double maxPrice = visibleCandles[0].high;
    double minPrice = visibleCandles[0].low;

    for (var candle in visibleCandles) {
      maxPrice = max(maxPrice, candle.high);
      minPrice = min(minPrice, candle.low);
    }

    final priceRange = maxPrice - minPrice;
    final padding = priceRange * 0.1;
    maxPrice += padding;
    minPrice -= padding;

    // Draw grid
    paint.color = const Color(0xFF1a1f3a);
    paint.strokeWidth = 1;

    for (int i = 0; i <= 10; i++) {
      final y = chartTop + (chartHeight / 10) * i;
      canvas.drawLine(
        Offset(chartLeft, y),
        Offset(chartRight, y),
        paint,
      );

      final price = maxPrice - ((maxPrice - minPrice) / 10) * i;
      final textPainter = TextPainter(
        text: TextSpan(
          text: price.toStringAsFixed(5),
          style: const TextStyle(color: Color(0xFF6b7280), fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(chartLeft - 50, y - 6));
    }

    // Draw candles
    final candleWidth = chartWidth / visibleCandles.length;
    final bodyWidth = max(2.0, candleWidth * 0.7);

    for (int i = 0; i < visibleCandles.length; i++) {
      final candle = visibleCandles[i];
      final x = chartLeft + (i + 0.5) * candleWidth;

      final openY = chartTop +
          ((maxPrice - candle.open) / (maxPrice - minPrice)) * chartHeight;
      final closeY = chartTop +
          ((maxPrice - candle.close) / (maxPrice - minPrice)) * chartHeight;
      final highY = chartTop +
          ((maxPrice - candle.high) / (maxPrice - minPrice)) * chartHeight;
      final lowY = chartTop +
          ((maxPrice - candle.low) / (maxPrice - minPrice)) * chartHeight;

      final isGreen = candle.close >= candle.open;
      paint.color = isGreen ? const Color(0xFF22c55e) : const Color(0xFFef4444);

      // Wick
      paint.strokeWidth = 1;
      canvas.drawLine(Offset(x, highY), Offset(x, lowY), paint);

      // Body
      final bodyTop = min(openY, closeY);
      final bodyHeight = max(1.0, (closeY - openY).abs());
      canvas.drawRect(
        Rect.fromLTWH(x - bodyWidth / 2, bodyTop, bodyWidth, bodyHeight),
        paint,
      );
    }

    // Draw positions
    for (var pos in positions) {
      final entryY = chartTop +
          ((maxPrice - pos.entry) / (maxPrice - minPrice)) * chartHeight;
      final slY = chartTop +
          ((maxPrice - pos.stopLoss) / (maxPrice - minPrice)) * chartHeight;
      final tpY = chartTop +
          ((maxPrice - pos.takeProfit) / (maxPrice - minPrice)) * chartHeight;

      // Entry line
      paint.color = pos.type == 'long'
          ? const Color(0xFF3b82f6)
          : const Color(0xFFf59e0b);
      paint.strokeWidth = 2;
      paint.style = PaintingStyle.stroke;

      final dashWidth = 5.0;
      final dashSpace = 5.0;
      double currentX = chartLeft;

      while (currentX < chartRight) {
        canvas.drawLine(
          Offset(currentX, entryY),
          Offset(min(currentX + dashWidth, chartRight), entryY),
          paint,
        );
        currentX += dashWidth + dashSpace;
      }

      // SL line
      paint.color = const Color(0xFFef4444);
      currentX = chartLeft;
      while (currentX < chartRight) {
        canvas.drawLine(
          Offset(currentX, slY),
          Offset(min(currentX + dashWidth, chartRight), slY),
          paint,
        );
        currentX += dashWidth + dashSpace;
      }

      // TP line
      paint.color = const Color(0xFF22c55e);
      currentX = chartLeft;
      while (currentX < chartRight) {
        canvas.drawLine(
          Offset(currentX, tpY),
          Offset(min(currentX + dashWidth, chartRight), tpY),
          paint,
        );
        currentX += dashWidth + dashSpace;
      }
    }

    // Current price line
    paint.style = PaintingStyle.stroke;
    final currentPriceY = chartTop +
        ((maxPrice - currentPrice) / (maxPrice - minPrice)) * chartHeight;
    paint.color = const Color(0xFF3b82f6);
    paint.strokeWidth = 2;

    double currentX = chartLeft;
    const dashWidth = 3.0;
    const dashSpace = 3.0;

    while (currentX < chartRight) {
      canvas.drawLine(
        Offset(currentX, currentPriceY),
        Offset(min(currentX + dashWidth, chartRight), currentPriceY),
        paint,
      );
      currentX += dashWidth + dashSpace;
    }

    // Price label
    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFF3b82f6);
    canvas.drawRect(
      Rect.fromLTWH(chartRight + 5, currentPriceY - 12, 65, 24),
      paint,
    );

    final priceText = TextPainter(
      text: TextSpan(
        text: currentPrice.toStringAsFixed(5),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    priceText.layout();
    priceText.paint(canvas, Offset(chartRight + 10, currentPriceY - 6));
  }

  @override
  bool shouldRepaint(covariant ChartPainter oldDelegate) => true;
}