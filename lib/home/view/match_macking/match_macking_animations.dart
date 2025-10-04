import 'dart:async';

import 'package:flutter/material.dart';

import 'dart:math' as math;

import 'package:get/get.dart';
import 'package:the_chess/values/colors.dart';

final List<String> imageList = [
  "assets/images/figures/black/knight.png",
  "assets/images/figures/white/bishop.png",
  "assets/images/figures/white/king.png",
  "assets/images/figures/white/rook.png",
];

// Controller class for managing state
class ImageSliderController extends GetxController {
  // Observable variables
  final _currentIndex = 0.obs;
  final _isPlaying = true.obs;
  Timer? _timer;

  // Getters for reactive variables
  int get currentIndex => _currentIndex.value;
  bool get isPlaying => _isPlaying.value;

  // Properties for configuration
  Duration duration = const Duration(seconds: 1);
  List<String> imagePaths = [];

  @override
  void onInit() {
    super.onInit();
    startSlideShow();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  void initialize(List<String> paths, Duration slideDuration) {
    imagePaths = paths;
    duration = slideDuration;
    if (_isPlaying.value) {
      startSlideShow();
    }
  }

  void startSlideShow() {
    _timer?.cancel();
    if (imagePaths.isEmpty) return;

    _timer = Timer.periodic(duration, (timer) {
      _currentIndex.value = (_currentIndex.value + 1) % imagePaths.length;
    });
  }

  void stopSlideShow() {
    _timer?.cancel();
    _timer = null;
  }

  void togglePlayPause() {
    _isPlaying.value = !_isPlaying.value;
    if (_isPlaying.value) {
      startSlideShow();
    } else {
      stopSlideShow();
    }
  }

  void nextImage() {
    if (imagePaths.isEmpty) return;
    _currentIndex.value = (_currentIndex.value + 1) % imagePaths.length;
  }

  void previousImage() {
    if (imagePaths.isEmpty) return;
    _currentIndex.value = _currentIndex.value == 0
        ? imagePaths.length - 1
        : _currentIndex.value - 1;
  }

  void goToImage(int index) {
    if (index >= 0 && index < imagePaths.length) {
      _currentIndex.value = index;
    }
  }
}

// Widget class using GetX
class SimpleVerticalImageSlider extends StatelessWidget {
  final List<String> imagePaths;
  final Duration duration;
  final double height;
  final double width;
  final bool showControls;
  final String? tag; // For multiple sliders

  const SimpleVerticalImageSlider({
    super.key,
    required this.imagePaths,
    this.duration = const Duration(seconds: 1),
    this.height = 100,
    this.width = 100,
    this.showControls = true,
    this.tag,
  });

  @override
  Widget build(BuildContext context) {
    // Get or create controller with optional tag for multiple instances
    final controller = Get.put(
      ImageSliderController(),
      tag: tag,
    );

    // Initialize controller with current widget parameters
    controller.initialize(imagePaths, duration);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              height: height,
              width: width,
              clipBehavior: Clip.hardEdge,
              child: Obx(() {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 1.0),
                        end: const Offset(0.0, 0.0),
                      ).animate(animation),
                      child: child,
                    );
                  },
                  child: imagePaths.isNotEmpty
                      ? Image.asset(
                          imagePaths[controller.currentIndex],
                          key: ValueKey<int>(controller.currentIndex),
                          fit: BoxFit.cover,
                          height: height,
                          width: width,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[400],
                              child: const Icon(
                                Icons.error,
                                color: Colors.red,
                              ),
                            );
                          },
                        )
                      : Container(
                          key: const ValueKey('empty'),
                          color: Colors.grey[400],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        ),
                );
              }),
            ),
          ],
        ),

        // Control buttons
        if (showControls && imagePaths.isNotEmpty) ...[
          const SizedBox(height: 8),
          // Obx(() {
          //   return Row(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       // IconButton(
          //       //   onPressed: controller.togglePlayPause,
          //       //   icon: Icon(
          //       //       controller.isPlaying ? Icons.pause : Icons.play_arrow),
          //       //   tooltip: controller.isPlaying ? 'Pause' : 'Play',
          //       //   iconSize: 24,
          //       // ),
          //     ],
          //   );
          // }),
        ],
      ],
    );
  }
}

