import 'package:flutter/material.dart';
import 'package:roomee/core/configs/app_theme.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/utils/function_helper.dart';

/// Component thanh thông báo ngoại tuyến (Offline Banner)
/// Tự động hiển thị khi người dùng đang xem dữ liệu offline từ cache
class AppOfflineBanner extends StatelessWidget {
  final DateTime? lastFetchedAt;
  final String? message;

  const AppOfflineBanner({
    super.key,
    this.lastFetchedAt,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    String text = message ?? t('common.offlineModeNotice');
    if (lastFetchedAt != null) {
      final timeStr = FunctionHelper.formatDateTime(
        lastFetchedAt,
        pattern: 'HH:mm dd/MM',
      );
      text = '$text (${t('common.lastUpdated', {'time': timeStr})})';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: DefaultColors.secondary.withValues(alpha: 0.12),
        border: Border(
          top: BorderSide(
            color: DefaultColors.secondary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 16,
            color: DefaultColors.secondary,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: FontSizes.small,
                fontWeight: FontWeight.w600,
                color: DefaultColors.secondary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
