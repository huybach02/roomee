import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/screens/loading_screen.dart';
import 'package:roomee/core/widgets/app_confirm_dialog.dart';
import 'package:roomee/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:roomee/features/workspace/presentation/bloc/workspace_bloc.dart';

/// Đăng xuất thủ công, không để mất các thay đổi ngoại tuyến chưa gửi.
///
/// - Không còn phiếu chờ: đăng xuất ngay.
/// - Còn phiếu: thử đẩy lên server trước; thành công thì đăng xuất bình thường.
/// - Đẩy thất bại: hỏi người dùng giữ lại (gửi tiếp khi đăng nhập lại) hay xoá.
Future<void> confirmAndLogout(BuildContext context) async {
  final authBloc = context.read<AuthBloc>();
  final workspaceBloc = context.read<WorkspaceBloc?>();

  final pending = await workspaceBloc?.pendingMutationCount() ?? 0;
  if (pending == 0) {
    authBloc.add(const AuthLogoutEvent());
    return;
  }

  if (!context.mounted) return;
  LoadingScreen.show(context);
  await workspaceBloc!.flushPendingMutations();
  final remaining = await workspaceBloc.pendingMutationCount();

  if (!context.mounted) return;
  LoadingScreen.hide(context);

  if (remaining == 0) {
    authBloc.add(const AuthLogoutEvent());
    return;
  }

  if (!context.mounted) return;
  final keep = await AppConfirmDialog.show(
    context,
    title: t('logoutPendingTitle'),
    message: t('logoutPendingMessage', {'count': '$remaining'}),
    cancelText: t('logoutDiscard'),
    confirmText: t('logoutKeepPending'),
    barrierDismissible: false,
  );

  if (keep == null) return;
  authBloc.add(AuthLogoutEvent(preservePendingChanges: keep));
}
