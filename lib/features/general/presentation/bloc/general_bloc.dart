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

    final currentWards = current is GeneralLoaded
        ? current.wards
        : const <WardModel>[];
    final currentIsLoadingWards = current is GeneralLoaded
        ? current.isLoadingWards
        : false;

    emit(
      GeneralLoaded(
        provinces: const [],
        wards: currentWards,
        isLoadingProvinces: true,
        isLoadingWards: currentIsLoadingWards,
      ),
    );

    try {
      final provinces = await _generalRepository.getProvinces();
      // Đọc state mới nhất sau khi await để không ghi đè wards
      final latest = state;
      final latestWards = latest is GeneralLoaded ? latest.wards : currentWards;
      final latestIsLoadingWards = latest is GeneralLoaded
          ? latest.isLoadingWards
          : false;

      emit(
        GeneralLoaded(
          provinces: provinces,
          wards: latestWards,
          isLoadingProvinces: false,
          isLoadingWards: latestIsLoadingWards,
        ),
      );
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
    final currentProvinces = current is GeneralLoaded
        ? current.provinces
        : const <ProvinceModel>[];
    final currentIsLoadingProvinces = current is GeneralLoaded
        ? current.isLoadingProvinces
        : false;

    emit(
      GeneralLoaded(
        provinces: currentProvinces,
        wards: const [],
        isLoadingProvinces: currentIsLoadingProvinces,
        isLoadingWards: true,
      ),
    );

    try {
      final wards = await _generalRepository.getWardsByProvince(
        event.provinceId,
      );
      // Đọc state mới nhất sau khi await để không ghi đè provinces vừa load
      final latest = state;
      final latestProvinces = latest is GeneralLoaded
          ? latest.provinces
          : currentProvinces;
      final latestIsLoadingProvinces = latest is GeneralLoaded
          ? latest.isLoadingProvinces
          : false;

      emit(
        GeneralLoaded(
          provinces: latestProvinces,
          wards: wards,
          isLoadingProvinces: latestIsLoadingProvinces,
          isLoadingWards: false,
        ),
      );
    } on ApiException catch (e) {
      final latest = state;
      final latestProvinces = latest is GeneralLoaded
          ? latest.provinces
          : currentProvinces;
      emit(GeneralLoaded(provinces: latestProvinces, error: e.message));
    } catch (e) {
      final latest = state;
      final latestProvinces = latest is GeneralLoaded
          ? latest.provinces
          : currentProvinces;
      emit(GeneralLoaded(provinces: latestProvinces, error: e.toString()));
    }
  }
}
