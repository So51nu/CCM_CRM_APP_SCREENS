part of '../../../../click_connect_ai_crm_ui.dart';

class InvoiceTile extends StatelessWidget {
  final String id;
  final String name;
  final String amount;
  final String status;
  final Color color;

  const InvoiceTile({super.key, required this.id, required this.name, required this.amount, required this.status, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GlassCard(
          child: Row(
            children: [
              const Icon(Icons.receipt_long_rounded, color: CcColors.blue300, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(id, style: const TextStyle(fontWeight: FontWeight.w900)),
                    Text(name, style: const TextStyle(color: CcColors.textMuted)),
                    Text(amount, style: const TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              CcChip(label: status, color: color, filled: true),
              const SizedBox(width: 6),
              IconButton.filledTonal(icon: Icon(status.contains('Pending') ? Icons.notifications_active_rounded : Icons.chat_rounded, color: status.contains('Pending') ? CcColors.amber : CcColors.green), onPressed: () {}),
            ],
          ),
        ),
      );
}


