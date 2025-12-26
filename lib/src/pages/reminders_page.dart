import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/reminder.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  final _storage = StorageService();
  final _notifications = NotificationService();
  List<Reminder> _reminders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final remindersResult = await _storage.getReminders();
    setState(() {
      _reminders = remindersResult.dataOrNull ?? [];
      _loading = false;
    });
  }

  Future<void> _toggleReminder(Reminder reminder) async {
    final updated = reminder.copyWith(isEnabled: !reminder.isEnabled);
    await _storage.updateReminder(updated);

    if (updated.isEnabled) {
      await _notifications.scheduleReminder(updated);
    } else {
      await _notifications.cancelReminder(updated.id);
    }

    await _loadReminders();
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    await _notifications.cancelReminder(reminder.id);
    await _storage.deleteReminder(reminder.id);
    await _loadReminders();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${reminder.title} deleted'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool> _confirmDelete(Reminder reminder) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.trash2, color: AppColors.error, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Delete Reminder?'),
          ],
        ),
        titleTextStyle: AppTextStyles.h4.copyWith(color: AppColors.gray900),
        content: Text(
          'Are you sure you want to delete "${reminder.title}"? This action cannot be undone.',
          style: AppTextStyles.body.copyWith(color: AppColors.gray600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray500),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showAddReminderSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddReminderSheet(
        onSave: (reminder) async {
          await _storage.addReminder(reminder);
          await _notifications.scheduleReminder(reminder);
          await _loadReminders();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.gray700),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Reminders',
          style: AppTextStyles.h3.copyWith(color: AppColors.gray900),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.bellRing, color: AppColors.primary),
            tooltip: 'Test Notification',
            onPressed: () {
              _notifications.showTestNotification();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Test notification sent!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _reminders.isEmpty
              ? _buildEmptyState()
              : _buildRemindersList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddReminderSheet,
        backgroundColor: AppColors.primary,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.bellRing,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Reminders Yet',
              style: AppTextStyles.h3.copyWith(color: AppColors.gray800),
            ),
            const SizedBox(height: 8),
            Text(
              'Set up reminders to stay on track\nwith your wellness goals',
              style: AppTextStyles.body.copyWith(color: AppColors.gray500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _showAddReminderSheet,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Add Reminder'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacing6),
      itemCount: _reminders.length,
      itemBuilder: (context, index) {
        final reminder = _reminders[index];
        return _ReminderCard(
          reminder: reminder,
          onToggle: () => _toggleReminder(reminder),
          onDelete: () async {
            final confirmed = await _confirmDelete(reminder);
            if (confirmed) {
              _deleteReminder(reminder);
            }
          },
        );
      },
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ReminderCard({
    required this.reminder,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(reminder.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false; // Don't auto-dismiss, let onDelete handle it
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(
            color: reminder.isEnabled ? AppColors.gray100 : AppColors.gray200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: reminder.isEnabled
                    ? _getTypeColor(reminder.type).withValues(alpha: 0.1)
                    : AppColors.gray100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  reminder.type.emoji,
                  style: TextStyle(
                    fontSize: 24,
                    color: reminder.isEnabled ? null : AppColors.gray400,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: reminder.isEnabled
                          ? AppColors.gray800
                          : AppColors.gray400,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.clock,
                        size: 12,
                        color: reminder.isEnabled
                            ? AppColors.gray400
                            : AppColors.gray300,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        reminder.formattedTime,
                        style: AppTextStyles.caption.copyWith(
                          color: reminder.isEnabled
                              ? AppColors.gray500
                              : AppColors.gray400,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        LucideIcons.repeat,
                        size: 12,
                        color: reminder.isEnabled
                            ? AppColors.gray400
                            : AppColors.gray300,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          reminder.frequencyDescription,
                          style: AppTextStyles.caption.copyWith(
                            color: reminder.isEnabled
                                ? AppColors.gray500
                                : AppColors.gray400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 24,
                decoration: BoxDecoration(
                  color: reminder.isEnabled ? AppColors.primary : AppColors.gray200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: reminder.isEnabled
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 18,
                    height: 18,
                    margin: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(ReminderType type) {
    switch (type) {
      case ReminderType.hydration:
        return AppColors.info;
      case ReminderType.stretchBreak:
        return AppColors.secondary;
      case ReminderType.meditation:
        return AppColors.accent;
      case ReminderType.custom:
        return AppColors.primary;
    }
  }
}


class AddReminderSheet extends StatefulWidget {
  final Future<void> Function(Reminder) onSave;

  const AddReminderSheet({super.key, required this.onSave});

  @override
  State<AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<AddReminderSheet> {
  ReminderType _selectedType = ReminderType.hydration;
  ReminderFrequency _selectedFrequency = ReminderFrequency.daily;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  final Set<int> _selectedDays = {};
  bool _saving = false;

  final _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.gray900,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _save() async {
    if (_selectedFrequency == ReminderFrequency.custom && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one day'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final reminder = Reminder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: _selectedType,
      title: _selectedType.displayName,
      message: _selectedType.defaultMessage,
      time: _selectedTime,
      frequency: _selectedFrequency,
      customDays: _selectedDays.toList()..sort(),
    );

    await widget.onSave(reminder);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${reminder.title} reminder set for ${reminder.formattedTime}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'New Reminder',
              style: AppTextStyles.h2.copyWith(color: AppColors.gray900),
            ),
            const SizedBox(height: 24),

            // Reminder Type
            Text(
              'REMINDER TYPE',
              style: AppTextStyles.tiny.copyWith(
                color: AppColors.gray400,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ReminderType.values.map((type) {
                final isSelected = _selectedType == type;
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.gray50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.gray200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(type.emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          type.displayName,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isSelected ? AppColors.primary : AppColors.gray600,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Time
            Text(
              'TIME',
              style: AppTextStyles.tiny.copyWith(
                color: AppColors.gray400,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _selectTime,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gray200),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.clock, size: 20, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      _formatTime(_selectedTime),
                      style: AppTextStyles.h3.copyWith(color: AppColors.gray800),
                    ),
                    const Spacer(),
                    const Icon(LucideIcons.chevronRight, size: 20, color: AppColors.gray400),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Frequency
            Text(
              'REPEAT',
              style: AppTextStyles.tiny.copyWith(
                color: AppColors.gray400,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: ReminderFrequency.values.map((freq) {
                final isSelected = _selectedFrequency == freq;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _selectedFrequency = freq;
                      if (freq != ReminderFrequency.custom) {
                        _selectedDays.clear();
                      }
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(
                        right: freq != ReminderFrequency.custom ? 8 : 0,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.gray50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.gray200,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          freq.displayName,
                          style: AppTextStyles.captionBold.copyWith(
                            color: isSelected ? Colors.white : AppColors.gray600,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            // Custom days selector - responsive
            if (_selectedFrequency == ReminderFrequency.custom) ...[
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final daySize = ((constraints.maxWidth - 36) / 7).clamp(32.0, 44.0);
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (index) {
                      final day = index + 1;
                      final isSelected = _selectedDays.contains(day);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedDays.remove(day);
                            } else {
                              _selectedDays.add(day);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: daySize,
                          height: daySize,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.gray50,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.gray200,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _dayLabels[index],
                              style: AppTextStyles.captionBold.copyWith(
                                color: isSelected ? Colors.white : AppColors.gray600,
                                fontSize: daySize * 0.32,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ],
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Set Reminder',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
