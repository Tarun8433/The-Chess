import 'dart:math' show pi;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:the_chess/values/colors.dart';

/// Build custom style with (context, animationValue, slideWidth, menuScreen, mainScreen) {}
typedef DrawerStyleBuilder = Widget Function(
  BuildContext context,
  double animationValue,
  double slideWidth,
  Widget menuScreen,
  Widget mainScreen,
);

class ZoomDrawer extends StatefulWidget {
  const ZoomDrawer({
    super.key,
    required this.menuScreen,
    required this.mainScreen,
    this.style = DrawerStyle.defaultStyle,
    this.controller,
    this.mainScreenScale = 0.3,
    this.slideWidth = 275.0,
    this.slideHeight = 0,
    this.menuScreenWidth,
    this.borderRadius = 16.0,
    this.angle = -12.0,
    this.dragOffset = 60.0,
    this.openDragSensitivity = 425,
    this.closeDragSensitivity = 425,
    this.drawerShadowsBackgroundColor = const Color(0xffffffff),
    this.menuBackgroundColor = Colors.transparent,
    this.mainScreenOverlayColor,
    this.menuScreenOverlayColor,
    this.overlayBlend = BlendMode.srcATop,
    this.overlayBlur,
    this.shadowLayer1Color,
    this.shadowLayer2Color,
    this.showShadow = false,
    this.openCurve = const Interval(0.0, 1.0, curve: Curves.easeOut),
    this.closeCurve = const Interval(0.0, 1.0, curve: Curves.easeOut),
    this.duration = const Duration(milliseconds: 250),
    this.reverseDuration = const Duration(milliseconds: 250),
    this.androidCloseOnBackTap = false,
    this.moveMenuScreen = true,
    this.disableDragGesture = false,
    this.isRtl = false,
    this.clipMainScreen = true,
    this.mainScreenTapClose = false,
    this.menuScreenTapClose = false,
    this.mainScreenAbsorbPointer = true,
    this.shrinkMainScreen = false,
    this.boxShadow,
    this.drawerStyleBuilder,
    // Enhanced properties
    this.alwaysVisible = false,
    this.enableInteraction = true,
    this.responsiveBreakpoint = 768,
  });

  /// Layout style
  final DrawerStyle style;

  /// controller to have access to the open/close/toggle function of the drawer
  final ZoomDrawerController? controller;

  /// Screen containing the menu/bottom screen
  final Widget menuScreen;

  /// Screen containing the main content to display
  final Widget mainScreen;

  /// MainScreen scale factor
  final double mainScreenScale;

  /// Sliding width of the drawer
  final double slideWidth;

  /// Sliding height of the drawer
  final double slideHeight;

  /// menuScreen Width
  /// Set it to double.infinity to make it take screen width
  final double? menuScreenWidth;

  /// Border radius of the slide content
  final double borderRadius;

  /// Rotation angle of the drawer
  final double angle;

  /// Background color of the menuScreen
  final Color menuBackgroundColor;

  /// Background color of the drawer shadows
  final Color drawerShadowsBackgroundColor;

  /// First shadow background color
  final Color? shadowLayer1Color;

  /// Second shadow background color
  final Color? shadowLayer2Color;

  /// Boolean, whether to show the drawer shadows - Applies to defaultStyle only
  final bool showShadow;

  /// Close drawer on android back button
  final bool androidCloseOnBackTap;

  /// Make menuScreen slide along with mainScreen animation
  final bool moveMenuScreen;

  /// Drawer slide out curve
  final Curve openCurve;

  /// Drawer slide in curve
  final Curve closeCurve;

  /// Drawer forward Duration
  final Duration duration;

  /// Drawer reverse Duration
  final Duration reverseDuration;

  /// Disable swipe gesture
  final bool disableDragGesture;

  /// display the drawer in RTL
  final bool isRtl;

  /// Depreciated: Set [borderRadius] to 0 instead
  final bool clipMainScreen;

  /// The offset to trigger drawer drag
  final double dragOffset;

  /// How fast the opening drawer drag in response to a touch
  final double openDragSensitivity;

