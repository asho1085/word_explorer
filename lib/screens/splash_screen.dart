import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'mode_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  double _progress = 0.0;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _animController.forward();

    // Simulated progress bar
    _progressTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted) return;
      setState(() {
        _progress += 0.02;
        if (_progress >= 1.0) {
          _progress = 1.0;
          _progressTimer?.cancel();
          _navigateToHome();
        }
      });
    });
  }

  void _navigateToHome() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (context, animation, secondaryAnimation) =>
              const ModeSelectionScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.bgDark,
              AppTheme.bgMedium,
              AppTheme.bgSurface,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Ambient glowing background orb
            Center(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.emerald.withAlpha(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.emerald.withAlpha(60),
                      blurRadius: 120,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
            ),

            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),

                      // Animated App Icon
                      AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Opacity(
                              opacity: _fadeAnimation.value,
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.emerald.withAlpha(100),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: Colors.black.withAlpha(140),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: Image.asset(
                              'assets/images/app_icon.png',
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) {
                                // Fallback icon container
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppTheme.emerald,
                                        AppTheme.blue,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.grid_4x4_rounded,
                                      color: Colors.white,
                                      size: 64,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Game Title
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            Text(
                              'WORD SEARCH',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4,
                                color: AppTheme.emerald,
                                shadows: [
                                  Shadow(
                                    color: AppTheme.emerald.withAlpha(120),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'EXPLORER',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Discover • Learn • Master Words',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.8,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Sleek loading progress indicator
                      Column(
                        children: [
                          Container(
                            width: 180,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppTheme.bgCard,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withAlpha(20),
                                width: 1,
                              ),
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 60),
                                width: 180 * _progress,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppTheme.emerald,
                                      AppTheme.blue,
                                      AppTheme.gold,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.emerald.withAlpha(180),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Loading levels & puzzles...',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
