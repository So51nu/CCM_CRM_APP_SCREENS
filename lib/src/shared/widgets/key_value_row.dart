part of '../../../click_connect_ai_crm_ui.dart';

class KeyValueRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final IconData? icon;

  const KeyValueRow(this.label, this.value, {super.key, this.valueColor, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: CcColors.textMuted, size: 18),
            const SizedBox(width: 10),
          ],
          Expanded(child: Text(label, style: const TextStyle(color: CcColors.textMuted, fontWeight: FontWeight.w700, fontSize: 13))),
          const SizedBox(width: 12),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: TextStyle(color: valueColor ?? CcColors.text, fontWeight: FontWeight.w800, fontSize: 13))),
        ],
      ),
    );
  }
}