// Controller for VS Battle animation state
class VSBattleController extends GetxController
    with GetTickerProviderStateMixin {
  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _clashController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _colorController;

  // Animations
  late Animation<Offset> _vSlideAnimation;
  late Animation<Offset> _sSlideAnimation;
  late Animation<double> _vRotationAnimation;
  late Animation<double> _sRotationAnimation;
  late Animation<double> _vScaleAnimation;
  late Animation<double> _sScaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveScaleAnimation;
  late Animation<double> _waveOpacityAnimation;
  late Animation<double> _redColorAnimation;
  late Animation<double> _blueColorAnimation;

  // Reactive variables
  final _isVisible = false.obs;
  final _isAnimating = false.obs;

  // Getters
  bool get isVisible => _isVisible.value;
  bool get isAnimating => _isAnimating.value;

  // Animation getters
  Animation<Offset> get vSlideAnimation => _vSlideAnimation;
  Animation<Offset> get sSlideAnimation => _sSlideAnimation;
  Animation<double> get vRotationAnimation => _vRotationAnimation;
  Animation<double> get sRotationAnimation => _sRotationAnimation;
  Animation<double> get vScaleAnimation => _vScaleAnimation;
  Animation<double> get sScaleAnimation => _sScaleAnimation;
  Animation<double> get pulseAnimation => _pulseAnimation;
  Animation<double> get waveScaleAnimation => _waveScaleAnimation;
  Animation<double> get waveOpacityAnimation => _waveOpacityAnimation;
  Animation<double> get redColorAnimation => _redColorAnimation;
  Animation<double> get blueColorAnimation => _blueColorAnimation;

  @override
  void onInit() {
    super.onInit();
    initializeControllers();
    setupAnimations();
  }

  @override
  void onClose() {
    _slideController.dispose();
    _clashController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    _colorController.dispose();
    super.onClose();
  }

  void initializeControllers() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _clashController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _colorController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  void setupAnimations() {
    // Slide animations for V and S
    _vSlideAnimation = Tween<Offset>(
      begin: const Offset(-2.0, 0.0),
      end: const Offset(-0.15, 0.0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _sSlideAnimation = Tween<Offset>(
      begin: const Offset(2.0, 0.0),
      end: const Offset(0.15, 0.0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    // Rotation animations
    _vRotationAnimation = Tween<double>(
      begin: -math.pi,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _sRotationAnimation = Tween<double>(
      begin: math.pi,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    // Scale animations for entrance effect
    _vScaleAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _sScaleAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    // Color animations
    _redColorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _colorController,
      curve: Curves.easeInOut,
    ));

    _blueColorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _colorController,
      curve: Curves.easeInOut,
    ));

    // Wave effect animations
    _waveScaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.8,
    ).animate(CurvedAnimation(
      parent: _clashController,
      curve: Curves.easeOut,
    ));

    _waveOpacityAnimation = Tween<double>(
      begin: 0.8,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _clashController,
      curve: Curves.easeOut,
    ));

    // Pulse animation for the circle
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void startVSAnimation() async {
    _isVisible.value = true;

    // Stop all controllers first
    _slideController.stop();
    _clashController.stop();
    _pulseController.stop();
    _rotationController.stop();

    // Reset all controllers
    _slideController.reset();
    _clashController.reset();
    _pulseController.reset();
    _rotationController.reset();

    startAnimationSequenceForVSonly();
    update();
  }

  Future<void> startAnimationSequenceForVSonly() async {
    if (_isAnimating.value) return;

    _isAnimating.value = true;
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();

    await _slideController.forward();
    await Future.delayed(const Duration(milliseconds: 300));

    // Use forward instead of repeat to avoid freezing
    _clashController.forward();

    _isAnimating.value = false;
  }

  Future<void> startAnimationSequence() async {
    if (_isAnimating.value) return;

    _isAnimating.value = true;
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
    _colorController.forward();

    await _slideController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    await _clashController.forward();

    _isAnimating.value = false;
  }

  void restartAnimation() {
    _isVisible.value = true;
    _slideController.reset();
    _clashController.reset();
    _colorController.reset();
    startAnimationSequence();
    update(); // Trigger rebuild for GetBuilder
  }

  void stopAnimation() {
    _pulseController.stop();
    _rotationController.stop();
    _slideController.stop();
    _clashController.stop();
    _colorController.stop();
    _isAnimating.value = false;
  }

  void hideVS() {
    _isVisible.value = false;
  }

  void showVS() {
    _isVisible.value = true;
  }
}

// Updated VSBattleWidget using GetX
class VSBattleWidget extends StatelessWidget {
  final String? tag;
  final bool showRestartButton;

  const VSBattleWidget({
    super.key,
    this.tag,
    this.showRestartButton = true,
  });

  @override
  Widget build(BuildContext context) {
    // Get or create controller
    final controller = Get.put(VSBattleController(), tag: tag);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.3, -0.7),
            radius: 1.2,
            colors: [
              MyColors.lightGray.withValues(alpha: 0.8),
              MyColors.darkBackground,
              MyColors.lightGray,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated color backgrounds
            _buildAnimatedColorBackground(controller),

            // Main VS container
            Obx(() {
              return Visibility(
                visible: controller.isVisible,
                child: Center(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _buildEnergyWave(controller),
                        _buildCentralCircle(controller),
                        _buildVLetter(controller),
                        _buildSLetter(controller),
                      ],
                    ),
                  ),
                ),
              );
            }),

            // Restart button
            //  _buildRestartButton(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedColorBackground(VSBattleController controller) {
    return AnimatedBuilder(
      animation: controller._colorController,
      builder: (context, child) {
        return Stack(
          children: [
            ClipPath(
              clipper: DiagonalClipper(
                progress: controller.redColorAnimation.value,
                isFromTopLeft: true,
              ),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: MyColors.lightGray, // MyColors.lightGray equivalent
              ),
            ),
            ClipPath(
              clipper: DiagonalClipper(
                progress: controller.blueColorAnimation.value,
                isFromTopLeft: false,
              ),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: MyColors.tealGray, // MyColors.mediumGray equivalent
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCentralCircle(VSBattleController controller) {
    return AnimatedBuilder(
      animation: controller.pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: controller.pulseAnimation.value,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 6),
              color: Colors.white.withValues(alpha: 0.1),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVLetter(VSBattleController controller) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        controller._slideController,
        controller._colorController,
      ]),
      builder: (context, child) {
        return SlideTransition(
          position: controller.vSlideAnimation,
          child: Transform.rotate(
            angle: controller.vRotationAnimation.value,
            child: Transform.scale(
              scale: controller.vScaleAnimation.value,
              child: Text(
                'V',
                style: TextStyle(
                  fontSize: 100,
                  fontWeight: FontWeight.w900,
                  foreground: Paint()
                    ..shader = LinearGradient(
                      colors: [
                        Color.lerp(Colors.white, const Color(0xFFFF4444),
                                controller.redColorAnimation.value) ??
                            Colors.white,
                        Colors.white,
                      ],
                    ).createShader(const Rect.fromLTWH(0.0, 0.0, 100.0, 100.0)),
                  shadows: const [
                    Shadow(
                      offset: Offset(4, 4),
                      blurRadius: 8,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSLetter(VSBattleController controller) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        controller._slideController,
        controller._colorController,
      ]),
      builder: (context, child) {
        return SlideTransition(
          position: controller.sSlideAnimation,
          child: Transform.rotate(
            angle: controller.sRotationAnimation.value,
            child: Transform.scale(
              scale: controller.sScaleAnimation.value,
              child: Text(
                'S',
                style: TextStyle(
                  fontSize: 100,
                  fontWeight: FontWeight.w900,
                  foreground: Paint()
                    ..shader = LinearGradient(
                      colors: [
                        Color.lerp(Colors.white, const Color(0xFF9CA3AF),
                                controller.blueColorAnimation.value) ??
                            Colors.white,
                        Colors.white,
                      ],
                    ).createShader(const Rect.fromLTWH(0.0, 0.0, 100.0, 100.0)),
                  shadows: const [
                    Shadow(
                      offset: Offset(4, 4),
                      blurRadius: 8,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnergyWave(VSBattleController controller) {
    return AnimatedBuilder(
      animation: controller._clashController,
      builder: (context, child) {
        return Opacity(
          opacity: controller.waveOpacityAnimation.value,
          child: Transform.scale(
            scale: controller.waveScaleAnimation.value,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.8),
                  width: 3,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF9CA3AF),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Color(0xFF6B7280),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  // TODO: ResetAmination Buttion
  // Widget _buildRestartButton(VSBattleController controller) {
  //   return Positioned(
  //     bottom: 50,
  //     left: 0,
  //     right: 0,
  //     child: Center(
  //       child: Obx(() {
  //         return ElevatedButton(
  //           onPressed:
  //               controller.isAnimating ? null : controller.restartAnimation,
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: Colors.white.withValues(alpha:0.2),
  //             foregroundColor: Colors.white,
  //             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  //             shape: RoundedRectangleBorder(
  //               borderRadius: BorderRadius.circular(25),
  //               side: const BorderSide(color: Colors.white, width: 2),
  //             ),
  //           ),
  //           child: Text(
  //             controller.isAnimating ? 'Animating...' : 'Restart Battle',
  //             style: const TextStyle(
  //               fontWeight: FontWeight.bold,
  //               fontSize: 16,
  //             ),
  //           ),
  //         );
  //       }),
  //     ),
  //   );
  // }
}

// Custom clipper remains the same
class DiagonalClipper extends CustomClipper<Path> {
  final double progress;
  final bool isFromTopLeft;

  DiagonalClipper({
    required this.progress,
    required this.isFromTopLeft,
  });

  @override
  Path getClip(Size size) {
    final path = Path();

    if (isFromTopLeft) {
      final diagonal =
          math.sqrt(size.width * size.width + size.height * size.height);
      final currentDistance = diagonal * progress * 1;
      final angle = math.atan2(size.height, size.width);
      final endX = currentDistance * math.cos(angle);
      final endY = currentDistance * math.sin(angle);

      path.moveTo(0, 0);
      path.lineTo(endX, 0);
      path.lineTo(0, endY);
      path.close();
    } else {
      final diagonal =
          math.sqrt(size.width * size.width + size.height * size.height);
      final currentDistance = diagonal * progress * 1;
      final angle = math.atan2(size.height, size.width);
      final startX = size.width - currentDistance * math.cos(angle);
      final startY = size.height - currentDistance * math.sin(angle);

      path.moveTo(size.width, size.height);
      path.lineTo(startX, size.height);
      path.lineTo(size.width, startY);
      path.close();
    }

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return oldClipper is DiagonalClipper &&
        (oldClipper.progress != progress ||
            oldClipper.isFromTopLeft != isFromTopLeft);
  }
}
