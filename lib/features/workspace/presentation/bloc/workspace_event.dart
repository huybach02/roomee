part of 'workspace_bloc.dart';

@immutable
abstract class WorkspaceEvent {
  const WorkspaceEvent();
}

class WorkspaceLoadEvent extends WorkspaceEvent {
  final Map<String, dynamic>? queryParameters;

  const WorkspaceLoadEvent({this.queryParameters});
}

class WorkspaceLoadMoreEvent extends WorkspaceEvent {
  final Map<String, dynamic>? queryParameters;

  const WorkspaceLoadMoreEvent({this.queryParameters});
}

class WorkspaceCreateEvent extends WorkspaceEvent {
  final Map<String, dynamic> data;

  const WorkspaceCreateEvent(this.data);
}

class WorkspaceUpdateEvent extends WorkspaceEvent {
  final int id;
  final Map<String, dynamic> data;

  const WorkspaceUpdateEvent(this.id, this.data);
}

class WorkspaceDeleteEvent extends WorkspaceEvent {
  final int id;

  const WorkspaceDeleteEvent(this.id);
}

class WorkspaceToggleStatusEvent extends WorkspaceEvent {
  final int id;
  final int status;

  const WorkspaceToggleStatusEvent({required this.id, required this.status});
}
