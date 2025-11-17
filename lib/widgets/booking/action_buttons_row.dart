import 'package:flutter/material.dart';

class ActionButton {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
  });
}

class ActionButtonsRow extends StatelessWidget {
  final List<ActionButton> buttons;

  const ActionButtonsRow({
    super.key,
    required this.buttons,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: buttons.map((button) => _buildButton(button)).toList(),
    );
  }

  Widget _buildButton(ActionButton button) {
    return Expanded(
      child: InkWell(
        onTap: button.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(button.icon, size: 20, color: Colors.black87),
              const SizedBox(height: 2),
              Text(
                button.label,
                style: const TextStyle(fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}