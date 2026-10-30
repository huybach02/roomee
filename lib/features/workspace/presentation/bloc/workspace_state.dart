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
  final int total;
  final int page;
  final int totalPages;
  final bool hasReachedMax;
  final bool isLoadingMore;

  const WorkspaceLoaded({
    this.workspaces = const [],
    this.total = 0,
    this.page = 1,
    this.totalPages = 1,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
  });

  WorkspaceLoaded copyWith({
    List<WorkspaceModel>? workspaces,
    int? total,
    int? page,
    int? totalPages,
    bool? hasReachedMax,
    bool? isLoadingMore,
  }) {
    return WorkspaceLoaded(
      workspaces: workspaces ?? this.workspaces,
      total: total ?? this.total,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
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
  final String id;

  const WorkspaceDeleteSuccess(this.id);
}
