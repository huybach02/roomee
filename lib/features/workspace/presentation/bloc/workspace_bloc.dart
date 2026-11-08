import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/network/api_exceptions.dart';
import 'package:roomee/core/offline/query/offline_page.dart';
import 'package:roomee/features/workspace/data/workspace_repository.dart';
import 'package:roomee/utils/constanst.dart';

part 'workspace_event.dart';
part 'workspace_state.dart';

class WorkspaceBloc extends Bloc<WorkspaceEvent, WorkspaceState> {
  final IWorkspaceRepository _workspaceRepository;

  ValueListenable<bool>? get isSyncingNotifier =>
      _workspaceRepository.isSyncingNotifier;

  ValueListenable<bool?>? get syncSuccessNotifier =>
      _workspaceRepository.syncSuccessNotifier;

  WorkspaceBloc({IWorkspaceRepository? repository})
    : _workspaceRepository = repository ?? WorkspaceRepository(),
      super(const WorkspaceInitial()) {
    on<WorkspaceLoadEvent>(_onWorkspaceLoadRequested);
    on<WorkspaceLoadMoreEvent>(_onWorkspaceLoadMoreRequested);
    on<WorkspaceCreateEvent>(_onWorkspaceCreateRequested);
    on<WorkspaceUpdateEvent>(_onWorkspaceUpdateRequested);
    on<WorkspaceDeleteEvent>(_onWorkspaceDeleteRequested);
    on<WorkspaceToggleStatusEvent>(_onWorkspaceToggleStatusRequested);
    on<WorkspaceResetEvent>(_onWorkspaceResetRequested);
  }

  void _onWorkspaceResetRequested(
    WorkspaceResetEvent event,
    Emitter<WorkspaceState> emit,
  ) {
    emit(const WorkspaceInitial());
  }

  Future<void> _onWorkspaceLoadRequested(
    WorkspaceLoadEvent event,
    Emitter<WorkspaceState> emit,
  ) async {
    final currentState = state;
    if (currentState is WorkspaceLoaded) {
      emit(currentState.copyWith(isRefreshing: true, errorMessage: null));
    } else {
      emit(const WorkspaceLoading());
    }

    try {
      final params = Map<String, dynamic>.from(event.queryParameters ?? {});
      params['page'] = params['page'] ?? defaultPage;
      params['limit'] = params['limit'] ?? defaultLimit;

      final pagination = await _workspaceRepository.getWorkspaces(
        queryParameters: params,
      );
      emit(WorkspaceLoaded(
        workspaces: pagination.data,
        total: pagination.total,
        page: pagination.page,
        totalPages: pagination.totalPages,
        hasReachedMax: pagination.hasReachedMax,
        isOffline: pagination.source == DataSourceKind.local,
        cacheIsComplete: pagination.isComplete,
        lastFetchedAt: pagination.lastFetchedAt,
        isLoadingMore: false,
        isRefreshing: false,
        errorMessage: null,
      ));
    } on ApiException catch (e) {
      if (state is WorkspaceLoaded) {
        emit((state as WorkspaceLoaded).copyWith(
          isRefreshing: false,
          errorMessage: e.message,
        ));
      } else {
        emit(WorkspaceFailure(e.message));
      }
    } catch (e) {
      if (state is WorkspaceLoaded) {
        emit((state as WorkspaceLoaded).copyWith(
          isRefreshing: false,
          errorMessage: e.toString(),
        ));
      } else {
        emit(WorkspaceFailure(e.toString()));
      }
    } finally {
      event.completer?.complete();
    }
  }

  Future<void> _onWorkspaceLoadMoreRequested(
    WorkspaceLoadMoreEvent event,
    Emitter<WorkspaceState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkspaceLoaded ||
        currentState.hasReachedMax ||
        currentState.isLoadingMore ||
        currentState.isRefreshing) {
      return;
    }

    final loadingMoreState = currentState.copyWith(
      isLoadingMore: true,
      errorMessage: null,
    );
    emit(loadingMoreState);
    try {
      final params = Map<String, dynamic>.from(event.queryParameters ?? {});
      params['page'] = currentState.page + 1;
      params['limit'] = params['limit'] ?? defaultLimit;

      final pagination = await _workspaceRepository.getWorkspaces(
        queryParameters: params,
      );

      if (!identical(state, loadingMoreState)) return;

      // Source Guard: Không nối dữ liệu local vào danh sách online nếu rớt mạng khi load more
      if (!currentState.isOffline &&
          pagination.source == DataSourceKind.local) {
        emit(currentState.copyWith(
          isLoadingMore: false,
          errorMessage: t('errors.cannotLoadMoreOffline'),
        ));
        return;
      }

      final updatedList = List<WorkspaceModel>.from(currentState.workspaces)
        ..addAll(pagination.data);

      emit(currentState.copyWith(
        workspaces: updatedList,
        total: pagination.total,
        page: pagination.page,
        totalPages: pagination.totalPages,
        hasReachedMax: pagination.hasReachedMax,
        isOffline: pagination.source == DataSourceKind.local,
        cacheIsComplete: pagination.isComplete,
        lastFetchedAt: pagination.lastFetchedAt ?? currentState.lastFetchedAt,
        isLoadingMore: false,
        errorMessage: null,
      ));
    } catch (_) {
      if (identical(state, loadingMoreState)) {
        emit(currentState.copyWith(isLoadingMore: false));
      }
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

  Future<void> _onWorkspaceToggleStatusRequested(
    WorkspaceToggleStatusEvent event,
    Emitter<WorkspaceState> emit,
  ) async {
    if (state is! WorkspaceLoaded) return;
    final currentState = state as WorkspaceLoaded;
    final currentWorkspaces = currentState.workspaces;

    emit(
      currentState.copyWith(
        workspaces: currentWorkspaces.map((ws) {
          return ws.id == event.id ? ws.copyWith(status: event.status) : ws;
        }).toList(),
      ),
    );

    try {
      final updated = await _workspaceRepository.updateWorkspace(event.id, {
        'status': event.status,
      });
      emit(
        currentState.copyWith(
          workspaces: currentWorkspaces.map((ws) {
            return ws.id == event.id ? updated : ws;
          }).toList(),
        ),
      );
    } on ApiException catch (e) {
      emit(currentState);
      emit(WorkspaceFailure(e.message));
    } catch (e) {
      emit(currentState);
      emit(WorkspaceFailure(e.toString()));
    }
  }
}
