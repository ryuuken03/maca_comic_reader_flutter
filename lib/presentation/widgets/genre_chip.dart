import 'package:flutter/material.dart';

class GenreChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool>? onSelected;
  final double fontSize;

  const GenreChip({
    Key? key,
    required this.label,
    this.isSelected = false,
    this.onSelected,
    this.fontSize = 11.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (onSelected == null) {
      // Regular informational chip (e.g., in Detail Page)
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: fontSize, 
            color: Colors.white.withOpacity(0.85),
          ),
        ),
      );
    }
    
    // Interactive FilterChip (e.g., in Filter Dialog)
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: fontSize + 1,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.black : Colors.white70,
        ),
      ),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: const Color(0xFFFDD644),
      checkmarkColor: Colors.black,
      backgroundColor: const Color(0xFF2C2C2C),
      pressElevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? const Color(0xFFFDD644) : Colors.transparent,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      visualDensity: VisualDensity.compact,
    );
  }
}
