import 'package:flutter/material.dart';

class Estabelecimento {
  int id;
  String name;
  int employees;
  String hq;
  String url;
  bool active;
  Color color;

  Estabelecimento(this.id, this.name, this.employees, this.hq, this.url,
      this.active, this.color);

  factory Estabelecimento.fromJson(dynamic json) {
    return Estabelecimento(
        json['id'] as int,
        json['name'] as String,
        json['employees'] as int,
        json['hq'] as String,
        json['url'] as String,
        json['active'] as bool,
        _getAvatarColor(json['id'] as int));
  }

  static Color _getAvatarColor(int index) {
    switch (index % 4) {
      case 0:
        return Colors.red;
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.indigoAccent;
      default:
        return null;
    }
  }
}
