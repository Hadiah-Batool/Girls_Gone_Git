// lib/domain/agents/agent_orchestrator.dart
//
// Rehnumai Multi-Agent Orchestrator
//
// Implements a 4-node sequential reasoning chain that analyses a student's
// time-series data (attendance, fees, exam scores, teacher notes) and produces
// a structured risk diagnosis + parent-friendly WhatsApp intervention message.
//
// Each node:
//   1. Yields a "thinking" AgentReasoningEvent (outputJson == null)
//   2. Calls OpenRouter via OpenRouterService
//   3. Yields a "done" AgentReasoningEvent (outputJson == parsed result)
//
// After all four nodes, a final AgentStep.complete sentinel is yielded.
//
// Usage:
//   final orchestrator = AgentOrchestrator();
//   await for (final event in orchestrator.analyzeStudentRisk(student)) {
//     print(event);
//   }

import 'dart:convert';
import '../../data/models/student_model.dart';
import '../../core/services/gemini_service.dart';
import 'agent_state.dart';

class AgentOrchestrator {
  final OpenRouterService _service;

  AgentOrchestrator({OpenRouterService? service})
      : _service = service ?? OpenRouterService.instance;

  // ────────────────────────────────────────────────────────────────────────
  // Public API
  // ────────────────────────────────────────────────────────────────────────

