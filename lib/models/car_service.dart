import 'package:flutter/material.dart';

enum CarType { economy, standard, premium }

class CarService {
  final CarType type;
  final String name;
  final String capacity;
  final int etaMin;
  final String subtitle;
  final int price;
  final int? originalPrice;

  const CarService({
    required this.type,
    required this.name,
    required this.capacity,
    required this.etaMin,
    required this.subtitle,
    required this.price,
    this.originalPrice,
  });

  IconData get icon {
    switch (type) {
      case CarType.economy:
        return Icons.directions_car;
      case CarType.standard:
        return Icons.directions_car_filled;
      case CarType.premium:
        return Icons.time_to_leave;
    }
  }

  Color get color {
    switch (type) {
      case CarType.economy:
        return Colors.blue;
      case CarType.standard:
        return Colors.orange;
      case CarType.premium:
        return Colors.purple;
    }
  }
}