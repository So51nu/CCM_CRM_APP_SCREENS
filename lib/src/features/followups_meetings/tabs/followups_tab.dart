part of '../../../../click_connect_ai_crm_ui.dart';

class _FollowupsTab extends StatelessWidget {
  const _FollowupsTab();

  @override
  Widget build(BuildContext context) {
    final followups = const [
      ('Rohit Sharma', 'TechNova Solutions', '10:00 AM', 'Due Today', CcColors.green),
      ('Neha Patel', 'BrightEdge Marketing', '11:30 AM', 'Due Today', CcColors.green),
      ('Amit Verma', 'Verma Enterprises', '02:00 PM', 'Overdue', CcColors.red),
      ('Sneha Iyer', 'CloudPeak Systems', '04:30 PM', 'Upcoming', CcColors.blue500),
      ('Karan Mehta', 'Mehta & Co.', 'Tomorrow, 10:00 AM', 'Upcoming', CcColors.blue500),
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              CcChip(label: 'Today', filled: true),
              CcChip(label: 'Overdue 5', color: CcColors.red),
              CcChip(label: 'Upcoming 12'),
              CcChip(label: 'Completed'),
            ],
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                return Column(
                  children: [
                    Text(
                      ['S', 'M', 'T', 'W', 'T', 'F', 'S'][index],
                      style: const TextStyle(color: CcColors.textMuted),
                    ),
                    const SizedBox(height: 6),
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: index == 3 ? CcColors.blue500 : Colors.transparent,
                      child: Text(
                        '${11 + index}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          ...followups.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: item.$5,
                      child: Text(item.$1.substring(0, 1)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w900)),
                          Text(item.$2, style: const TextStyle(color: CcColors.textMuted, fontSize: 12)),
                          const SizedBox(height: 6),
                          CcChip(label: item.$4, color: item.$5, filled: true),
                        ],
                      ),
                    ),
                    Text(item.$3, style: TextStyle(color: item.$5, fontWeight: FontWeight.w900)),
                    const SizedBox(width: 8),
                    const Icon(Icons.call_rounded, color: CcColors.blue300),
                    const SizedBox(width: 8),
                    const Icon(Icons.notifications_none_rounded, color: CcColors.textMuted),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 6),
          GlassCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                _MiniStat('Total', '12'),
                _MiniStat('Completed', '4', CcColors.green),
                _MiniStat('Overdue', '5', CcColors.red),
                _MiniStat('Due Today', '3', CcColors.blue500),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