  /// Analyses a [student]'s risk profile through a 4-step sequential chain.
  ///
  /// Emits 9 events total:
  ///   - 2 events per agent node (thinking + done) × 4 nodes = 8 events
  ///   - 1 final [AgentStep.complete] sentinel
  ///
  /// Throws re-throws [OpenRouterException] if any node fails after
  /// exhausting the fallback model.
  Stream<AgentReasoningEvent> analyzeStudentRisk(Student student) async* {
    // Serialise student data once; reused across all node prompts
    final studentJson = _escapeForPrompt(student.toJson());

    // ── Node 1: Pattern Analyst ──────────────────────────────────────────
    yield AgentReasoningEvent.thinking(
      step: AgentStep.patternAnalyst,
      statusMessage: 'Inspecting time-series logs for attendance, '
          'fee, and score events…',
    );

    final node1Output = await _runPatternAnalyst(studentJson);

    yield AgentReasoningEvent.done(
      step: AgentStep.patternAnalyst,
      statusMessage: 'Timeline observations extracted '
          '(${(node1Output["timeline_observations"] as List?)?.length ?? 0} events).',
      outputJson: node1Output,
    );

    // ── Node 2: Root-Cause Reasoner ──────────────────────────────────────
    yield AgentReasoningEvent.thinking(
      step: AgentStep.rootCause,
      statusMessage: 'Cross-referencing event sequence with teacher '
          'soft-notes to diagnose root cause…',
    );

    final node2Output = await _runRootCauseReasoner(
      studentJson: studentJson,
      node1Output: node1Output,
    );

    yield AgentReasoningEvent.done(
      step: AgentStep.rootCause,
      statusMessage: 'Root cause identified: '
          '${node2Output["root_cause"] ?? "Unknown"} '
          '(confidence: ${node2Output["confidence"] ?? "N/A"}).',
      outputJson: node2Output,
    );

    // ── Node 3: Self-Critique Agent ──────────────────────────────────────
    yield AgentReasoningEvent.thinking(
      step: AgentStep.selfCritique,
      statusMessage: 'Auditing diagnosis for false positives and '
          'isolated events vs. sustained trends…',
    );

    final node3Output = await _runSelfCritique(
      studentJson: studentJson,
      node1Output: node1Output,
      node2Output: node2Output,
    );

    final isSustained = node3Output['is_sustained_trend'] as bool? ?? false;
    yield AgentReasoningEvent.done(
      step: AgentStep.selfCritique,
      statusMessage: isSustained
          ? 'Sustained trend confirmed (>2 weeks). Proceeding to intervention.'
          : 'Isolated event detected. Intervention will reflect lower urgency.',
      outputJson: node3Output,
    );

    // ── Node 4: Intervention Planner ─────────────────────────────────────
    yield AgentReasoningEvent.thinking(
      step: AgentStep.interventionPlanner,
      statusMessage: 'Drafting a warm, parent-friendly WhatsApp '
          'message based on the diagnosis…',
    );

    final node4Output = await _runInterventionPlanner(
      studentJson: studentJson,
      node2Output: node2Output,
      node3Output: node3Output,
    );

    yield AgentReasoningEvent.done(
      step: AgentStep.interventionPlanner,
      statusMessage: 'Intervention message drafted successfully.',
      outputJson: node4Output,
    );

    // ── Complete sentinel ────────────────────────────────────────────────
    yield AgentReasoningEvent.complete(
      summary: {
        'student_id': student.id,
        'student_name': student.name,
        'root_cause': node2Output['root_cause'],
        'confidence': node2Output['confidence'],
        'is_sustained_trend': node3Output['is_sustained_trend'],
        'revised_diagnosis': node3Output['revised_diagnosis'],
        'whatsapp_message': node4Output['whatsapp_message'],
        'timeline_events_count':
            (node1Output['timeline_observations'] as List?)?.length ?? 0,
      },
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // Node 1 – Pattern Analyst
  // ────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _runPatternAnalyst(
    String studentJson,
  ) async {
    const systemPrompt = '''
You are an Objective Educational Data Inspector.
Your ONLY task is to read raw time-series student data and produce a precise, 
chronological list of observable events. 

RULES (follow strictly):
- Report ONLY what the data shows. No hypotheses, no root-cause guessing.
- Calculate the delta_t_days between consecutive events.
- Include ALL attendance drops, score drops, fee events, and teacher note dates.
- Output MUST be valid JSON matching this exact schema:

{
  "timeline_observations": [
    {
      "day_offset": <integer, days from first event>,
      "date": "<YYYY-MM-DD>",
      "event_type": "<fee_overdue | attendance_drop | attendance_recovery | score_drop | score_stable | score_recovery | teacher_note | fee_paid>",
      "detail": "<one-sentence factual description>",
      "delta_t_days": <integer, days since previous event in this list; 0 for first>
    }
  ],
  "observation_window_days": <integer>,
  "total_absences": <integer>,
  "attendance_rate_pct": <float>,
  "fee_overdue": <boolean>,
  "score_trend": "<declining | stable | recovering | insufficient_data>"
}
''';

    final userPrompt = '''
Inspect the following student data and produce the timeline observations JSON.

STUDENT DATA:
$studentJson
''';

    return await _service.chatWithFallback(
      messages: [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      temperature: 0.1, // Near-deterministic for factual extraction
      maxTokens: 1500,
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // Node 2 – Root-Cause Reasoner
  // ────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _runRootCauseReasoner({
    required String studentJson,
    required Map<String, dynamic> node1Output,
  }) async {
    const systemPrompt = '''
You are an Experienced Educational Diagnostician with 15 years of field 
experience in low-income school contexts in South Asia.

You receive:
  A) A chronological timeline of observable events from an independent data inspector.
  B) Raw student data including soft teacher notes.

Your task is to identify the PRIMARY root cause of the student's risk pattern.

VALID ROOT CAUSE LABELS (use EXACTLY one):
  - "Financial Strain"   : Fee overdue is the first or dominant trigger.
  - "Academic Struggle"  : Score decline precedes attendance drop.
  - "Attendance-Led"     : Attendance is the primary problem with unclear cause.
  - "Mixed"              : Multiple causes interact; explain which dominates.

RULES:
  - Weight the SEQUENCE of events heavily. The first event in the timeline is a key signal.
  - Teacher soft-notes are qualitative evidence – treat them as supporting data.
  - Confidence should be "High", "Medium", or "Low".
  - Output MUST be valid JSON matching this schema exactly:

{
  "root_cause": "<Financial Strain | Academic Struggle | Attendance-Led | Mixed>",
  "confidence": "<High | Medium | Low>",
  "primary_trigger_event": "<brief description of the first alarming event>",
  "event_sequence_summary": "<2-3 sentences: how events unfolded chronologically>",
  "teacher_note_evidence": "<what the soft notes reveal; null if no notes>",
  "evidence_summary": "<3-4 sentences synthesising all evidence for this diagnosis>",
  "alternative_hypothesis": "<second-best label and why it was ruled out>"
}
''';

    final userPrompt = '''
TIMELINE OBSERVATIONS (from Pattern Analyst):
${_escapeForPrompt(node1Output)}

RAW STUDENT DATA (including teacher notes):
$studentJson

Based on the above, diagnose the root cause.
''';

    return await _service.chatWithFallback(
      messages: [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      temperature: 0.3,
      maxTokens: 1200,
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // Node 3 – Self-Critique Agent
  // ────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _runSelfCritique({
    required String studentJson,
    required Map<String, dynamic> node1Output,
    required Map<String, dynamic> node2Output,
  }) async {
    const systemPrompt = '''
You are a Skeptical QA Auditor reviewing an AI-generated educational risk diagnosis.
Your job is to challenge whether the diagnosis reflects a SUSTAINED pattern 
(more than 2 weeks of consistent signals) or an ISOLATED bad period (e.g. one sick 
week, one hard exam, a temporary family event).

EVALUATION CRITERIA:
  1. Sustained trend: ≥ 3 consecutive absences spanning > 14 days OR ≥ 2 consecutive 
     score drops > 15 percentage points over > 14 days.
  2. Isolated event: Signals appear in a single short window (≤ 7 days) with strong 
     recovery evidence OR an explicit explanation (e.g. medical note, family event).

RULES:
  - Be skeptical. Assume isolated unless evidence clearly shows sustained trend.
  - Output MUST be valid JSON matching this schema exactly:

{
  "is_sustained_trend": <true | false>,
  "weeks_observed": <float, number of weeks of the signal window>,
  "consecutive_absences_max": <integer, longest run of consecutive absences>,
  "score_drops_count": <integer, number of score drops ≥ 10 points>,
  "isolation_evidence": "<any teacher notes or data suggesting this is temporary; null if none>",
  "justification": "<2-3 sentences explaining the sustained vs isolated verdict>",
  "revised_diagnosis": "<final confirmed root cause label or 'Isolated – No Intervention Needed'>",
  "urgency_level": "<Critical | High | Medium | Low | Monitor>"
}
''';

    final userPrompt = '''
ORIGINAL DIAGNOSIS (from Root-Cause Reasoner):
${_escapeForPrompt(node2Output)}

TIMELINE DATA (from Pattern Analyst):
${_escapeForPrompt(node1Output)}

RAW STUDENT DATA (for context):
$studentJson

Audit the diagnosis. Is this a sustained trend or an isolated event?
''';

    return await _service.chatWithFallback(
      messages: [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      temperature: 0.2, // Strict audit – low randomness
      maxTokens: 1000,
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // Node 4 – Intervention Planner
  // ────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _runInterventionPlanner({
    required String studentJson,
    required Map<String, dynamic> node2Output,
    required Map<String, dynamic> node3Output,
  }) async {
    // Extract key fields for targeted prompting
    final studentName =
        (jsonDecode(studentJson) as Map<String, dynamic>)['name'] as String? ??
            'the student';
    final rootCause = node2Output['root_cause'] as String? ?? 'unknown concern';
    final urgency = node3Output['urgency_level'] as String? ?? 'Medium';
    final isSustained = node3Output['is_sustained_trend'] as bool? ?? false;
    final revisedDiagnosis =
        node3Output['revised_diagnosis'] as String? ?? rootCause;

    final systemPrompt = '''
You are a Community Action Coordinator working with a school in an underserved 
urban area of Pakistan. You write WhatsApp messages to parents in clear, warm, 
non-alarming language. You never use jargon, never blame the family, and always 
frame outreach as the school caring about the child.

CONTEXT FOR THIS MESSAGE:
  - Student: $studentName
  - Root Cause: $rootCause
  - Sustained Trend: $isSustained
  - Urgency: $urgency
  - Revised Diagnosis: $revisedDiagnosis

MESSAGE GUIDELINES BY ROOT CAUSE:
  - "Financial Strain": Mention fee support options, never shame. 
    Offer a meeting to discuss flexible arrangements.
  - "Academic Struggle": Focus on learning support, ask about home study environment. 
    Offer tutoring or extra help.
  - "Attendance-Led": Express care and concern, ask if everything is okay at home. 
    Avoid accusatory tone.
  - "Mixed": Address both concerns gently in sequence.
  - "Isolated – No Intervention Needed": Send a warm check-in message only. 
    Acknowledge the student's return and consistency.

TONE: Warm, supportive, brief (3-5 sentences max), written as if by a caring teacher.
LANGUAGE: Write in English. Keep sentences simple and short.

Output MUST be valid JSON matching this schema exactly:

{
  "whatsapp_message": "<the full message text, 3-5 sentences>",
  "tone": "<supportive | urgent | informational | check-in>",
  "language": "English",
  "recommended_action": "<what the school should do in parallel, e.g. schedule fee counselling>",
  "follow_up_days": <integer, recommended days until next check-in>
}
''';

    final userPrompt = '''
Write a WhatsApp message for the parent of $studentName.
Use the diagnosis and urgency level below to calibrate the tone.

FINAL DIAGNOSIS:
${_escapeForPrompt(node3Output)}

ROOT-CAUSE DETAIL:
${_escapeForPrompt(node2Output)}
''';

    return await _service.chatWithFallback(
      messages: [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      temperature: 0.6, // Slightly higher for natural language warmth
      maxTokens: 800,
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ────────────────────────────────────────────────────────────────────────

  /// Serialises a Map to a compact, prompt-safe JSON string.
  String _escapeForPrompt(Map<String, dynamic> data) {
    // jsonEncode handles all escaping (quotes, newlines, unicode)
    return const JsonEncoder.withIndent('  ').convert(data);
  }
}
