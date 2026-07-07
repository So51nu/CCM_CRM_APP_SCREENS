part of '../../../../click_connect_ai_crm_ui.dart';

class TranscriptBubble extends StatelessWidget {
  final String speaker;
  final String time;
  final String text;
  const TranscriptBubble({super.key, required this.speaker, required this.time, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Text(speaker, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(width: 8), Text(time, style: const TextStyle(color: CcColors.textMuted, fontSize: 12))]),
      const SizedBox(height: 6),
      Text(text, style: const TextStyle(color: CcColors.textSoft, height: 1.35)),
    ])),
  );
}


