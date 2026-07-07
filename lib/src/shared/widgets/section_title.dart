part of '../../../click_connect_ai_crm_ui.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionTitle(this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: CcColors.text))),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!, style: const TextStyle(fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}


