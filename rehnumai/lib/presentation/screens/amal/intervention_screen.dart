import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme.dart';
import '../../widgets/app_top_bar.dart';

class InterventionScreen extends StatefulWidget {
  const InterventionScreen({super.key});

  @override
  State<InterventionScreen> createState() => _InterventionScreenState();
}

class _InterventionScreenState extends State<InterventionScreen> {
  final TextEditingController _gutCheckController = TextEditingController();
  bool _messageSent = false;

  @override
  void dispose() {
    _gutCheckController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBright,
      appBar: const AppTopBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Context header
            _ContextHeader(),
            const SizedBox(height: 20),

            // ── AI Diagnosis Banner
            _DiagnosisBanner(),
            const SizedBox(height: 20),

            // ── Draft parent message card
            _ParentMessageCard(
              isSent: _messageSent,
              onSend: () => setState(() => _messageSent = true),
            ),
            const SizedBox(height: 12),

            // ── Escalate
            _ActionListTile(
              icon: Icons.supervisor_account,
              iconBg: AppColors.secondaryContainer,
              iconColor: AppColors.onSecondaryContainer,
              title: 'Escalate to Counselor',
              subtitle: 'Request a formal financial review',
            ),
            const SizedBox(height: 12),

            // ── Home visit
            _ActionListTile(
              icon: Icons.home_work,
              iconBg: AppColors.surfaceContainerHigh,
              iconColor: AppColors.onSurfaceVariant,
              title: 'Schedule Home Visit',
              subtitle: 'Check-in personally with the family',
            ),
            const SizedBox(height: 24),

            // ── Gut-check
            _GutCheckCard(controller: _gutCheckController),
          ],
        ),
      ),
    );
  }
}

// ─── Context Header ───────────────────────────────────────────────────────────

class _ContextHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Intervention Hub',
          style: AppTextStyles.headlineMd.copyWith(color: AppColors.inkText),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
            children: [
              const TextSpan(text: 'Recommended actions for '),
              TextSpan(
                text: 'Ali Khan',
                style: AppTextStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const TextSpan(text: ' (Grade 8)'),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── AI Diagnosis Banner ─────────────────────────────────────────────────────

class _DiagnosisBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inverseOnSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: AppColors.riskMedium, width: 4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb, color: AppColors.secondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI DIAGNOSIS',
                  style: AppTextStyles.labelCaps.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                    children: [
                      const TextSpan(
                        text:
                            'Pattern of 3 consecutive absences coinciding with fee collection week. High probability of ',
                      ),
                      TextSpan(
                        text: 'financial strain',
                        style: AppTextStyles.bodySm.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkText,
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Parent Message Card ──────────────────────────────────────────────────────

class _ParentMessageCard extends StatefulWidget {
  const _ParentMessageCard({required this.isSent, required this.onSend});
  final bool isSent;
  final VoidCallback onSend;

  @override
  State<_ParentMessageCard> createState() => _ParentMessageCardState();
}

class _ParentMessageCardState extends State<_ParentMessageCard> {
  bool _isEditing = false;
  final _editController = TextEditingController(
    text:
        'Assalam-o-Alaikum, this is Ustaad Ahmad. I noticed Ali has missed a few days this week. We value his presence in class greatly. If there is any difficulty regarding the recent fee schedule, please know the school is here to support you. Let\'s talk.',
  );

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Decorative orb
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Draft Parent Message',
                        style: AppTextStyles.headlineMd.copyWith(
                          fontSize: 18,
                          color: AppColors.inkText,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Recommended',
                        style: AppTextStyles.labelCaps.copyWith(
                          color: AppColors.onPrimaryContainer,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Message bubble
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBright,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: _isEditing
                      ? TextField(
                          controller: _editController,
                          maxLines: 5,
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        )
                      : Text(
                          widget.isSent
                              ? '✅ Message sent to Ali\'s parent'
                              : _editController.text,
                          style: AppTextStyles.bodySm.copyWith(
                            color: widget.isSent
                                ? AppColors.tertiary
                                : AppColors.onSurfaceVariant,
                            height: 1.6,
                          ),
                        ),
                ),
                const SizedBox(height: 12),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!widget.isSent) ...[
                      IconButton(
                        icon: Icon(
                          _isEditing ? Icons.check : Icons.edit,
                          size: 20,
                          color: AppColors.onSurfaceVariant,
                        ),
                        onPressed: () {
                          setState(() => _isEditing = !_isEditing);
                        },
                        tooltip: _isEditing ? 'Done editing' : 'Edit message',
                      ),
                      const SizedBox(width: 4),
                      ElevatedButton.icon(
                        onPressed: widget.onSend,
                        icon: const Icon(Icons.send, size: 16),
                        label: const Text('Approve & Send'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          elevation: 0,
                          shape: const StadiumBorder(),
                          textStyle: AppTextStyles.labelCaps,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ] else
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Send Another',
                          style: AppTextStyles.labelCaps.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action List Tile ─────────────────────────────────────────────────────────

class _ActionListTile extends StatelessWidget {
  const _ActionListTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkText,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Gut-Check Card ───────────────────────────────────────────────────────────

class _GutCheckCard extends StatelessWidget {
  const _GutCheckCard({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.sandBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceDim),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                "Ustaad's Gut-Check",
                style: AppTextStyles.headlineMd.copyWith(
                  fontSize: 18,
                  color: AppColors.inkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Is the AI missing something? Add your personal observation to improve future recommendations.',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'e.g., Ali mentioned his father was unwell last week...',
              filled: true,
              fillColor: AppColors.surfaceBright,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.inkText),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceContainerHigh,
                foregroundColor: AppColors.onSurface,
                elevation: 0,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                textStyle: AppTextStyles.labelCaps,
              ),
              child: const Text('Save Note'),
            ),
          ),
        ],
      ),
    );
  }
}

