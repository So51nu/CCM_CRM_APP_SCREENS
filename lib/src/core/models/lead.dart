part of '../../../click_connect_ai_crm_ui.dart';

class Lead {
  final String name;
  final String company;
  final String mobile;
  final String alternate;
  final String source;
  final String city;
  final String interest;
  final String status;
  final String priority;
  final int score;
  final String followUp;

  const Lead({
    required this.name,
    required this.company,
    required this.mobile,
    required this.alternate,
    required this.source,
    required this.city,
    required this.interest,
    required this.status,
    required this.priority,
    required this.score,
    required this.followUp,
  });
}

const demoLeads = <Lead>[
  Lead(
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


