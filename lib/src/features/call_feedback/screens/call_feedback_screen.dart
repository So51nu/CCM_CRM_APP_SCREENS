part of '../../../../click_connect_ai_crm_ui.dart';

class CallFeedbackScreen extends StatefulWidget {
  final bool openedFromCall;

  const CallFeedbackScreen({super.key, this.openedFromCall = false});

  @override
  State<CallFeedbackScreen> createState() => _CallFeedbackScreenState();
}

class _CallFeedbackScreenState extends State<CallFeedbackScreen> {
  Lead? selectedLead;
  String selectedStatus = 'Interested';
  String customerMood = 'Positive';
  String leadQuality = 'Hot';
  String proposalRequired = 'No';
  String whatsappSend = 'Yes';
  String _lastLoadedEventId = '';
  String _lastAiEventId = '';

  final durationController = TextEditingController(text: '00:00:00');
  final notesController = TextEditingController();
  final requestController = TextEditingController();
  final nextFollowupController = TextEditingController();
  final productController = TextEditingController();
  final budgetController = TextEditingController();
  final meetingAtController = TextEditingController();
  final recordingUrlController = TextEditingController();
  final aiSuggestionController = TextEditingController();

  static const statuses = <String>[
    'Interested', 'Not Interested', 'Connected', 'Ringing', 'Not Picked', 'Busy', 'Switched Off', 'Wrong Number', 'Call Later', 'Meeting Fixed', 'Proposal Sent', 'Payment Pending', 'Won', 'Lost', 'Junk',
  ];
  static const moods = <String>['Positive', 'Neutral', 'Confused', 'Price Sensitive', 'Negative'];
  static const qualities = <String>['Hot', 'Warm', 'Cold', 'Junk'];
  static const yesNo = <String>['Yes', 'No'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final app = CrmScope.of(context);
      await app.refreshLeads(silent: true);
      _prefillFromLatestCall(app, force: true);
      await _autoAiForLatestCall(app);
    });
  }

  @override
  void dispose() {
    durationController.dispose();
    notesController.dispose();
    requestController.dispose();
    nextFollowupController.dispose();
    productController.dispose();
    budgetController.dispose();
    meetingAtController.dispose();
    recordingUrlController.dispose();
    aiSuggestionController.dispose();
    super.dispose();
  }

  void _prefillFromLatestCall(CrmAppState app, {bool force = false}) {
    if (!mounted) return;
    final pending = app.pendingFeedback;
    final eventId = _text(pending?['event_id'], '');
    if (!force && eventId.isNotEmpty && eventId == _lastLoadedEventId) return;
    if (eventId.isNotEmpty) _lastLoadedEventId = eventId;
    final request = pending ?? app.activeCallRequest;
    final requestId = _int(request?['request_id'] ?? request?['id']);
    if (requestId > 0) requestController.text = '$requestId';
    final leadId = _int(request?['lead_id']);
    Lead? found;
    if (leadId > 0) {
      for (final lead in app.leads) {
        if (lead.id == leadId) { found = lead; break; }
      }
    }
    found ??= app.leads.isNotEmpty ? app.leads.first : null;
    final duration = _text(request?['duration'], '');
    if (duration.isNotEmpty && duration != '-') durationController.text = duration;
    final recordingUrl = _text(request?['recording_url'], '');
    if (recordingUrl.isNotEmpty && recordingUrl != '-') {
      recordingUrlController.text = recordingUrl;
    } else if (app.lastRecordingUrl.isNotEmpty && app.lastRecordingUrl != '-') {
      recordingUrlController.text = app.lastRecordingUrl;
    }
    final autoNotes = _text(request?['notes'], '');
    if (autoNotes.isNotEmpty && notesController.text.trim().isEmpty) notesController.text = autoNotes;
    if (found != null && productController.text.trim().isEmpty) productController.text = found.service;
    setState(() => selectedLead = found);
  }

  @override
  Widget build(BuildContext context) {
    final app = CrmScope.of(context);
    return BrandedScaffold(
      title: 'Call Feedback',
      showBack: widget.openedFromCall,
      actions: [
        IconButton(
          tooltip: 'Auto-fill latest call',
          onPressed: () {
            _prefillFromLatestCall(app, force: true);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Latest call data auto-filled')));
          },
          icon: const Icon(Icons.auto_fix_high_rounded),
        ),
        IconButton(
          tooltip: 'Refresh leads',
          onPressed: app.apiLoading ? null : () async { await app.refreshLeads(); _prefillFromLatestCall(app, force: true); },
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: AnimatedBuilder(
        animation: app,
        builder: (context, _) {
          final pendingEventId = _text(app.pendingFeedback?['event_id'], '');
          if (pendingEventId.isNotEmpty && pendingEventId != _lastLoadedEventId) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (!mounted) return;
              _prefillFromLatestCall(app, force: true);
              await _autoAiForLatestCall(app);
            });
          }
          final leads = app.leads;
          selectedLead ??= leads.isNotEmpty ? leads.first : null;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassCard(
                gradient: LinearGradient(colors: [CcColors.green.withValues(alpha: .14), CcColors.card]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: const [Icon(Icons.rate_review_rounded, color: CcColors.green), SizedBox(width: 10), Expanded(child: Text('Auto Feedback after call cut', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)))]),
                  const SizedBox(height: 8),
                  const Text('Call cut hote hi app ye feedback screen auto-open karega aur Request ID, Lead, Duration, Recording URL auto-fill karega. Backend OpenAI key available ho to recording/transcript evidence se AI summary bhi auto-fill hogi. Aap verify karke save karo.', style: TextStyle(color: CcColors.textSoft, height: 1.4)),
                  const SizedBox(height: 12),
                  KeyValueRow('Logged User', '${app.userName} (#${app.userId})', icon: Icons.person_outline_rounded),
                  KeyValueRow('Auto-detected Request', requestController.text.isNotEmpty ? '#${requestController.text}' : '-', icon: Icons.tag_rounded),
                  if (recordingUrlController.text.isNotEmpty) KeyValueRow('Recording Linked', recordingUrlController.text, icon: Icons.mic_rounded, valueColor: CcColors.green),
                ]),
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Text('Feedback Form', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 14),
                  if (leads.isEmpty)
                    Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      const Text('Assigned leads abhi load nahi hue. Refresh Leads dabao.', style: TextStyle(color: CcColors.amber)),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(onPressed: app.apiLoading ? null : () => app.refreshLeads(), icon: const Icon(Icons.people_alt_rounded), label: const Text('Refresh Leads')),
                    ])
                  else
                    DropdownButtonFormField<int>(
                      initialValue: selectedLead?.id,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Lead', prefixIcon: Icon(Icons.person_search_rounded)),
                      items: leads.map((lead) => DropdownMenuItem<int>(value: lead.id, child: Text('${lead.name}  •  ${lead.mobile}', maxLines: 1, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (id) => setState(() => selectedLead = leads.firstWhere((lead) => lead.id == id, orElse: () => leads.first)),
                    ),
                  const SizedBox(height: 12),
                  TextField(controller: requestController, keyboardType: TextInputType.number, readOnly: requestController.text.isNotEmpty, decoration: const InputDecoration(labelText: 'Request ID / Call Session ID auto-detected', prefixIcon: Icon(Icons.tag_rounded))),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(initialValue: selectedStatus, isExpanded: true, decoration: const InputDecoration(labelText: 'Final Call Status', prefixIcon: Icon(Icons.fact_check_rounded)), items: statuses.map((status) => DropdownMenuItem<String>(value: status, child: Text(status, maxLines: 1, overflow: TextOverflow.ellipsis))).toList(), onChanged: (value) => setState(() => selectedStatus = value ?? selectedStatus)),
                  const SizedBox(height: 12),
                  _fieldPair(
                    _dropdown('Customer Mood', customerMood, moods, Icons.mood_rounded, (v) => setState(() => customerMood = v)),
                    _dropdown('Lead Quality', leadQuality, qualities, Icons.local_fire_department_rounded, (v) => setState(() => leadQuality = v)),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: durationController, decoration: const InputDecoration(labelText: 'Call Duration auto-filled', hintText: '00:02:15', prefixIcon: Icon(Icons.timer_outlined))),
                  const SizedBox(height: 12),
                  TextField(controller: productController, decoration: const InputDecoration(labelText: 'Product / Service Interested', hintText: 'Website / CRM / Ads / SEO', prefixIcon: Icon(Icons.work_outline_rounded))),
                  const SizedBox(height: 12),
                  TextField(controller: budgetController, decoration: const InputDecoration(labelText: 'Budget', hintText: '₹50,000 or low budget', prefixIcon: Icon(Icons.currency_rupee_rounded))),
                  const SizedBox(height: 12),
                  TextField(controller: nextFollowupController, decoration: const InputDecoration(labelText: 'Next Follow-up', hintText: '2026-07-10 16:00:00', prefixIcon: Icon(Icons.event_rounded))),
                  const SizedBox(height: 12),
                  TextField(controller: meetingAtController, decoration: const InputDecoration(labelText: 'Meeting Date/Time optional', hintText: '2026-07-11 12:00:00', prefixIcon: Icon(Icons.video_call_rounded))),
                  const SizedBox(height: 12),
                  _fieldPair(
                    _dropdown('Proposal Required', proposalRequired, yesNo, Icons.picture_as_pdf_rounded, (v) => setState(() => proposalRequired = v)),
                    _dropdown('WhatsApp Send', whatsappSend, yesNo, Icons.chat_rounded, (v) => setState(() => whatsappSend = v)),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: recordingUrlController, readOnly: true, decoration: const InputDecoration(labelText: 'Recording URL auto-linked', prefixIcon: Icon(Icons.mic_external_on_rounded))),
                  const SizedBox(height: 12),
                  TextField(controller: notesController, maxLines: 5, decoration: const InputDecoration(labelText: 'Discussion Notes', hintText: 'Client ne kya bola, requirement, objection, next action...', prefixIcon: Icon(Icons.notes_rounded))),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(onPressed: app.apiLoading || selectedLead == null ? null : () => _aiAutoFill(app), icon: const Icon(Icons.auto_awesome_rounded), label: const Text('AI Auto-fill / Suggest Next Action')),
                  if (aiSuggestionController.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    TextField(controller: aiSuggestionController, maxLines: 4, decoration: const InputDecoration(labelText: 'AI Suggestion', prefixIcon: Icon(Icons.psychology_rounded))),
                  ],
                  const SizedBox(height: 16),
                  PrimaryButton(label: app.apiLoading ? 'Saving...' : 'Save Feedback', icon: Icons.cloud_done_rounded, onPressed: app.apiLoading || selectedLead == null ? null : () => _saveFeedback(app)),
                ]),
              ),
              const SizedBox(height: 12),
              GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                KeyValueRow('Last Status', app.statusMessage, icon: Icons.info_outline_rounded, valueColor: app.error == null ? CcColors.green : CcColors.red),
                KeyValueRow('Pending Offline Feedback', '${app.feedbackQueueCount}', icon: Icons.sync_problem_rounded, valueColor: app.feedbackQueueCount == 0 ? CcColors.green : CcColors.amber),
                if (app.error != null) KeyValueRow('Error', app.error!, icon: Icons.error_outline_rounded, valueColor: CcColors.red),
              ])),
            ],
          );
        },
      ),
    );
  }

  Widget _fieldPair(Widget left, Widget right) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 430) {
          return Column(
            children: [
              left,
              const SizedBox(height: 12),
              right,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: left),
            const SizedBox(width: 10),
            Expanded(child: right),
          ],
        );
      },
    );
  }

  Widget _dropdown(String label, String value, List<String> items, IconData icon, ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      selectedItemBuilder: (context) => items
          .map((item) => Align(
                alignment: Alignment.centerLeft,
                child: Text(item, maxLines: 1, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      items: items
          .map((item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item, maxLines: 1, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: (v) => onChanged(v ?? value),
    );
  }


  Future<void> _autoAiForLatestCall(CrmAppState app) async {
    final lead = selectedLead;
    final eventId = _text(app.pendingFeedback?['event_id'], '');
    final requestId = _int(requestController.text);
    if (lead == null || requestId <= 0 || eventId.isEmpty || eventId == _lastAiEventId) return;
    _lastAiEventId = eventId;
    try {
      final data = await app.getAutoCallFeedback(
        leadId: lead.id,
        requestId: requestId,
        duration: durationController.text,
        notes: notesController.text,
        recordingUrl: recordingUrlController.text,
      );
      if (!mounted) return;
      _applyAiFeedback(data, auto: true);
    } catch (_) {
      // Safe: feedback screen still opens with verified call data even if AI/transcription is unavailable.
    }
  }

  void _applyAiFeedback(Map<String, dynamic> data, {bool auto = false}) {
    final feedback = _asMap(data['auto_feedback'] ?? data['feedback'] ?? data);
    if (feedback.isEmpty) return;
    final outcome = _text(feedback['call_outcome'] ?? feedback['outcome'], '');
    final leadStatus = _text(feedback['lead_status'] ?? feedback['status'], '');
    final summary = _text(feedback['summary'], '');
    final nextAction = _text(feedback['next_action'], '');
    final sentiment = _text(feedback['sentiment'], '');
    final followUpAt = _text(feedback['follow_up_at'], '');
    final confidence = _text(feedback['confidence'], '');
    final transcript = _text(data['transcript'] ?? feedback['transcript'], '');

    setState(() {
      if (outcome.isNotEmpty && statuses.contains(outcome)) selectedStatus = outcome;
      if (leadStatus.isNotEmpty) {
        final low = leadStatus.toLowerCase();
        if (low.contains('interested') || low.contains('qualified') || low.contains('meeting')) selectedStatus = 'Interested';
        if (low.contains('not interested')) selectedStatus = 'Not Interested';
        if (low.contains('wrong')) selectedStatus = 'Wrong Number';
        if (low.contains('lost')) selectedStatus = 'Lost';
        if (low.contains('won')) selectedStatus = 'Won';
      }
      if (sentiment == 'Positive' || sentiment == 'Neutral' || sentiment == 'Negative') customerMood = sentiment;
      final lowStatus = leadStatus.toLowerCase();
      if (lowStatus.contains('interested') || lowStatus.contains('qualified') || lowStatus.contains('meeting') || lowStatus.contains('won')) leadQuality = 'Hot';
      if (lowStatus.contains('new') || lowStatus.contains('contacted')) leadQuality = 'Warm';
      if (lowStatus.contains('lost') || lowStatus.contains('not interested') || lowStatus.contains('wrong')) leadQuality = 'Cold';
      if (followUpAt.isNotEmpty && followUpAt != '-') nextFollowupController.text = followUpAt;
      final aiLines = <String>[];
      if (summary.isNotEmpty && summary != '-') aiLines.add('AI Summary: $summary');
      if (nextAction.isNotEmpty && nextAction != '-') aiLines.add('Next Action: $nextAction');
      if (leadStatus.isNotEmpty && leadStatus != '-') aiLines.add('Suggested Lead Status: $leadStatus');
      if (confidence.isNotEmpty && confidence != '-') aiLines.add('AI Confidence: $confidence%');
      if (transcript.isNotEmpty && transcript != '-') aiLines.add('Transcript/Evidence: $transcript');
      if (aiLines.isNotEmpty) {
        aiSuggestionController.text = aiLines.join('\n');
        final cleanNotes = notesController.text.trim();
        if (cleanNotes.isEmpty || cleanNotes.endsWith('Discussion notes:')) {
          notesController.text = aiSuggestionController.text;
        } else if (!cleanNotes.contains('AI Summary:')) {
          notesController.text = '$cleanNotes\n\n${aiSuggestionController.text}';
        }
      }
    });
  }

  Future<void> _aiAutoFill(CrmAppState app) async {
    final lead = selectedLead;
    if (lead == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final contextText = '''
Lead: ${lead.name}
Phone: ${lead.mobile}
Service: ${productController.text.trim().isEmpty ? lead.service : productController.text.trim()}
Call Status: $selectedStatus
Duration: ${durationController.text}
Mood: $customerMood
Lead Quality: $leadQuality
Budget: ${budgetController.text}
Recording URL: ${recordingUrlController.text}
Notes: ${notesController.text}
Suggest feedback summary, lead quality, next action, follow-up timing, WhatsApp message, and closing script.
''';
    try {
      final requestId = _int(requestController.text);
      if (requestId > 0) {
        final autoData = await app.getAutoCallFeedback(
          leadId: lead.id,
          requestId: requestId,
          duration: durationController.text,
          notes: notesController.text,
          recordingUrl: recordingUrlController.text,
          refreshAi: true,
        );
        if (!mounted) return;
        _applyAiFeedback(autoData);
      } else {
        final suggestion = await app.getAiSuggestion(leadId: lead.id, context: contextText);
        if (!mounted) return;
        setState(() {
          aiSuggestionController.text = suggestion;
          if (notesController.text.trim().isEmpty) notesController.text = 'AI Summary: \n$suggestion';
        });
      }
      messenger.showSnackBar(const SnackBar(content: Text('AI suggestion generated')));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('AI suggestion failed: $e')));
    }
  }

  Future<void> _saveFeedback(CrmAppState app) async {
    final lead = selectedLead;
    if (lead == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await app.submitFeedback(
        lead: lead,
        requestId: _int(requestController.text),
        status: selectedStatus,
        duration: durationController.text.trim().isEmpty ? '00:00:00' : durationController.text.trim(),
        notes: notesController.text.trim(),
        nextFollowup: nextFollowupController.text.trim(),
        customerMood: customerMood,
        leadQuality: leadQuality,
        productInterested: productController.text.trim(),
        budget: budgetController.text.trim(),
        meetingAt: meetingAtController.text.trim(),
        proposalRequired: proposalRequired,
        whatsappSend: whatsappSend,
        recordingUrl: recordingUrlController.text.trim(),
        aiSuggestion: aiSuggestionController.text.trim(),
      );
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(app.feedbackQueueCount > 0 ? 'Feedback saved locally. Auto-sync will retry.' : 'Feedback saved in CRM')));
      if (widget.openedFromCall && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Feedback save failed: $e')));
    }
  }
}