  /// How fast the closing drawer drag in response to a touch
  final double closeDragSensitivity;

  /// Color of the main screen's cover overlay
  final Color? mainScreenOverlayColor;

  /// Color of the menu screen's cover overlay
  final Color? menuScreenOverlayColor;

  /// The BlendMode of the overlay filter
  final BlendMode overlayBlend;

  /// Apply a Blur amount to the mainScreen
  final double? overlayBlur;

  /// The Shadow of the mainScreenWidget
  final List<BoxShadow>? boxShadow;

  /// Close drawer when tapping menuScreen
  final bool menuScreenTapClose;

  /// Close drawer when tapping mainScreen
  final bool mainScreenTapClose;

  /// Prevent touches to mainScreen while drawer is open
  final bool mainScreenAbsorbPointer;

  /// Shrinks the mainScreen by [slideWidth]
  final bool shrinkMainScreen;

  /// Build custom animated style
  final DrawerStyleBuilder? drawerStyleBuilder;

  /// Always keep drawer visible (for tablet/desktop)
  final bool alwaysVisible;

  /// Enable interaction with both drawer and main screen
  final bool enableInteraction;

  /// Screen width breakpoint for responsive behavior
  final double responsiveBreakpoint;

  @override
  ZoomDrawerState createState() => ZoomDrawerState();

  /// static function to provide the drawer state
  static ZoomDrawerState? of(BuildContext context) =>
      context.findAncestorStateOfType<ZoomDrawerState>();
}

