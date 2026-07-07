part of '../../../../click_connect_ai_crm_ui.dart';

class TimelineItem extends StatelessWidget {
  final String time;
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const TimelineItem({super.key, required this.time, required this.icon, required this.color, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 68, child: Text(time, style: const TextStyle(color: CcColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700))),
        IconBadge(icon: icon, color: color, size: 36),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(body, style: const TextStyle(color: CcColors.textSoft, height: 1.35, fontSize: 12)),
        ])),
      ]),
    );
  }
}


