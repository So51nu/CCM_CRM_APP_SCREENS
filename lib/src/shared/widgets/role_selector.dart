part of '../../../click_connect_ai_crm_ui.dart';

class RoleSelector extends StatelessWidget {
  final String selectedRole;
  final ValueChanged<String> onChanged;

  const RoleSelector({super.key, required this.selectedRole, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final roles = const [
      ('Telecaller', Icons.headset_mic_rounded),
      ('Sales Executive', Icons.person_pin_rounded),
      ('Manager', Icons.admin_panel_settings_rounded),
    ];
    return Row(
      children: roles.map((role) {
        final selected = selectedRole == role.$1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => onChanged(role.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: selected ? CcColors.blue500.withValues(alpha: .2) : CcColors.cardSoft.withValues(alpha: .65),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: selected ? CcColors.blue500 : CcColors.line),
                ),
                child: Column(
                  children: [
                    Icon(role.$2, color: selected ? CcColors.blue300 : CcColors.textMuted),
                    const SizedBox(height: 6),
                    Text(role.$1, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: selected ? CcColors.blue300 : CcColors.textSoft)),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}