class ZoomDrawerState extends State<ZoomDrawer>
    with SingleTickerProviderStateMixin {
  /// Triggers drag animation
  bool _shouldDrag = false;

  /// Decides where the drawer will reside in screen
  late int _slideDirection;

  /// Once drawer is open, _absorbingMainScreen will absorb any pointer
  late final ValueNotifier<bool> _absorbingMainScreen;

  /// Drawer state
  final ValueNotifier<DrawerState> _stateNotifier =
      ValueNotifier(DrawerState.closed);

  ValueNotifier<DrawerState> get stateNotifier => _stateNotifier;

  late final AnimationController _animationController = AnimationController(
    vsync: this,
    duration: widget.duration,
    reverseDuration: widget.duration,
  )..addStatusListener(_animationStatusListener);

  double get _animationValue => _animationController.value;

  /// Drawer last action state
  DrawerLastAction _drawerLastAction = DrawerLastAction.closed;

  DrawerLastAction get drawerLastAction => _drawerLastAction;

  /// Check if drawer should be always visible based on screen size
  bool get _shouldBeAlwaysVisible {
    if (!widget.alwaysVisible) return false;
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth >= widget.responsiveBreakpoint;
  }

  /// Check whether drawer is open
  bool isOpen() =>
      stateNotifier.value == DrawerState.open || _shouldBeAlwaysVisible;

  /// Decides if drag animation should start according to dragOffset
  void _onHorizontalDragStart(DragStartDetails startDetails) {
    // Don't allow drag if always visible
    if (_shouldBeAlwaysVisible) return;

    final maxDragSlide = widget.isRtl
        ? context.screenWidth - widget.dragOffset
        : widget.dragOffset;

    final toggleValue = widget.isRtl
        ? _animationController.isCompleted
        : _animationController.isDismissed;

    final isDraggingFromLeft =
        toggleValue && startDetails.globalPosition.dx < maxDragSlide;

    final isDraggingFromRight =
        !toggleValue && startDetails.globalPosition.dx > maxDragSlide;

    _shouldDrag = isDraggingFromLeft || isDraggingFromRight;
  }

  /// Update animation value during drag
  void _onHorizontalDragUpdate(DragUpdateDetails updateDetails) {
    if (_shouldBeAlwaysVisible) return;

    if (_shouldDrag == false &&
        ![DrawerState.opening, DrawerState.closing]
            .contains(_stateNotifier.value)) {
      return;
    }

    final dragSensitivity = drawerLastAction == DrawerLastAction.open
        ? widget.closeDragSensitivity
        : widget.openDragSensitivity;

    final delta = updateDetails.primaryDelta ?? 0 / widget.dragOffset;

    if (widget.isRtl) {
      _animationController.value -= delta / dragSensitivity;
    } else {
      _animationController.value += delta / dragSensitivity;
    }
  }

  /// Handle drag end
  void _onHorizontalDragEnd(DragEndDetails dragEndDetails) {
    if (_shouldBeAlwaysVisible) return;

    if (_animationController.isDismissed || _animationController.isCompleted) {
      return;
    }

    const minFlingVelocity = 350.0;
    final dragVelocity = dragEndDetails.velocity.pixelsPerSecond.dx.abs();
    final willFling = dragVelocity > minFlingVelocity;

    if (willFling) {
      final visualVelocityInPx = dragEndDetails.velocity.pixelsPerSecond.dx /
          (context.screenWidth * 50);

      final visualVelocityInPxRTL = -visualVelocityInPx;

      _animationController.fling(
        velocity: widget.isRtl ? visualVelocityInPxRTL : visualVelocityInPx,
        animationBehavior: AnimationBehavior.preserve,
      );
    } else if (drawerLastAction == DrawerLastAction.open) {
      if (_animationController.value > 0.65) {
        open();
        return;
      }
      close();
    } else if (drawerLastAction == DrawerLastAction.closed) {
      if (_animationController.value < 0.35) {
        close();
        return;
      }
      open();
    }
  }

  /// Close drawer on Tap
  void _mainScreenTapHandler() {
    if (widget.mainScreenTapClose &&
        stateNotifier.value == DrawerState.open &&
        !_shouldBeAlwaysVisible) {
      close();
    }
  }

  void _menuScreenTapHandler() {
    if (widget.menuScreenTapClose &&
        stateNotifier.value == DrawerState.open &&
        !_shouldBeAlwaysVisible) {
      close();
    }
  }

  /// Open drawer
  TickerFuture? open() {
    if (mounted && !_shouldBeAlwaysVisible) {
      return _animationController.forward();
    }
    return null;
  }

  /// Close drawer
  TickerFuture? close() {
    if (mounted && !_shouldBeAlwaysVisible) {
      return _animationController.reverse();
    }
    return null;
  }

  /// Toggle drawer
  TickerFuture? toggle({bool forceToggle = false}) {
    if (_shouldBeAlwaysVisible) return null;

    if (stateNotifier.value == DrawerState.open ||
        (forceToggle && drawerLastAction == DrawerLastAction.open)) {
      return close();
    } else if (stateNotifier.value == DrawerState.closed ||
        (forceToggle && drawerLastAction == DrawerLastAction.closed)) {
      return open();
    }
    return null;
  }

  /// Assign widget methods to controller
  void _assignToController() {
    if (widget.controller == null) return;

    widget.controller!.open = open;
    widget.controller!.close = close;
    widget.controller!.toggle = toggle;
    widget.controller!.isOpen = isOpen;
    widget.controller!.stateNotifier = stateNotifier;
  }

  /// Updates stateNotifier and other states
  void _animationStatusListener(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.forward:
        if (drawerLastAction == DrawerLastAction.open &&
            _animationController.value < 1) {
          _stateNotifier.value = DrawerState.closing;
        } else {
          _stateNotifier.value = DrawerState.opening;
        }
        break;
      case AnimationStatus.reverse:
        if (drawerLastAction == DrawerLastAction.closed &&
            _animationController.value > 0) {
          _stateNotifier.value = DrawerState.opening;
        } else {
          _stateNotifier.value = DrawerState.closing;
        }
        break;
      case AnimationStatus.completed:
        _stateNotifier.value = DrawerState.open;
        _drawerLastAction = DrawerLastAction.open;
        _absorbingMainScreen.value = widget.mainScreenAbsorbPointer &&
            !widget.enableInteraction &&
            !_shouldBeAlwaysVisible;
        break;
      case AnimationStatus.dismissed:
        _stateNotifier.value = DrawerState.closed;
        _drawerLastAction = DrawerLastAction.closed;
        _absorbingMainScreen.value = false;
        break;
    }
  }

  @override
  void initState() {
    super.initState();

    _absorbingMainScreen = ValueNotifier(false);
    _assignToController();
    _slideDirection = widget.isRtl ? -1 : 1;

    // Auto-open if should be always visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_shouldBeAlwaysVisible) {
        _animationController.value = 1.0;
        _stateNotifier.value = DrawerState.open;
        _drawerLastAction = DrawerLastAction.open;
      }
    });
  }

  @override
  void didUpdateWidget(covariant ZoomDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isRtl != widget.isRtl) {
      _slideDirection = widget.isRtl ? -1 : 1;
    }

    // Handle responsive changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_shouldBeAlwaysVisible && _animationController.value != 1.0) {
        _animationController.value = 1.0;
        _stateNotifier.value = DrawerState.open;
        _drawerLastAction = DrawerLastAction.open;
      } else if (!_shouldBeAlwaysVisible &&
          !widget.alwaysVisible &&
          _animationController.value == 1.0) {
        // Close drawer when screen becomes mobile
        close();
      }
    });
  }

  @override
  void dispose() {
    _stateNotifier.dispose();
    _absorbingMainScreen.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Build the widget based on the animation value
  Widget _applyDefaultStyle(
    Widget? child, {
    double? angle,
    double scale = 1,
    double slide = 0,
  }) {
    double slidePercent;
    double scalePercent;

    // Force full opening for always visible mode
    if (_shouldBeAlwaysVisible) {
      slidePercent = 1.0;
      scalePercent = 1.0;
    } else {
      switch (stateNotifier.value) {
        case DrawerState.closed:
          slidePercent = 0.0;
          scalePercent = 0.0;
          break;
        case DrawerState.open:
          slidePercent = 1.0;
          scalePercent = 1.0;
          break;
        case DrawerState.opening:
          slidePercent = (widget.openCurve).transform(_animationValue);
          scalePercent = Interval(0.0, 0.3, curve: widget.openCurve)
              .transform(_animationValue);
          break;
        case DrawerState.closing:
          slidePercent = (widget.closeCurve).transform(_animationValue);
          scalePercent = Interval(0.0, 1.0, curve: widget.closeCurve)
              .transform(_animationValue);
          break;
      }
    }

    final effectiveAnimationValue =
        _shouldBeAlwaysVisible ? 1.0 : _animationValue;

    /// Sliding X
    final xPosition = ((widget.slideWidth - slide) *
            effectiveAnimationValue *
            _slideDirection) *
        slidePercent;

    /// Sliding Y
    final yPosition = ((widget.slideHeight - slide) *
            effectiveAnimationValue *
            _slideDirection) *
        slidePercent;

    /// Scale
    final scalePercentage = scale - (widget.mainScreenScale * scalePercent);

    /// BorderRadius
    final radius = widget.borderRadius * effectiveAnimationValue;

    /// Rotation
    final rotationAngle =
        ((((angle ?? widget.angle) * pi) / 180) * effectiveAnimationValue) *
            _slideDirection;

    return Transform(
      transform: Matrix4.translationValues(xPosition, yPosition, 0.0)
        ..rotateZ(rotationAngle)
        ..scale(scalePercentage, scalePercentage),
      alignment: widget.isRtl ? Alignment.centerRight : Alignment.centerLeft,
      child: scale == 1
          ? child
          : ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: child,
            ),
    );
  }

  /// Builds the layers of menuScreen
  Widget get menuScreenWidget {
    final effectiveAnimationValue =
        _shouldBeAlwaysVisible ? 1.0 : _animationValue;

    Widget menuScreen = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _shouldBeAlwaysVisible ? null : _menuScreenTapHandler,
      child: SizedBox.expand(
        child: Align(
          alignment: widget.isRtl ? Alignment.topRight : Alignment.topLeft,
          child: SizedBox(
            width: widget.menuScreenWidth ??
                (widget.slideWidth -
                    (context.screenWidth / widget.slideWidth) -
                    50),
            child: widget.menuScreen,
          ),
        ),
      ),
    );

    // Transform for menu animation
    if (widget.moveMenuScreen && widget.style != DrawerStyle.style1) {
      final left =
          (1 - effectiveAnimationValue) * widget.slideWidth * _slideDirection;
      menuScreen = Transform.translate(
        offset: Offset(-left, 0),
        child: menuScreen,
      );
    }

    // Add overlay color
    if (widget.menuScreenOverlayColor != null) {
      final overlayColor = ColorTween(
        begin: widget.menuScreenOverlayColor,
        end: widget.menuScreenOverlayColor!.withOpacity(0.0),
      );

      menuScreen = ColorFiltered(
        colorFilter: ColorFilter.mode(
          overlayColor.lerp(effectiveAnimationValue)!,
          widget.overlayBlend,
        ),
        child: ColoredBox(
          color: widget.menuBackgroundColor,
          child: menuScreen,
        ),
      );
    } else {
      menuScreen = Container(
        decoration: BoxDecoration(
          color: widget.menuBackgroundColor,
          gradient: const LinearGradient(
            colors: [MyColors.lightGray, MyColors.tealGray],
            begin: Alignment.topRight,
            end: Alignment.bottomRight,
          ),
        ),
        child: menuScreen,
      );
    }

    return menuScreen;
  }

  /// Builds the layers of mainScreen
  Widget get mainScreenWidget {
    Widget mainScreen = widget.mainScreen;
    final effectiveAnimationValue =
        _shouldBeAlwaysVisible ? 1.0 : _animationValue;

    // Shrink screen if needed
    if (widget.shrinkMainScreen) {
      final mainSize =
          context.screenWidth - (widget.slideWidth * effectiveAnimationValue);
      mainScreen = SizedBox(
        width: mainSize > 0 ? mainSize : context.screenWidth,
        child: mainScreen,
      );
    }

    // Add overlay color
    if (widget.mainScreenOverlayColor != null && !_shouldBeAlwaysVisible) {
      final overlayColor = ColorTween(
        begin: widget.mainScreenOverlayColor!.withOpacity(0.0),
        end: widget.mainScreenOverlayColor,
      );
      mainScreen = ColorFiltered(
        colorFilter: ColorFilter.mode(
          overlayColor.lerp(effectiveAnimationValue)!,
          widget.overlayBlend,
        ),
        child: mainScreen,
      );
    }

    // Add border radius
    if (widget.borderRadius != 0 && !_shouldBeAlwaysVisible) {
      final borderRadius = widget.borderRadius * effectiveAnimationValue;
      mainScreen = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: mainScreen,
      );
    }

    // Add box shadow
    if (widget.boxShadow != null && !_shouldBeAlwaysVisible) {
      final radius = widget.borderRadius * effectiveAnimationValue;
      mainScreen = Container(
        margin: EdgeInsets.all(8.0 * effectiveAnimationValue),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: widget.boxShadow,
        ),
        child: mainScreen,
      );
    }

    // Add rotation for non-default styles
    if (widget.angle != 0 &&
        widget.style != DrawerStyle.defaultStyle &&
        !_shouldBeAlwaysVisible) {
      final rotationAngle = (((widget.angle) * pi * _slideDirection) / 180) *
          effectiveAnimationValue;
      mainScreen = Transform.rotate(
        angle: rotationAngle,
        alignment: widget.isRtl
            ? AlignmentDirectional.topEnd
            : AlignmentDirectional.topStart,
        child: mainScreen,
      );
    }

    // Add blur effect
    if (widget.overlayBlur != null && !_shouldBeAlwaysVisible) {
      final blurAmount = widget.overlayBlur! * effectiveAnimationValue;
      mainScreen = ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: blurAmount,
          sigmaY: blurAmount,
        ),
        child: mainScreen,
      );
    }

    // Handle pointer absorption for interaction
    if (widget.mainScreenAbsorbPointer && !widget.enableInteraction) {
      mainScreen = Stack(
        children: [
          mainScreen,
          ValueListenableBuilder(
            valueListenable: _absorbingMainScreen,
            builder: (_, bool valueNotifier, ___) {
              if (valueNotifier &&
                  stateNotifier.value == DrawerState.open &&
                  !_shouldBeAlwaysVisible) {
                return AbsorbPointer(
                  child: Container(
                    color: Colors.transparent,
                    width: context.screenWidth,
                    height: context.screenHeight,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      );
    }

    // Add tap to close
    if (widget.mainScreenTapClose && !_shouldBeAlwaysVisible) {
      mainScreen = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _mainScreenTapHandler,
        child: mainScreen,
      );
    }

    return mainScreen;
  }

  @override
  Widget build(BuildContext context) => _renderLayout();

  Widget _renderLayout() {
    Widget parentWidget;

    // Always visible mode uses a simple Row layout
    if (_shouldBeAlwaysVisible) {
      return Row(
        children: [
          SizedBox(
            width: widget.slideWidth,
            child: menuScreenWidget,
          ),
          Expanded(
            child: mainScreenWidget,
          ),
        ],
      );
    }

    // Regular zoom drawer behavior for mobile
    if (widget.drawerStyleBuilder != null) {
      parentWidget = AnimatedBuilder(
        animation: _animationController,
        builder: (context, _) => widget.drawerStyleBuilder!(
          context,
          _animationValue,
          widget.slideWidth,
          menuScreenWidget,
          mainScreenWidget,
        ),
      );
    } else {
      switch (widget.style) {
        case DrawerStyle.style1:
          parentWidget = AnimatedBuilder(
            animation: _animationController,
            builder: (context, _) => Style1Widget(
              animationValue: _animationValue,
              isRtl: widget.isRtl,
              mainScreenScale: widget.mainScreenScale,
              slideWidth: widget.slideWidth,
              menuBackgroundColor: widget.menuBackgroundColor,
              slideDirection: _slideDirection,
              mainScreenWidget: mainScreenWidget,
              menuScreenWidget: menuScreenWidget,
            ),
          );
          break;
        case DrawerStyle.style2:
          parentWidget = AnimatedBuilder(
            animation: _animationController,
            builder: (context, _) => Style2Widget(
              isRtl: widget.isRtl,
              mainScreenScale: widget.mainScreenScale,
              slideWidth: widget.slideWidth,
              slideDirection: _slideDirection,
              animationValue: _animationValue,
              menuScreenWidget: menuScreenWidget,
              mainScreenWidget: mainScreenWidget,
            ),
          );
          break;
        case DrawerStyle.style3:
          parentWidget = AnimatedBuilder(
            animation: _animationController,
            builder: (context, _) => Style3Widget(
              isRtl: widget.isRtl,
              mainScreenScale: widget.mainScreenScale,
              slideWidth: widget.slideWidth,
              animationValue: _animationValue,
              slideDirection: _slideDirection,
              menuScreenWidget: menuScreenWidget,
              mainScreenWidget: mainScreenWidget,
            ),
          );
          break;
        case DrawerStyle.style4:
          parentWidget = AnimatedBuilder(
            animation: _animationController,
            builder: (context, _) => Style4Widget(
              isRtl: widget.isRtl,
              mainScreenScale: widget.mainScreenScale,
              slideWidth: widget.slideWidth,
              animationValue: _animationValue,
              slideDirection: _slideDirection,
              menuScreenWidget: menuScreenWidget,
              mainScreenWidget: mainScreenWidget,
            ),
          );
          break;
        default:
          parentWidget = AnimatedBuilder(
            animation: _animationController,
            builder: (_, __) => StyleDefaultWidget(
              animationController: _animationController,
              mainScreenWidget: mainScreenWidget,
              menuScreenWidget: menuScreenWidget,
              angle: widget.angle,
              showShadow: widget.showShadow,
              shadowLayer1Color: widget.shadowLayer1Color,
              shadowLayer2Color: widget.shadowLayer2Color,
              drawerShadowsBackgroundColor: widget.drawerShadowsBackgroundColor,
              applyDefaultStyle: _applyDefaultStyle,
            ),
          );
      }
    }

    // Add gesture detection for mobile
    if (!widget.disableDragGesture) {
      parentWidget = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: _onHorizontalDragStart,
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        onHorizontalDragEnd: _onHorizontalDragEnd,
        child: parentWidget,
      );
    }

    // Add PopScope for Android back button
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        widget.androidCloseOnBackTap) {
      parentWidget = PopScope(
        canPop: _canPop(),
        child: parentWidget,
      );
    }

    return parentWidget;
  }

  bool _canPop() {
    if ([DrawerState.open, DrawerState.opening].contains(stateNotifier.value) &&
        !_shouldBeAlwaysVisible) {
      close();
      return false;
    }
    return true;
  }
}

// Keep all the existing style widgets and enums unchanged
class Style1Widget extends StatelessWidget {
  const Style1Widget({
    Key? key,
    required this.animationValue,
    required this.mainScreenWidget,
    required this.menuScreenWidget,
    required this.slideDirection,
    required this.slideWidth,
    required this.mainScreenScale,
    required this.isRtl,
    this.menuBackgroundColor,
  }) : super(key: key);

  final double animationValue;
  final int slideDirection;
  final double slideWidth;
  final double mainScreenScale;
  final bool isRtl;
  final Widget mainScreenWidget;
  final Widget menuScreenWidget;
  final Color? menuBackgroundColor;

  @override
  Widget build(BuildContext context) {
    final xOffset = (1 - animationValue) * slideWidth * slideDirection;

    return Stack(
      children: [
        mainScreenWidget,
        Transform.translate(
          offset: Offset(-xOffset, 0),
          child: Container(
            width: slideWidth,
            color: menuBackgroundColor,
            child: menuScreenWidget,
          ),
        ),
      ],
    );
  }
}

class Style2Widget extends StatelessWidget {
  const Style2Widget({
    Key? key,
    required this.animationValue,
    required this.menuScreenWidget,
    required this.mainScreenWidget,
    required this.slideDirection,
    required this.slideWidth,
    required this.mainScreenScale,
    required this.isRtl,
  }) : super(key: key);

  final int slideDirection;
  final double slideWidth;
  final double mainScreenScale;
  final bool isRtl;
  final double animationValue;
  final Widget menuScreenWidget;
  final Widget mainScreenWidget;

  @override
  Widget build(BuildContext context) {
    final xPosition = slideWidth * slideDirection * animationValue;
    final yPosition = animationValue * slideWidth;
    final scalePercentage = 1 - (animationValue * mainScreenScale);

    return Stack(
      children: [
        menuScreenWidget,
        Transform(
          transform: Matrix4.identity()
            ..translate(xPosition, yPosition)
            ..scale(scalePercentage),
          alignment: Alignment.center,
          child: mainScreenWidget,
        ),
      ],
    );
  }
}

class Style3Widget extends StatelessWidget {
  const Style3Widget({
    Key? key,
    required this.animationValue,
    required this.slideDirection,
    required this.menuScreenWidget,
    required this.mainScreenWidget,
    required this.slideWidth,
    required this.mainScreenScale,
    required this.isRtl,
  }) : super(key: key);

  final double animationValue;
  final int slideDirection;
  final double slideWidth;
  final double mainScreenScale;
  final bool isRtl;
  final Widget menuScreenWidget;
  final Widget mainScreenWidget;

  @override
  Widget build(BuildContext context) {
    final xPosition = (slideWidth / 2) * animationValue * slideDirection;
    final scalePercentage = 1 - (animationValue * mainScreenScale);
    final yAngle = animationValue * (pi / 4) * slideDirection;

    return Stack(
      children: [
        menuScreenWidget,
        Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0009)
            ..translate(xPosition)
            ..scale(scalePercentage)
            ..rotateY(yAngle),
          alignment: isRtl ? Alignment.centerLeft : Alignment.centerRight,
          child: mainScreenWidget,
        ),
      ],
    );
  }
}

