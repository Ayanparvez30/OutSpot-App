
import 'package:flutter/material.dart';

class UserModel {
  final String name;
  final String avatar;
  final double karma;
  final int level;
  final String label;
  final String extra;
  final IconData? icon;

  UserModel({
    required this.name,
    required this.avatar,
    required this.karma,
    required this.level,
    this.label = "",
    this.extra = "",
    this.icon,
  });
}