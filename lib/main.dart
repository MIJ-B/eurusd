import React, { useState, useRef, useEffect } from 'react';
import { TrendingUp, TrendingDown, Play, Pause, RotateCcw, SkipForward, Minus, Circle, Square, Pencil, Trash2 } from 'lucide-react';

const EURUSDTradingApp = () => {
  const canvasRef = useRef(null);
  const [timeframe, setTimeframe] = useState('H1');
  const [mode, setMode] = useState('live');
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentIndex, setCurrentIndex] = useState(0);
  const [drawingTool, setDrawingTool] = useState(null);
  const [drawings, setDrawings] = useState([]);
  const [isDrawing, setIsDrawing] = useState(false);
  const [drawStart, setDrawStart] = useState(null);
  const [tempDrawing, setTempDrawing] = useState(null);
  const [positions, setPositions] = useState([]);
  const [showOrderDialog, setShowOrderDialog] = useState(false);
  const [orderType, setOrderType] = useState('long');
  const [entryPrice, setEntryPrice] = useState('');
  const [stopLoss, setStopLoss] = useState('');
  const [takeProfit, setTakeProfit] = useState('');
  const [lots, setLots] = useState('0.01');

  // Generate realistic EURUSD candlestick data
  const generateCandles = (count) => {
    const candles = [];
    let lastClose = 1.0850;
    const now = Date.now();
    const timeframes = {
      'M1': 60000, 'M5': 300000, 'M15': 900000, 'M30': 1800000,
      'H1': 3600000, 'H4': 14400000, 'D1': 86400000
    };
    const interval = timeframes[timeframe];

    for (let i = 0; i < count; i++) {
      const open = lastClose;
      const volatility = 0.0015;
      const change = (Math.random() - 0.48) * volatility;
      const close = open + change;
      const high = Math.max(open, close) + Math.random() * volatility * 0.5;
      const low = Math.min(open, close) - Math.random() * volatility * 0.5;
      
      candles.push({
        time: now - (count - i) * interval,
        open: parseFloat(open.toFixed(5)),
        high: parseFloat(high.toFixed(5)),
        low: parseFloat(low.toFixed(5)),
        close: parseFloat(close.toFixed(5))
      });
      
      lastClose = close;
    }
    return candles;
  };

  const [candles, setCandles] = useState(() => generateCandles(200));
  const currentPrice = candles[candles.length - 1]?.close || 1.0850;

  // Drawing functions
  const getCanvasCoords = (e) => {
    const canvas = canvasRef.current;
    const rect = canvas.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;
    
    const visibleCandles = candles.slice(Math.max(0, currentIndex - 100), currentIndex + 1);
    const prices = visibleCandles.flatMap(c => [c.high, c.low]);
    const maxPrice = Math.max(...prices);
    const minPrice = Math.min(...prices);
    
    const price = maxPrice - (y - 40) / (canvas.height - 80) * (maxPrice - minPrice);
    const candleIndex = Math.floor((x - 60) / ((canvas.width - 120) / visibleCandles.length));
    
    return { x, y, price, candleIndex };
  };

  const handleMouseDown = (e) => {
    if (!drawingTool) return;
    const coords = getCanvasCoords(e);
    setIsDrawing(true);
    setDrawStart(coords);
  };

  const handleMouseMove = (e) => {
    if (!isDrawing || !drawStart) return;
    const coords = getCanvasCoords(e);
    
    setTempDrawing({
      type: drawingTool,
      start: drawStart,
      end: coords
    });
  };

  const handleMouseUp = (e) => {
    if (!isDrawing || !drawStart) return;
    const coords = getCanvasCoords(e);
    
    setDrawings([...drawings, {
      type: drawingTool,
      start: drawStart,
      end: coords,
      id: Date.now()
    }]);
    
    setIsDrawing(false);
    setDrawStart(null);
    setTempDrawing(null);
  };

  // Draw chart
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    
    const ctx = canvas.getContext('2d');
    const width = canvas.width;
    const height = canvas.height;
    
    // Clear canvas
    ctx.fillStyle = '#0a0e27';
    ctx.fillRect(0, 0, width, height);
    
    // Get visible candles
    const visibleCandles = candles.slice(Math.max(0, currentIndex - 100), currentIndex + 1);
    if (visibleCandles.length === 0) return;
    
    // Calculate price range
    const prices = visibleCandles.flatMap(c => [c.high, c.low]);
    const maxPrice = Math.max(...prices);
    const minPrice = Math.min(...prices);
    const priceRange = maxPrice - minPrice;
    const padding = priceRange * 0.1;
    
    const chartTop = 40;
    const chartBottom = height - 40;
    const chartLeft = 60;
    const chartRight = width - 60;
    const chartHeight = chartBottom - chartTop;
    const chartWidth = chartRight - chartLeft;
    
    // Draw grid
    ctx.strokeStyle = '#1a1f3a';
    ctx.lineWidth = 1;
    
    for (let i = 0; i <= 10; i++) {
      const y = chartTop + (chartHeight / 10) * i;
      ctx.beginPath();
      ctx.moveTo(chartLeft, y);
      ctx.lineTo(chartRight, y);
      ctx.stroke();
      
      const price = maxPrice + padding - ((maxPrice - minPrice + 2 * padding) / 10) * i;
      ctx.fillStyle = '#6b7280';
      ctx.font = '11px monospace';
      ctx.textAlign = 'right';
      ctx.fillText(price.toFixed(5), chartLeft - 10, y + 4);
    }
    
    // Draw candles
    const candleWidth = chartWidth / visibleCandles.length;
    const bodyWidth = Math.max(2, candleWidth * 0.7);
    
    visibleCandles.forEach((candle, i) => {
      const x = chartLeft + (i + 0.5) * candleWidth;
      const openY = chartTop + ((maxPrice + padding - candle.open) / (maxPrice - minPrice + 2 * padding)) * chartHeight;
      const closeY = chartTop + ((maxPrice + padding - candle.close) / (maxPrice - minPrice + 2 * padding)) * chartHeight;
      const highY = chartTop + ((maxPrice + padding - candle.high) / (maxPrice - minPrice + 2 * padding)) * chartHeight;
      const lowY = chartTop + ((maxPrice + padding - candle.low) / (maxPrice - minPrice + 2 * padding)) * chartHeight;
      
      const isGreen = candle.close >= candle.open;
      
      // Wick
      ctx.strokeStyle = isGreen ? '#22c55e' : '#ef4444';
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.moveTo(x, highY);
      ctx.lineTo(x, lowY);
      ctx.stroke();
      
      // Body
      ctx.fillStyle = isGreen ? '#22c55e' : '#ef4444';
      const bodyTop = Math.min(openY, closeY);
      const bodyHeight = Math.abs(closeY - openY) || 1;
      ctx.fillRect(x - bodyWidth / 2, bodyTop, bodyWidth, bodyHeight);
    });
    
    // Draw positions
    positions.forEach(pos => {
      const entryY = chartTop + ((maxPrice + padding - pos.entry) / (maxPrice - minPrice + 2 * padding)) * chartHeight;
      const slY = chartTop + ((maxPrice + padding - pos.sl) / (maxPrice - minPrice + 2 * padding)) * chartHeight;
      const tpY = chartTop + ((maxPrice + padding - pos.tp) / (maxPrice - minPrice + 2 * padding)) * chartHeight;
      
      // Entry line
      ctx.strokeStyle = pos.type === 'long' ? '#3b82f6' : '#f59e0b';
      ctx.lineWidth = 2;
      ctx.setLineDash([5, 5]);
      ctx.beginPath();
      ctx.moveTo(chartLeft, entryY);
      ctx.lineTo(chartRight, entryY);
      ctx.stroke();
      
      // SL line
      ctx.strokeStyle = '#ef4444';
      ctx.beginPath();
      ctx.moveTo(chartLeft, slY);
      ctx.lineTo(chartRight, slY);
      ctx.stroke();
      
      // TP line
      ctx.strokeStyle = '#22c55e';
      ctx.beginPath();
      ctx.moveTo(chartLeft, tpY);
      ctx.lineTo(chartRight, tpY);
      ctx.stroke();
      
      ctx.setLineDash([]);
    });
    
    // Draw drawings
    const allDrawings = [...drawings];
    if (tempDrawing) allDrawings.push(tempDrawing);
    
    allDrawings.forEach(drawing => {
      const startX = chartLeft + drawing.start.candleIndex * candleWidth;
      const endX = chartLeft + drawing.end.candleIndex * candleWidth;
      const startY = chartTop + ((maxPrice + padding - drawing.start.price) / (maxPrice - minPrice + 2 * padding)) * chartHeight;
      const endY = chartTop + ((maxPrice + padding - drawing.end.price) / (maxPrice - minPrice + 2 * padding)) * chartHeight;
      
      ctx.strokeStyle = '#fbbf24';
      ctx.lineWidth = 2;
      ctx.setLineDash([]);
      
      switch(drawing.type) {
        case 'trend':
        case 'horizontal':
        case 'vertical':
        case 'ray':
        case 'extended':
          ctx.beginPath();
          ctx.moveTo(startX, drawing.type === 'horizontal' ? startY : drawing.type === 'vertical' ? chartTop : startY);
          ctx.lineTo(endX, drawing.type === 'horizontal' ? startY : drawing.type === 'vertical' ? chartBottom : endY);
          ctx.stroke();
          break;
        case 'rectangle':
          ctx.strokeRect(startX, startY, endX - startX, endY - startY);
          break;
        case 'circle':
          const radius = Math.sqrt((endX - startX) ** 2 + (endY - startY) ** 2);
          ctx.beginPath();
          ctx.arc(startX, startY, radius, 0, Math.PI * 2);
          ctx.stroke();
          break;
        case 'path':
          ctx.beginPath();
          ctx.moveTo(startX, startY);
          ctx.lineTo(endX, endY);
          ctx.stroke();
          break;
      }
    });
    
    // Current price line
    const currentPriceY = chartTop + ((maxPrice + padding - currentPrice) / (maxPrice - minPrice + 2 * padding)) * chartHeight;
    ctx.strokeStyle = '#3b82f6';
    ctx.lineWidth = 2;
    ctx.setLineDash([3, 3]);
    ctx.beginPath();
    ctx.moveTo(chartLeft, currentPriceY);
    ctx.lineTo(chartRight, currentPriceY);
    ctx.stroke();
    ctx.setLineDash([]);
    
    // Price label
    ctx.fillStyle = '#3b82f6';
    ctx.fillRect(chartRight + 5, currentPriceY - 12, 65, 24);
    ctx.fillStyle = '#ffffff';
    ctx.font = 'bold 12px monospace';
    ctx.textAlign = 'left';
    ctx.fillText(currentPrice.toFixed(5), chartRight + 10, currentPriceY + 4);
    
  }, [candles, currentIndex, drawings, tempDrawing, positions, currentPrice]);

  // Backtesting controls
  useEffect(() => {
    if (mode === 'backtest' && isPlaying) {
      const interval = setInterval(() => {
        setCurrentIndex(prev => {
          if (prev >= candles.length - 1) {
            setIsPlaying(false);
            return prev;
          }
          return prev + 1;
        });
      }, 100);
      return () => clearInterval(interval);
    }
  }, [mode, isPlaying, candles.length]);

  // Calculate P&L
  const calculatePL = (pos) => {
    const priceDiff = pos.type === 'long' ? currentPrice - pos.entry : pos.entry - currentPrice;
    const pipValue = 10; // $10 per pip for 0.01 lot
    const pips = priceDiff * 10000;
    return (pips * pipValue * parseFloat(pos.lots)).toFixed(2);
  };

  const openOrder = (type) => {
    setOrderType(type);
    setEntryPrice(currentPrice.toFixed(5));
    setShowOrderDialog(true);
  };

  const placeOrder = () => {
    const newPos = {
      id: Date.now(),
      type: orderType,
      entry: parseFloat(entryPrice),
      sl: parseFloat(stopLoss),
      tp: parseFloat(takeProfit),
      lots: lots,
      openTime: Date.now()
    };
    setPositions([...positions, newPos]);
    setShowOrderDialog(false);
    setEntryPrice('');
    setStopLoss('');
    setTakeProfit('');
  };

  return (
    <div className="w-full h-screen bg-gray-900 text-white flex flex-col">
      {/* Header */}
      <div className="bg-gray-800 p-4 border-b border-gray-700">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <h1 className="text-2xl font-bold text-blue-400">EUR/USD</h1>
            <div className="text-3xl font-mono text-white">{currentPrice.toFixed(5)}</div>
          </div>
          
          {/* Timeframes */}
          <div className="flex gap-2">
            {['M1', 'M5', 'M15', 'M30', 'H1', 'H4', 'D1'].map(tf => (
              <button
                key={tf}
                onClick={() => setTimeframe(tf)}
                className={`px-3 py-1 rounded ${timeframe === tf ? 'bg-blue-500' : 'bg-gray-700 hover:bg-gray-600'}`}
              >
                {tf}
              </button>
            ))}
          </div>
          
          {/* Mode */}
          <div className="flex gap-2">
            <button
              onClick={() => setMode('live')}
              className={`px-4 py-2 rounded ${mode === 'live' ? 'bg-green-500' : 'bg-gray-700 hover:bg-gray-600'}`}
            >
              Live
            </button>
            <button
              onClick={() => setMode('backtest')}
              className={`px-4 py-2 rounded ${mode === 'backtest' ? 'bg-purple-500' : 'bg-gray-700 hover:bg-gray-600'}`}
            >
              Backtesting
            </button>
          </div>
        </div>
      </div>

      {/* Drawing Tools */}
      <div className="bg-gray-800 p-3 border-b border-gray-700 flex items-center gap-2 overflow-x-auto">
        <button onClick={() => setDrawingTool('trend')} className={`px-3 py-2 rounded flex items-center gap-2 ${drawingTool === 'trend' ? 'bg-yellow-500 text-black' : 'bg-gray-700 hover:bg-gray-600'}`}>
          <span>╱</span> Trend
        </button>
        <button onClick={() => setDrawingTool('horizontal')} className={`px-3 py-2 rounded flex items-center gap-2 ${drawingTool === 'horizontal' ? 'bg-yellow-500 text-black' : 'bg-gray-700 hover:bg-gray-600'}`}>
          <Minus size={16} /> Horizontal
        </button>
        <button onClick={() => setDrawingTool('vertical')} className={`px-3 py-2 rounded flex items-center gap-2 ${drawingTool === 'vertical' ? 'bg-yellow-500 text-black' : 'bg-gray-700 hover:bg-gray-600'}`}>
          <span>│</span> Vertical
        </button>
        <button onClick={() => setDrawingTool('rectangle')} className={`px-3 py-2 rounded flex items-center gap-2 ${drawingTool === 'rectangle' ? 'bg-yellow-500 text-black' : 'bg-gray-700 hover:bg-gray-600'}`}>
          <Square size={16} /> Rectangle
        </button>
        <button onClick={() => setDrawingTool('circle')} className={`px-3 py-2 rounded flex items-center gap-2 ${drawingTool === 'circle' ? 'bg-yellow-500 text-black' : 'bg-gray-700 hover:bg-gray-600'}`}>
          <Circle size={16} /> Circle
        </button>
        <button onClick={() => setDrawingTool('path')} className={`px-3 py-2 rounded flex items-center gap-2 ${drawingTool === 'path' ? 'bg-yellow-500 text-black' : 'bg-gray-700 hover:bg-gray-600'}`}>
          <Pencil size={16} /> Path
        </button>
        <button onClick={() => { setDrawings([]); setDrawingTool(null); }} className="px-3 py-2 rounded bg-red-600 hover:bg-red-700 flex items-center gap-2">
          <Trash2 size={16} /> Delete All
        </button>
      </div>

      {/* Chart */}
      <div className="flex-1 relative">
        <canvas
          ref={canvasRef}
          width={1400}
          height={700}
          className="w-full h-full cursor-crosshair"
          onMouseDown={handleMouseDown}
          onMouseMove={handleMouseMove}
          onMouseUp={handleMouseUp}
        />
      </div>

      {/* Controls */}
      {mode === 'backtest' && (
        <div className="bg-gray-800 p-4 border-t border-gray-700">
          <div className="flex items-center gap-4">
            <button onClick={() => setIsPlaying(!isPlaying)} className="p-2 bg-blue-500 rounded hover:bg-blue-600">
              {isPlaying ? <Pause size={20} /> : <Play size={20} />}
            </button>
            <button onClick={() => setCurrentIndex(Math.min(candles.length - 1, currentIndex + 1))} className="p-2 bg-gray-700 rounded hover:bg-gray-600">
              <SkipForward size={20} />
            </button>
            <button onClick={() => setCurrentIndex(0)} className="p-2 bg-gray-700 rounded hover:bg-gray-600">
              <RotateCcw size={20} />
            </button>
            <input
              type="range"
              min="0"
              max={candles.length - 1}
              value={currentIndex}
              onChange={(e) => setCurrentIndex(parseInt(e.target.value))}
              className="flex-1"
            />
            <span className="text-sm">{currentIndex} / {candles.length - 1}</span>
          </div>
        </div>
      )}

      {/* Trading Panel */}
      <div className="bg-gray-800 p-4 border-t border-gray-700">
        <div className="flex items-center justify-between">
          <div className="flex gap-4">
            <button onClick={() => openOrder('long')} className="px-6 py-3 bg-green-600 hover:bg-green-700 rounded-lg flex items-center gap-2 font-bold">
              <TrendingUp size={20} /> LONG
            </button>
            <button onClick={() => openOrder('short')} className="px-6 py-3 bg-red-600 hover:bg-red-700 rounded-lg flex items-center gap-2 font-bold">
              <TrendingDown size={20} /> SHORT
            </button>
          </div>
          
          {/* Positions Summary */}
          <div className="flex gap-6">
            <div>
              <div className="text-sm text-gray-400">Open Positions</div>
              <div className="text-xl font-bold">{positions.length}</div>
            </div>
            <div>
              <div className="text-sm text-gray-400">Total P&L</div>
              <div className={`text-xl font-bold ${positions.reduce((sum, pos) => sum + parseFloat(calculatePL(pos)), 0) >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                ${positions.reduce((sum, pos) => sum + parseFloat(calculatePL(pos)), 0).toFixed(2)}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Open Positions */}
      {positions.length > 0 && (
        <div className="bg-gray-800 p-4 border-t border-gray-700 max-h-48 overflow-y-auto">
          <h3 className="font-bold mb-2">Open Positions</h3>
          {positions.map(pos => (
            <div key={pos.id} className="flex items-center justify-between bg-gray-700 p-3 rounded mb-2">
              <div className="flex gap-4">
                <span className={`px-2 py-1 rounded font-bold ${pos.type === 'long' ? 'bg-green-600' : 'bg-red-600'}`}>
                  {pos.type.toUpperCase()}
                </span>
                <span>Entry: {pos.entry.toFixed(5)}</span>
                <span>SL: {pos.sl.toFixed(5)}</span>
                <span>TP: {pos.tp.toFixed(5)}</span>
                <span>Lots: {pos.lots}</span>
              </div>
              <div className="flex items-center gap-4">
                <span className={`text-xl font-bold ${parseFloat(calculatePL(pos)) >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                  ${calculatePL(pos)}
                </span>
                <button onClick={() => setPositions(positions.filter(p => p.id !== pos.id))} className="px-3 py-1 bg-red-600 hover:bg-red-700 rounded">
                  Close
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Order Dialog */}
      {showOrderDialog && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-gray-800 p-6 rounded-lg w-96">
            <h2 className="text-xl font-bold mb-4">{orderType === 'long' ? 'Long' : 'Short'} Position</h2>
            <div className="space-y-4">
              <div>
                <label className="block text-sm mb-1">Entry Price</label>
                <input type="number" value={entryPrice} onChange={(e) => setEntryPrice(e.target.value)} step="0.00001" className="w-full bg-gray-700 p-2 rounded" />
              </div>
              <div>
                <label className="block text-sm mb-1">Stop Loss</label>
                <input type="number" value={stopLoss} onChange={(e) => setStopLoss(e.target.value)} step="0.00001" className="w-full bg-gray-700 p-2 rounded" />
              </div>
              <div>
                <label className="block text-sm mb-1">Take Profit</label>
                <input type="number" value={takeProfit} onChange={(e) => setTakeProfit(e.target.value)} step="0.00001" className="w-full bg-gray-700 p-2 rounded" />
              </div>
              <div>
                <label className="block text-sm mb-1">Lots</label>
                <input type="number" value={lots} onChange={(e) => setLots(e.target.value)} step="0.01" className="w-full bg-gray-700 p-2 rounded" />
              </div>
              <div className="flex gap-2">
                <button onClick={placeOrder} className="flex-1 bg-blue-600 hover:bg-blue-700 py-2 rounded">Place Order</button>
                <button onClick={() => setShowOrderDialog(false)} className="flex-1 bg-gray-600 hover:bg-gray-700 py-2 rounded">Cancel</button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default EURUSDTradingApp;