class Style4Widget extends StatelessWidget {
  const Style4Widget({
    Key? key,
    required this.animationValue,
    required this.slideDirection,
    required this.menuScreenWidget,
    required this.mainScreenWidget,
    required this.mainScreenScale,
    required this.slideWidth,
    required this.isRtl,
  }) : super(key: key);

  final double animationValue;
  final double slideWidth;
  final double mainScreenScale;
  final bool isRtl;
  final int slideDirection;
  final Widget menuScreenWidget;
  final Widget mainScreenWidget;

  @override
  Widget build(BuildContext context) {
    final xPosition = (slideWidth * 1.2) * animationValue * slideDirection;
    final scalePercentage = 1 - (animationValue * mainScreenScale);
    final yAngle = animationValue * (pi / 4) * slideDirection;

    return Stack(
      children: [
        menuScreenWidget,
        Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0009)
            ..translate(xPosition)
            ..scale(scalePercentage)
            ..rotateY(-yAngle),
          alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
          child: mainScreenWidget,
        ),
      ],
    );
  }
}

class StyleDefaultWidget extends StatelessWidget {
  const StyleDefaultWidget({
    super.key,
    required this.animationController,
    required this.showShadow,
    required this.angle,
    required this.menuScreenWidget,
    required this.mainScreenWidget,
    this.shadowLayer1Color,
    this.shadowLayer2Color,
    required this.drawerShadowsBackgroundColor,
    required this.applyDefaultStyle,
  });

