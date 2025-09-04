import 'package:flutter/material.dart';
import '../services/update_service.dart';

class UpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;
  final VoidCallback? onSkip;
  final VoidCallback? onUpdate;
  final VoidCallback? onLater;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    this.onSkip,
    this.onUpdate,
    this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: Row(
        children: [
          Icon(
            Icons.system_update,
            color: Theme.of(context).colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text('Update Available'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Version ${updateInfo.version}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "What's New:",
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Text(
                updateInfo.changelog.isNotEmpty 
                    ? updateInfo.changelog 
                    : 'Bug fixes and performance improvements.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          if (updateInfo.isForced) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This is a required update',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (!updateInfo.isForced) ...[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onSkip?.call();
            },
            child: const Text('Skip This Version'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onLater?.call();
            },
            child: const Text('Later'),
          ),
        ],
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            onUpdate?.call();
          },
          icon: const Icon(Icons.download),
          label: Text(updateInfo.isForced ? 'Update Now' : 'Update'),
        ),
      ],
    );
  }

  static Future<void> show(
    BuildContext context,
    UpdateInfo updateInfo, {
    VoidCallback? onSkip,
    VoidCallback? onUpdate,
    VoidCallback? onLater,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: !updateInfo.isForced,
      builder: (context) => UpdateDialog(
        updateInfo: updateInfo,
        onSkip: onSkip,
        onUpdate: onUpdate,
        onLater: onLater,
      ),
    );
  }
}

class UpdateNotificationBanner extends StatelessWidget {
  final UpdateInfo updateInfo;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const UpdateNotificationBanner({
    super.key,
    required this.updateInfo,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.system_update,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Update Available',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        'Version ${updateInfo.version}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!updateInfo.isForced && onDismiss != null)
                  IconButton(
                    onPressed: onDismiss,
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}