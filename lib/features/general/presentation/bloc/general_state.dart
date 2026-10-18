part of 'general_bloc.dart';

@immutable
sealed class GeneralState {
  const GeneralState();
}

final class GeneralInitial extends GeneralState {
  const GeneralInitial();
}

final class GeneralLoaded extends GeneralState {
  final List<ProvinceModel> provinces;
  final List<WardModel> wards;
  final bool isLoadingProvinces;
  final bool isLoadingWards;
  final String? error;

  const GeneralLoaded({
    this.provinces = const [],
    this.wards = const [],
    this.isLoadingProvinces = false,
    this.isLoadingWards = false,
    this.error,
  });

  GeneralLoaded copyWith({
    List<ProvinceModel>? provinces,
    List<WardModel>? wards,
    bool? isLoadingProvinces,
    bool? isLoadingWards,
    String? error,
  }) {
    return GeneralLoaded(
      provinces: provinces ?? this.provinces,
      wards: wards ?? this.wards,
      isLoadingProvinces: isLoadingProvinces ?? this.isLoadingProvinces,
      isLoadingWards: isLoadingWards ?? this.isLoadingWards,
      error: error,
    );
  }
}

final class GeneralFailure extends GeneralState {
  final String message;

  const GeneralFailure(this.message);
}
