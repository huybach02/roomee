import 'package:flutter/material.dart';
import 'package:roomee/core/configs/app_theme.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/offline/contracts/sync_dtos.dart';
import 'package:roomee/core/offline/repository/offline_crud_repository.dart';
import 'package:roomee/core/widgets/app_button.dart';
import 'package:roomee/core/widgets/app_confirm_dialog.dart';
import 'package:roomee/core/widgets/app_notification.dart';

class SyncConflictSheet extends StatefulWidget {
  final OfflineCrudRepository repository;
  final VoidCallback? onResolved;

  const SyncConflictSheet({
    super.key,
    required this.repository,
    this.onResolved,
  });

  static Future<void> show(
    BuildContext context, {
    required OfflineCrudRepository repository,
    VoidCallback? onResolved,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SyncConflictSheet(
        repository: repository,
        onResolved: onResolved,
      ),
    );
  }

  @override
  State<SyncConflictSheet> createState() => _SyncConflictSheetState();
}

class _SyncConflictSheetState extends State<SyncConflictSheet> {
  List<SyncMutation> _failedMutations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFailed();
  }

  Future<void> _loadFailed() async {
    final list = await widget.repository.getFailedMutations();
    if (mounted) {
      setState(() {
        _failedMutations = list;
        _isLoading = false;
      });
      if (list.isEmpty) {
        widget.onResolved?.call();
      }
    }
  }

  Future<void> _handleDiscard(SyncMutation mutation) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: t('common.discardConfirmTitle'),
      message: t('common.discardConfirmMessage'),
      confirmText: t('common.discardChange'),
      cancelText: t('validateErrors.close'),
      isDanger: true,
    );

    if (confirmed == true && mounted) {
      await widget.repository.discardMutation(mutationId: mutation.id);
      if (!mounted) return;
      AppNotification.showSuccess(
        context,
        t('common.deletedSuccess'),
      );
      await _loadFailed();
      if (_failedMutations.isEmpty && mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _handleRetry(SyncMutation mutation) async {
    await widget.repository.retryFailedMutation(mutationId: mutation.id);
    if (!mounted) return;
    AppNotification.showInfo(
      context,
      t('common.syncingData'),
    );
    await _loadFailed();
    if (_failedMutations.isEmpty && mounted) {
      Navigator.of(context).pop();
    }
  }

  String _formatAction(SyncMutationAction action) {
    switch (action) {
      case SyncMutationAction.create:
        return t('common.actionCreate');
      case SyncMutationAction.update:
        return t('common.actionUpdate');
      case SyncMutationAction.delete:
        return t('common.actionDelete');
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.75;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: DefaultColors.secondary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t('common.syncErrorTitle'),
                  style: const TextStyle(
                    fontSize: FontSizes.standardUp,
                    fontWeight: FontWeight.bold,
                    color: DefaultColors.primary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          Text(
            t('common.syncErrorSubtitle'),
            style: TextStyle(
              fontSize: FontSizes.standard,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          // Content
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_failedMutations.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  t('common.syncCompleted'),
                  style: const TextStyle(
                    fontSize: FontSizes.standard,
                    color: Colors.grey,
                  ),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _failedMutations.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _failedMutations[index];
                  final errorMsg =
                      item.errorMessage ?? t('errors.unknown');
                  final actionLabel = _formatAction(item.action);

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: DefaultColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$actionLabel: ${item.module}',
                                style: const TextStyle(
                                  fontSize: FontSizes.small,
                                  fontWeight: FontWeight.w600,
                                  color: DefaultColors.primary,
                                ),
                              ),
                            ),
                            if (item.statusCode != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '(${item.statusCode})',
                                style: TextStyle(
                                  fontSize: FontSizes.small,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          errorMsg,
                          style: const TextStyle(
                            fontSize: FontSizes.standard,
                            color: Color(0xFFC62828),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => _handleDiscard(item),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 16,
                                color: Color(0xFFC62828),
                              ),
                              label: Text(
                                t('common.discardChange'),
                                style: const TextStyle(
                                  color: Color(0xFFC62828),
                                  fontSize: FontSizes.small,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            AppButton(
                              text: t('common.retryChange'),
                              type: AppButtonType.primary,
                              width: null,
                              height: 36.0,
                              fontSize: FontSizes.small,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              onPressed: () => _handleRetry(item),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
