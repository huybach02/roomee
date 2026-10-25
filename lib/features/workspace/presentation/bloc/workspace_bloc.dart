import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/network/api_exceptions.dart';
import 'package:roomee/features/workspace/data/workspace_repository.dart';

part 'workspace_event.dart';
part 'workspace_state.dart';

class WorkspaceBloc extends Bloc<WorkspaceEvent, WorkspaceState> {
  final IWorkspaceRepository _workspaceRepository;

  WorkspaceBloc({IWorkspaceRepository? repository})
      : _workspaceRepository = repository ?? WorkspaceRepository(),
        super(const WorkspaceInitial()) {
    on<WorkspaceLoadEvent>(_onWorkspaceLoadRequested);
    on<WorkspaceCreateEvent>(_onWorkspaceCreateRequested);
    on<WorkspaceUpdateEvent>(_onWorkspaceUpdateRequested);
    on<WorkspaceDeleteEvent>(_onWorkspaceDeleteRequested);
  }

  Future<void> _onWorkspaceLoadRequested(
    WorkspaceLoadEvent event,
    Emitter<WorkspaceState> emit,
  ) async {
    emit(const WorkspaceLoading());
    try {
      final workspaces = await _workspaceRepository.getWorkspaces(
        queryParameters: event.queryParameters,
      );
      emit(WorkspaceLoaded(workspaces: workspaces));
    } on ApiException catch (e) {
      emit(WorkspaceFailure(e.message));
    } catch (e) {
      emit(WorkspaceFailure(e.toString()));
    }
  }

  Future<void> _onWorkspaceCreateRequested(
    WorkspaceCreateEvent event,
    Emitter<WorkspaceState> emit,
  ) async {
    emit(const WorkspaceLoading());
    try {
      final created = await _workspaceRepository.createWorkspace(event.data);
      emit(WorkspaceCreateSuccess(created));
    } on ApiException catch (e) {
      emit(WorkspaceFailure(e.message));
    } catch (e) {
      emit(WorkspaceFailure(e.toString()));
    }
  }

  Future<void> _onWorkspaceUpdateRequested(
    WorkspaceUpdateEvent event,
    Emitter<WorkspaceState> emit,
  ) async {
    emit(const WorkspaceLoading());
    try {
      final updated = await _workspaceRepository.updateWorkspace(
        event.id,
        event.data,
      );
      emit(WorkspaceUpdateSuccess(updated));
    } on ApiException catch (e) {
      emit(WorkspaceFailure(e.message));
    } catch (e) {
      emit(WorkspaceFailure(e.toString()));
    }
  }

  Future<void> _onWorkspaceDeleteRequested(
    WorkspaceDeleteEvent event,
    Emitter<WorkspaceState> emit,
  ) async {
    emit(const WorkspaceLoading());
    try {
      await _workspaceRepository.deleteWorkspace(event.id);
      emit(WorkspaceDeleteSuccess(event.id));
    } on ApiException catch (e) {
      emit(WorkspaceFailure(e.message));
    } catch (e) {
      emit(WorkspaceFailure(e.toString()));
    }
  }
}
