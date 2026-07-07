part of '../../../../click_connect_ai_crm_ui.dart';

class ProposalTile extends StatelessWidget {
  final String id;
  final String name;
  final String amount;
  final String status;
  final Color color;

  const ProposalTile({super.key, required this.id, required this.name, required this.amount, required this.status, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GlassCard(
          child: Row(
            children: [
              const Icon(Icons.picture_as_pdf_rounded, color: CcColors.red, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Prop #$id', style: const TextStyle(fontWeight: FontWeight.w900)),
                    Text(name, style: const TextStyle(color: CcColors.textMuted)),
                    Text(amount, style: const TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              CcChip(label: status, color: color, filled: true),
              const SizedBox(width: 6),
              IconButton.filledTonal(icon: const Icon(Icons.chat_rounded, color: CcColors.green), onPressed: () {}),
            ],
          ),
        ),
      );
}