  final AnimationController animationController;
  final bool showShadow;
  final double angle;
  final Widget menuScreenWidget;
  final Widget mainScreenWidget;
  final Color? shadowLayer1Color;
  final Color? shadowLayer2Color;
  final Color drawerShadowsBackgroundColor;
  final Widget Function(
    Widget?, {
    double? angle,
    double scale,
    double slide,
  }) applyDefaultStyle;

  @override
  Widget build(BuildContext context) {
    const slidePercent = 15.0;

    return Stack(
      children: [
        menuScreenWidget,
        if (showShadow) ...[
          /// Displaying the first shadow
          applyDefaultStyle(
            Container(
              color: shadowLayer1Color ??
                  drawerShadowsBackgroundColor.withAlpha(60),
            ),
            angle: (angle == 0.0) ? 0.0 : angle - 8,
            scale: .9,
            slide: slidePercent * 2,
          ),

          /// Displaying the second shadow
          applyDefaultStyle(
            Container(
              color: shadowLayer2Color ??
                  drawerShadowsBackgroundColor.withAlpha(180),
            ),
            angle: (angle == 0.0) ? 0.0 : angle - 4.0,
            scale: .95,
            slide: slidePercent,
          )
        ],

        /// Displaying the Main screen
        applyDefaultStyle(
          mainScreenWidget,
        ),
      ],
    );
  }
}

