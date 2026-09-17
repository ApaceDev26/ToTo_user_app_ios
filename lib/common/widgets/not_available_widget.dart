import 'package:toto_user/util/dimensions.dart';
import 'package:toto_user/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotAvailableWidget extends StatelessWidget {
  final double fontSize;
  final bool isRestaurant;
  final double opacity;
  final Color color;
  const NotAvailableWidget({super.key, this.fontSize = 11, this.isRestaurant = false, this.opacity = 0.7, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0, left: 0, bottom: 0, right: 0,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall), 
          color: Colors.black.withValues(alpha: opacity)
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            isRestaurant ? 'closed_now'.tr : 'not_available_now_break'.tr, 
            textAlign: TextAlign.center,
            style: robotoBold.copyWith(
              color: color, 
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
