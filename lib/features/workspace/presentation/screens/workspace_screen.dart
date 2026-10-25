import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:roomee/core/configs/app_theme.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/router/app_router.dart';
import 'package:roomee/features/workspace/presentation/bloc/workspace_bloc.dart';
import 'package:roomee/features/workspace/presentation/screens/list_workspace_screen.dart';

class WorkspaceScreen extends StatelessWidget {
  const WorkspaceScreen({super.key});

  Future<void> _openCreateWorkspace(BuildContext context) async {
    final result = await context.push(AppRoutes.createWorkspace);
    if (result == true && context.mounted) {
      context.read<WorkspaceBloc>().add(const WorkspaceLoadEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListWorkspaceScreen(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: DefaultColors.primary,
        foregroundColor: DefaultColors.white,
        tooltip: t('createWorkspace'),
        onPressed: () => _openCreateWorkspace(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
