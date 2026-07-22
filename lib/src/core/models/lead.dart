part of '../../../click_connect_ai_crm_ui.dart';

class Lead {
  final int id;
  final String name;
  final String company;
  final String mobile;
  final String alternate;
  final String email;
  final String source;
  final String city;
  final String interest;
  final String status;
  final String priority;
  final int score;
  final String followUp;
  final Map<String, dynamic> raw;

  // Backward-compatible alias used by feedback/AI screens.
  // Backend may send service/service_interest/product, but the app stores it as `interest`.
  String get service => interest;

  const Lead({
    this.id = 0,
    required this.name,
    required this.company,
    required this.mobile,
    required this.alternate,
    this.email = '',
    required this.source,
    required this.city,
    required this.interest,
    required this.status,
    required this.priority,
    required this.score,
    required this.followUp,
    this.raw = const <String, dynamic>{},
  });

  factory Lead.fromJson(Map<String, dynamic> json) {
    final mobile = _text(json['mobile'] ?? json['phone'] ?? json['phone_number'] ?? json['contact'] ?? json['primary_number'], '');
    return Lead(
      id: _int(json['id'] ?? json['lead_id']),
      name: _text(json['name'] ?? json['lead_name'] ?? json['customer_name'] ?? json['client_name'], 'Unnamed Lead'),
      company: _text(json['company'] ?? json['company_name'] ?? json['business_name'], '-'),
      mobile: mobile,
      alternate: _text(json['alternate'] ?? json['alternate_number'] ?? json['alt_mobile'] ?? json['secondary_phone'], ''),
      email: _text(json['email'] ?? json['lead_email'], ''),
      source: _text(json['source'] ?? json['lead_source'] ?? json['platform'], '-'),
      city: _text(json['city'] ?? json['location'], '-'),
      interest: _text(json['interest'] ?? json['service_interest'] ?? json['service'] ?? json['product'] ?? json['requirement'], '-'),
      status: _normalizeStatus(_text(json['status'] ?? json['lead_quality'] ?? json['temperature'], 'Warm')),
      priority: _normalizePriority(_text(json['priority'] ?? json['lead_priority'], 'Medium')),
      score: _int(json['score'] ?? json['ai_score'] ?? json['lead_score'], 50),
      followUp: _text(json['next_followup'] ?? json['next_follow_up'] ?? json['followup_at'] ?? json['scheduled_at'], 'No follow-up'),
      raw: json,
    );
  }

  static String _normalizeStatus(String value) {
    final low = value.toLowerCase();
    if (low.contains('hot') || low.contains('interested')) return 'Hot';
    if (low.contains('cold') || low.contains('not')) return 'Cold';
    return 'Warm';
  }

  static String _normalizePriority(String value) {
    final low = value.toLowerCase();
    if (low.contains('high')) return 'High';
    if (low.contains('low')) return 'Low';
    return 'Medium';
  }
}

const demoLeads = <Lead>[
  Lead(
    id: 10,
    name: 'Vikram Mehta',
    company: 'Mehta Enterprises',
    mobile: '+91 98765 43210',
    alternate: '+91 91234 56789',
    source: 'Website',
    city: 'Bengaluru',
    interest: 'CRM Software',
    status: 'Hot',
    priority: 'High',
    score: 85,
    followUp: 'Today, 11:00 AM',
  ),
  Lead(
    id: 11,
    name: 'Priya Sharma',
    company: 'Sharma Solutions',
    mobile: '+91 99876 54321',
    alternate: '+91 90000 11122',
    source: 'Referral',
    city: 'Mumbai',
    interest: 'Sales Automation',
    status: 'Warm',
    priority: 'Medium',
    score: 72,
    followUp: 'Tomorrow, 4:00 PM',
  ),
  Lead(
    id: 12,
    name: 'Rahul Verma',
    company: 'Verma Traders',
    mobile: '+91 97654 32109',
    alternate: '+91 88888 22222',
    source: 'Google Ads',
    city: 'Delhi',
    interest: 'Lead Management',
    status: 'Cold',
    priority: 'Low',
    score: 56,
    followUp: '25 May, 10:30 AM',
  ),
];
