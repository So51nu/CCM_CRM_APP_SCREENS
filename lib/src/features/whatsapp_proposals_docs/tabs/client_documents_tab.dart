part of '../../../../click_connect_ai_crm_ui.dart';

class ClientDocumentsBlock extends StatelessWidget {
  const ClientDocumentsBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final docs = const [
      (Icons.business_rounded, CcColors.blue500, 'Company Profile', '12 Files'),
      (Icons.menu_book_rounded, CcColors.amber, 'Brochure', '8 Files'),
      (Icons.collections_bookmark_rounded, CcColors.orange, 'Portfolio', '15 Files'),
      (Icons.picture_as_pdf_rounded, CcColors.red, 'Service PDF', '10 Files'),
      (Icons.price_check_rounded, CcColors.green, 'Pricing Sheet', '6 Files'),
      (Icons.cases_rounded, CcColors.purple, 'Case Studies', '9 Files'),
      (Icons.description_rounded, CcColors.red, 'Proposal PDFs', '14 Files'),
    ];
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const TextField(decoration: InputDecoration(hintText: 'Search documents...', prefixIcon: Icon(Icons.search_rounded))),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.15,
          children: docs
              .map(
                (e) => GlassCard(
                  padding: const EdgeInsets.all(13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconBadge(icon: e.$1, color: e.$2, size: 42),
                      const Spacer(),
                      Text(e.$3, style: const TextStyle(fontWeight: FontWeight.w900)),
                      Text(e.$4, style: const TextStyle(color: CcColors.textMuted)),
                      const SizedBox(height: 8),
                      Row(children: const [
                        Expanded(child: CcChip(label: 'Preview')),
                        SizedBox(width: 6),
                        Expanded(child: CcChip(label: 'Share', filled: true)),
                      ]),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ]),
    );
  }
}


