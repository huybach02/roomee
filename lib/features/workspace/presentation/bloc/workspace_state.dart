part of 'workspace_bloc.dart';

@immutable
abstract class WorkspaceState {
  const WorkspaceState();
}

class WorkspaceInitial extends WorkspaceState {
  const WorkspaceInitial();
}

class WorkspaceLoading extends WorkspaceState {
  const WorkspaceLoading();
}

class WorkspaceLoaded extends WorkspaceState {
  final List<WorkspaceModel> workspaces;

  const WorkspaceLoaded({this.workspaces = const []});
}

class WorkspaceFailure extends WorkspaceState {
  final String message;

  const WorkspaceFailure(this.message);
}

class WorkspaceCreateSuccess extends WorkspaceState {
  final WorkspaceModel workspace;

  const WorkspaceCreateSuccess(this.workspace);
}

class WorkspaceUpdateSuccess extends WorkspaceState {
  final WorkspaceModel workspace;

  const WorkspaceUpdateSuccess(this.workspace);
}

class WorkspaceDeleteSuccess extends WorkspaceState {
  final int id;

  const WorkspaceDeleteSuccess(this.id);
}
