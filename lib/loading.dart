import 'package:flutter/material.dart';
import 'dart:math';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _hackGridOpacity;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _scanLinePosition;
  late Animation<double> _circlePulse;

  final List<String> _hackMessages = [
    'ЗАГРУЖАЕМ СИСТЕМУ...',
    'ШИФРУЕМ ДАННЫЕ...',
    'ВВОД ПОЛЕЗНОЙ НАГРУЗКИ...',
    'ЗАГРУЗКА БАЗЫ...',
    'ЗАХВАТ СИСТЕМЫ УПРАВЛЕНИЯ'
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );

    // Анимации
    _hackGridOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.1), weight: 1.0),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 1.0),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
    ));

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
    ));

    _scanLinePosition = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.linear),
    ));

    _circlePulse = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeInOut),
    ));

    _controller.forward();

    Future.delayed(const Duration(seconds: 7), () {
      Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Фоновый градиент
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.5),
                  radius: 1.5,
                  colors: [Colors.black, Color(0xFF1A1A1A)],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),

          // Cетка
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _hackGridOpacity.value,
                  child: CustomPaint(
                    painter: HackGridPainter(
                      scanLinePosition: _scanLinePosition.value,
                      intensity: _hackGridOpacity.value,
                    ),
                  ),
                );
              },
            ),
          ),

          // Пульсирующий круг (эффект сканирования)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: CirclePulsePainter(
                    progress: _circlePulse.value,
                  ),
                );
              },
            ),
          ),

          // Центральный логотип
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _logoScale.value,
                  child: Opacity(
                    opacity: _logoOpacity.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'dDNA',
                          style: TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                            letterSpacing: 10,
                            fontFamily: 'Courier',
                          ),
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: 300,
                          child: LinearProgressIndicator(
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withOpacity(0.5)),
                            minHeight: 1,
                            value: _controller.value > 0.7
                                ? (_controller.value - 0.7) * 3.33
                                : 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Сообщения
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final messageIndex = min(
                  (_controller.value * _hackMessages.length).floor(),
                  _hackMessages.length - 1,
                );
                return Text(
                  _hackMessages[messageIndex],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    letterSpacing: 3,
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                );
              },
            ),
          ),

          // Процент загрузки
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Text(
                  '${(_controller.value * 100).toInt()}%',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Courier',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class HackGridPainter extends CustomPainter {
  final double scanLinePosition;
  final double intensity;

  HackGridPainter({required this.scanLinePosition, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    final columns = 40;
    final rows = 60;
    final cellWidth = size.width / columns;
    final cellHeight = size.height / rows;

    // Основная сетка
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05 * intensity)
      ..strokeWidth = 0.5;

    // Вертикальные линии
    for (int i = 0; i < columns; i++) {
      if (i % 5 == 0) {
        canvas.drawLine(
          Offset(i * cellWidth, 0),
          Offset(i * cellWidth, size.height),
          gridPaint,
        );
      }
    }

    // Горизонтальные линии
    for (int i = 0; i < rows; i++) {
      if (i % 5 == 0) {
        canvas.drawLine(
          Offset(0, i * cellHeight),
          Offset(size.width, i * cellHeight),
          gridPaint,
        );
      }
    }

    for (int i = 0; i < columns; i++) {
      for (int j = 0; j < rows; j++) {
        if (random.nextDouble() < 0.1) {
          final textSpan = TextSpan(
            text: random.nextDouble() > 0.5 ? '0' : '1',
            style: TextStyle(
              color: Colors.white.withOpacity(random.nextDouble() * 0.5 * intensity),
              fontSize: 10,
              fontFamily: 'Courier',
            ),
          );
          
          final textPainter = TextPainter(
            text: textSpan,
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(
            canvas,
            Offset(i * cellWidth, j * cellHeight),
          );
        }
      }
    }

    // Сканирующая линия
    final scanLineY = scanLinePosition * size.height;
    final scanPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(0, scanLineY),
      Offset(size.width, scanLineY),
      scanPaint,
    );

    // Эффект свечения под сканирующей линией
    final glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.05),
          Colors.white.withOpacity(0.0),
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTRB(
        0, scanLineY - 20, size.width, scanLineY + 20));

    canvas.drawRect(
      Rect.fromLTRB(0, scanLineY - 20, size.width, scanLineY + 20),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CirclePulsePainter extends CustomPainter {
  final double progress;

  CirclePulsePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) * 0.8;

    // Внешний круг (пульсация)
    final pulsePaint = Paint()
      ..color = Colors.white.withOpacity(0.1 * (1 - progress))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(
      center,
      maxRadius * progress,
      pulsePaint,
    );

    // Внутренний круг
    final innerPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(
      center,
      maxRadius * 0.3,
      innerPaint,
    );

    // Радиальные линии
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 0.5;

    for (int i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      canvas.drawLine(
        center,
        Offset(
          center.dx + cos(angle) * maxRadius * 0.5,
          center.dy + sin(angle) * maxRadius * 0.5,
        ),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}