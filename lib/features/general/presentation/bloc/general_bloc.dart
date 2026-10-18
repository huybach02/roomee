import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/network/api_exceptions.dart';
import 'package:roomee/features/general/data/general_repository.dart';

part 'general_event.dart';
part 'general_state.dart';

class GeneralBloc extends Bloc<GeneralEvent, GeneralState> {
  final IGeneralRepository _generalRepository;

  GeneralBloc({IGeneralRepository? repository})
    : _generalRepository = repository ?? GeneralRepository(),
      super(const GeneralInitial()) {
    on<GeneralProvincesLoadEvent>(_onProvincesLoadRequested);
    on<GeneralWardsLoadEvent>(_onWardsLoadRequested);
  }

  Future<void> _onProvincesLoadRequested(
    GeneralProvincesLoadEvent event,
    Emitter<GeneralState> emit,
  ) async {
    final current = state;
    if (current is GeneralLoaded && current.provinces.isNotEmpty) {
      return;
    }

    emit(const GeneralLoaded(isLoadingProvinces: true));

    try {
      final provinces = await _generalRepository.getProvinces();
      emit(GeneralLoaded(provinces: provinces));
    } on ApiException catch (e) {
      emit(GeneralFailure(e.message));
    } catch (e) {
      emit(GeneralFailure(e.toString()));
    }
  }

  Future<void> _onWardsLoadRequested(
    GeneralWardsLoadEvent event,
    Emitter<GeneralState> emit,
  ) async {
    final current = state;
    final provinces = current is GeneralLoaded
        ? current.provinces
        : const <ProvinceModel>[];

    emit(GeneralLoaded(provinces: provinces, isLoadingWards: true));

    try {
      final wards = await _generalRepository.getWardsByProvince(
        event.provinceId,
      );
      emit(GeneralLoaded(provinces: provinces, wards: wards));
    } on ApiException catch (e) {
      emit(GeneralLoaded(provinces: provinces, error: e.message));
    } catch (e) {
      emit(GeneralLoaded(provinces: provinces, error: e.toString()));
    }
  }
}
