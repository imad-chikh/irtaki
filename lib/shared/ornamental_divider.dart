import 'package:flutter/material.dart';

class OrnamentalDivider extends StatelessWidget {
  const OrnamentalDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: Container(
          width: 200,
          height: 1,
          color: Theme.of(context).dividerColor.withOpacity(0.5),
        ),
      ),
    );
  }
}
