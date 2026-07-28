import 'package:flutter/material.dart';
import 'package:meo_traker/core/constants/app_icons.dart';

/// Coin icon with fully rounded (circular) clip — no square corners.
class CoinIcon extends StatelessWidget {
  const CoinIcon({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          AppIcons.diemThuong,
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}
