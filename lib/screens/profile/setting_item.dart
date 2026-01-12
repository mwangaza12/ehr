import 'package:flutter/material.dart';

class SettingItem {
    final IconData icon;
    final String title;
    final String subtitle;
    final IconData trailing;
    final Color color;
    final VoidCallback onTap;

    SettingItem({
      required this.icon,
      required this.title,
      required this.subtitle,
      required this.trailing,
      required this.color,
      required this.onTap,
    });
  }