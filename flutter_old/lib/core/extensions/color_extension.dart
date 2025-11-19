import 'package:flutter/material.dart';

extension ColorExtension<T> on T {
  Color getColor(String color) {
    switch (color) {
      case "red":
        return Colors.red;
      case "green":
        return Colors.green;
      case "navy":
        return Colors.blue;
      case "yellow":
        return Colors.yellow;
      case "black":
        return Colors.black;
      default:
        return Colors.grey;
    }
  }

  Color textColorBalance(String color) {
    switch (color) {
      case "red":
        return Colors.white;
      case "green":
        return Colors.black;
      case "navy":
        return Colors.white;
      case "yellow":
        return Colors.black;
      case "black":
        return Colors.white;
      default:
        return Colors.white;
    }
  }
}
