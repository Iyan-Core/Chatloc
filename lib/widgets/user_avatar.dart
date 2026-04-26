import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double radius;
  final bool showOnlineIndicator;

  const UserAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.radius = 24,
    this.showOnlineIndicator = false,
  });

  Color _colorFromName(String name) {
    const colors = [
      Color(0xFF6C63FF), Color(0xFF06D6A0), Color(0xFFFF6B6B),
      Color(0xFFFFD166), Color(0xFF118AB2), Color(0xFF073B4C),
    ];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: _colorFromName(name),
          child: photoUrl != null
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: photoUrl!,
                    width: radius * 2,
                    height: radius * 2,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _initials(),
                  ),
                )
              : _initials(),
        ),
        if (showOnlineIndicator)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.5,
              height: radius * 0.5,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _initials() {
    final initials = name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join();
    return Text(
      initials,
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: radius * 0.55,
      ),
    );
  }
}
