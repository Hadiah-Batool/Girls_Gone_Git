// lib/domain/agents/agent_state.dart
//
// Typed event model for the Rehnumai multi-agent reasoning chain.
// The orchestrator emits a Stream<AgentReasoningEvent>; each event
// represents either a "thinking" notification or a "done" result for
// one agent node in the pipeline.

/// Identifies which node in the 4-step chain an event belongs to.
enum AgentStep {
  /// Node 1 – Objective Educational Data Inspector
  patternAnalyst,

  /// Node 2 – Experienced Educational Diagnostician
  rootCause,

  /// Node 3 – Skeptical QA Auditor
  selfCritique,

  /// Node 4 – Community Action Coordinator
  interventionPlanner,

  /// Sentinel value emitted once after all four nodes complete.
  complete,
}

/// Extension to provide human-readable metadata for each step.
extension AgentStepInfo on AgentStep {
  String get displayName {
    switch (this) {
      case AgentStep.patternAnalyst:
        return 'Pattern Analyst';
      case AgentStep.rootCause:
        return 'Root-Cause Reasoner';
      case AgentStep.selfCritique:
        return 'Self-Critique Agent';
      case AgentStep.interventionPlanner:
        return 'Intervention Planner';
      case AgentStep.complete:
        return 'Analysis Complete';
    }
  }

  String get persona {
    switch (this) {
      case AgentStep.patternAnalyst:
        return 'Objective Educational Data Inspector';
      case AgentStep.rootCause:
        return 'Experienced Educational Diagnostician';
      case AgentStep.selfCritique:
        return 'Skeptical QA Auditor';
      case AgentStep.interventionPlanner:
        return 'Community Action Coordinator';
      case AgentStep.complete:
        return 'System';
    }
  }

  /// Icon glyph (Unicode) for display in chat-style UIs.
  String get icon {
    switch (this) {
      case AgentStep.patternAnalyst:
        return '🔍';
      case AgentStep.rootCause:
        return '🧠';
      case AgentStep.selfCritique:
        return '🔎';
      case AgentStep.interventionPlanner:
        return '💬';
      case AgentStep.complete:
        return '✅';
    }
  }
}

/// A single event emitted by [AgentOrchestrator.analyzeStudentRisk].
///
/// Two categories of events exist per node:
/// - **Thinking**: [outputJson] is null; [statusMessage] describes ongoing work.
/// - **Done**: [outputJson] holds the parsed JSON response from the LLM.
///
/// A final [AgentStep.complete] event is always emitted after all four nodes,
/// with [outputJson] containing a summary of the full chain's output.
class AgentReasoningEvent {
  /// Which pipeline node this event belongs to.
  final AgentStep step;

  /// Human-readable name for the agent (mirrors [step.displayName]).
  final String agentName;

  /// Short persona label shown in UI thought-bubble headers.
  final String persona;

  /// Short human-readable status line, e.g. "Inspecting attendance logs…".
  final String statusMessage;

  /// Parsed JSON output from the LLM; null during "thinking" phase.
  final Map<String, dynamic>? outputJson;

  /// Whether this event represents a completed (done) state.
  /// When false, the node is still being processed.
  final bool isDone;

  const AgentReasoningEvent({
    required this.step,
    required this.agentName,
    required this.persona,
    required this.statusMessage,
    this.outputJson,
    required this.isDone,
  });

  /// Factory for the "thinking" notification emitted before an API call.
  factory AgentReasoningEvent.thinking({
    required AgentStep step,
    required String statusMessage,
  }) {
    return AgentReasoningEvent(
      step: step,
      agentName: step.displayName,
      persona: step.persona,
      statusMessage: statusMessage,
      outputJson: null,
      isDone: false,
    );
  }

  /// Factory for the "done" event emitted after a successful API response.
  factory AgentReasoningEvent.done({
    required AgentStep step,
    required String statusMessage,
    required Map<String, dynamic> outputJson,
  }) {
    return AgentReasoningEvent(
      step: step,
      agentName: step.displayName,
      persona: step.persona,
      statusMessage: statusMessage,
      outputJson: outputJson,
      isDone: true,
    );
  }

  /// Factory for the terminal [AgentStep.complete] sentinel.
  factory AgentReasoningEvent.complete({
    required Map<String, dynamic> summary,
  }) {
    return AgentReasoningEvent(
      step: AgentStep.complete,
      agentName: AgentStep.complete.displayName,
      persona: AgentStep.complete.persona,
      statusMessage: 'Full analysis pipeline completed successfully.',
      outputJson: summary,
      isDone: true,
    );
  }

  @override
  String toString() =>
      '[${step.displayName}] ${isDone ? "✓" : "…"} $statusMessage';
}
