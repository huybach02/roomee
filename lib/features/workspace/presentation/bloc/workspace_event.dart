part of 'workspace_bloc.dart';

@immutable
abstract class WorkspaceEvent {
  const WorkspaceEvent();
}

class WorkspaceLoadEvent extends WorkspaceEvent {
  final Map<String, dynamic>? queryParameters;

  const WorkspaceLoadEvent({this.queryParameters});
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