enum DrawerStyle {
  defaultStyle,
  style1,
  style2,
  style3,
  style4,
}

class ZoomDrawerController {
  /// Open drawer
  TickerFuture? Function()? open;

  /// Close drawer
  TickerFuture? Function()? close;

  /// Toggle drawer
  TickerFuture? Function({bool forceToggle})? toggle;

  /// Determine if status of drawer equals to Open
  bool Function()? isOpen;

  /// Drawer state notifier
  /// opening, closing, open, closed
  ValueNotifier<DrawerState>? stateNotifier;
}

enum DrawerState { opening, closing, open, closed }

enum DrawerLastAction { open, closed }

extension ZoomDrawerContext on BuildContext {
  /// Drawer
  ZoomDrawerState? get drawer => ZoomDrawer.of(this);

  /// drawerLastAction
  DrawerLastAction? get drawerLastAction =>
      ZoomDrawer.of(this)?.drawerLastAction;

  /// drawerState
  DrawerState? get drawerState => ZoomDrawer.of(this)?.stateNotifier.value;

  /// drawerState notifier
  ValueNotifier<DrawerState>? get drawerStateNotifier =>
      ZoomDrawer.of(this)?.stateNotifier;

  /// Screen Width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Screen Height
  double get screenHeight => MediaQuery.of(this).size.height;
}
