part of '../../../../click_connect_ai_crm_ui.dart';

class ProposalInvoiceBlock extends StatelessWidget {
  const ProposalInvoiceBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          Row(children: [
            Expanded(child: MetricTile(label: 'Total Proposals', value: '20', icon: Icons.description_rounded)),
            SizedBox(width: 10),
            Expanded(child: MetricTile(label: 'Accepted', value: '7', icon: Icons.check_circle_rounded, color: CcColors.green)),
          ]),
          SizedBox(height: 12),
          SectionTitle('Recent Proposals', action: 'View All'),
          ProposalTile(id: 'PR-2024-045', name: 'Acme Corporation', amount: '₹25,000', status: 'Accepted', color: CcColors.green),
          ProposalTile(id: 'PR-2024-044', name: 'Globex Solutions', amount: '₹18,500', status: 'Sent', color: CcColors.amber),
          ProposalTile(id: 'PR-2024-043', name: 'Stark Industries', amount: '₹12,000', status: 'Draft', color: CcColors.blue500),
          SectionTitle('Recent Invoices', action: 'View All'),
          InvoiceTile(id: 'INV-2024-032', name: 'Acme Corporation', amount: '₹25,000', status: 'Payment Pending', color: CcColors.red),
          InvoiceTile(id: 'INV-2024-031', name: 'Globex Solutions', amount: '₹18,500', status: 'Paid', color: CcColors.green),
        ],
      ),
    );
  }
}


