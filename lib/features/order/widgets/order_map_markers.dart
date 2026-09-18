import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:maplibre/maplibre.dart';

class OrderMapMarkers extends StatefulWidget {
  final Geographic? restaurant;
  final Geographic? rider;
  final Geographic? customer;

  const OrderMapMarkers({
    super.key,
    this.restaurant,
    this.rider,
    this.customer,
  });

  @override
  State<OrderMapMarkers> createState() => _OrderMapMarkersState();
}

class _OrderMapMarkersState extends State<OrderMapMarkers>
    with TickerProviderStateMixin {
  late final AnimationController _riderAnimation;
  late final AnimationController _riderIdleAnimation;
  late final AnimationController _customerAnimation;
  late final Listenable _markerAnimations;
  Geographic? _riderStart;
  Geographic? _riderEnd;
  bool _hasTravelMotion = false;
  double _headingStart = 90;
  double _headingEnd = 90;

  @override
  void initState() {
    super.initState();
    _riderAnimation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _riderIdleAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _customerAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _markerAnimations = Listenable.merge([
      _riderAnimation,
      _riderIdleAnimation,
      _customerAnimation,
    ]);
    _riderStart = widget.rider;
    _riderEnd = widget.rider;
  }

  Geographic? get _animatedRider {
    final start = _riderStart;
    final end = _riderEnd;
    if (start == null || end == null) return end;
    final progress = _riderAnimation.value;
    return Geographic(
      lat: start.lat + (end.lat - start.lat) * progress,
      lon: start.lon + (end.lon - start.lon) * progress,
    );
  }

  double get _animatedHeading {
    final turnProgress = (_riderAnimation.value * 5).clamp(0.0, 1.0);
    return _headingStart + (_headingEnd - _headingStart) * turnProgress;
  }

  double? _travelBearing(Geographic from, Geographic to) {
    final lat1 = from.lat * math.pi / 180;
    final lat2 = to.lat * math.pi / 180;
    final latDelta = (to.lat - from.lat) * 111320;
    final lonDelta = (to.lon - from.lon) *
        111320 * math.cos((lat1 + lat2) / 2);
    if (math.sqrt(latDelta * latDelta + lonDelta * lonDelta) < 5) {
      return null;
    }

    final lonRadians = (to.lon - from.lon) * math.pi / 180;
    final y = math.sin(lonRadians) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(lonRadians);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  @override
  void didUpdateWidget(covariant OrderMapMarkers oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.rider;
    final previous = _riderEnd;
    if (next?.lat == previous?.lat && next?.lon == previous?.lon) return;

    if (next == null || previous == null) {
      _riderAnimation.stop();
      _hasTravelMotion = false;
      _riderStart = next;
      _riderEnd = next;
    } else {
      final bearing = _travelBearing(previous, next);
      _hasTravelMotion = bearing != null;
      if (bearing != null) {
        _headingStart = _animatedHeading;
        final shortestTurn = (bearing - _headingStart + 540) % 360 - 180;
        _headingEnd = _headingStart + shortestTurn;
      }
      _riderStart = _animatedRider;
      _riderEnd = next;
      _riderAnimation.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _riderAnimation.dispose();
    _riderIdleAnimation.dispose();
    _customerAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _markerAnimations,
      builder: (context, _) => WidgetLayer(
        markers: [
          if (widget.restaurant != null)
            _marker(widget.restaurant!, Icons.storefront_rounded,
                const Color(0xFFFF8A32), const Color(0xFFE95420)),
          if (widget.customer != null)
            Marker(
              point: widget.customer!,
              size: const Size(76, 82),
              alignment: Alignment.bottomCenter,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: 25,
                      height: 9,
                      decoration: BoxDecoration(
                        color: const Color(0xFF225BD5).withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 5,
                    child: Transform.translate(
                      offset: Offset(0, -2 * _customerAnimation.value),
                      child: Transform.rotate(
                        angle: (_customerAnimation.value - 0.5) * 0.05,
                        alignment: Alignment.bottomCenter,
                        child: Image.asset(
                          'assets/image/happy_waiting_customer_3d.png',
                          width: 72,
                          height: 72,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          cacheWidth: 256,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_animatedRider != null)
            Marker(
              point: _animatedRider!,
              size: const Size(72, 74),
              alignment: Alignment.bottomCenter,
              child: _BikeImage(
                headingDegrees: _animatedHeading,
                motion: _riderIdleAnimation.value,
                moving: _hasTravelMotion && _riderAnimation.isAnimating,
              ),
            ),
        ],
      ),
    );
  }

  Marker _marker(
    Geographic point,
    IconData icon,
    Color start,
    Color end,
  ) {
    return Marker(
      point: point,
      size: const Size(52, 59),
      alignment: Alignment.bottomCenter,
      child: _PremiumPin(icon: icon, start: start, end: end),
    );
  }
}

class _BikeImage extends StatelessWidget {
  final double headingDegrees;
  final double motion;
  final bool moving;

  const _BikeImage({
    required this.headingDegrees,
    required this.motion,
    required this.moving,
  });

  @override
  Widget build(BuildContext context) {
    final mapBearing = MapCamera.maybeOf(context)?.bearing ?? 0;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Positioned(
          bottom: 1,
          child: Container(
            width: 27 - motion * 3,
            height: 8 - motion,
            decoration: BoxDecoration(
              color: const Color(0xFF087C65)
                  .withValues(alpha: 0.32 - motion * 0.08),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ),
        Positioned(
          bottom: 5,
          child: Transform.translate(
            offset: Offset(0, -(moving ? 2.5 : 1) * motion),
            child: Transform.rotate(
              angle: (headingDegrees - 90 - mapBearing) * math.pi / 180 -
                  (moving ? 0.04 : 0),
              child: SizedBox(
                width: 66,
                height: 66,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (moving) ...[
                      _speedStreak(-16 - motion * 5, 27, 18, 3),
                      _speedStreak(-12 - motion * 4, 37, 14, 2.5),
                      _speedStreak(-18 - motion * 6, 47, 20, 2.5),
                    ],
                    Image.asset(
                      'assets/image/delivery_bike_3d.png',
                      width: 66,
                      height: 66,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      cacheWidth: 256,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _speedStreak(double left, double top, double width, double height) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF16C8B4).withValues(alpha: 0),
              const Color(0xFF16C8B4).withValues(alpha: 0.85),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumPin extends StatelessWidget {
  final IconData icon;
  final Color start;
  final Color end;

  const _PremiumPin({required this.icon, required this.start, required this.end});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [start, end],
            ),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: end.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 25),
        ),
        Transform.translate(
          offset: const Offset(0, -3),
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: end,
                border: const Border(
                  right: BorderSide(color: Colors.white, width: 2),
                  bottom: BorderSide(color: Colors.white, width: 2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
