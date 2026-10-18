import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/models/models.dart';
import 'package:roomee/core/network/api_exceptions.dart';
import 'package:roomee/features/general/data/general_repository.dart';
import 'package:roomee/features/general/presentation/bloc/general_bloc.dart';

class _FakeGeneralRepository implements IGeneralRepository {
  int provincesCallCount = 0;
  int wardsCallCount = 0;
  ApiException? errorToThrow;

  @override
  Future<List<ProvinceModel>> getProvinces() async {
    provincesCallCount++;
    if (errorToThrow != null) throw errorToThrow!;
    return const [
      ProvinceModel(id: 1, code: 79, fullName: 'TP HCM', codeName: 'hcm'),
    ];
  }

  @override
  Future<List<WardModel>> getWardsByProvince(int provinceId) async {
    wardsCallCount++;
    if (errorToThrow != null) throw errorToThrow!;
    return const [
      WardModel(
        id: 10,
        code: 1,
        provinceId: 1,
        fullName: 'Phường 1',
        codeName: 'p1',
      ),
    ];
  }
}

void main() {
  late _FakeGeneralRepository fakeRepo;
  late GeneralBloc generalBloc;

  setUp(() {
    fakeRepo = _FakeGeneralRepository();
    generalBloc = GeneralBloc(repository: fakeRepo);
  });

  tearDown(() {
    generalBloc.close();
  });

  test('initial state is GeneralInitial', () {
    expect(generalBloc.state, isA<GeneralInitial>());
  });

  test('loads provinces and caches them (second request is a no-op)', () async {
    expectLater(
      generalBloc.stream,
      emitsInOrder([
        isA<GeneralLoaded>().having(
          (s) => s.isLoadingProvinces,
          'isLoadingProvinces',
          true,
        ),
        isA<GeneralLoaded>().having((s) => s.provinces, 'provinces', hasLength(1)),
      ]),
    );

    generalBloc.add(const GeneralProvincesLoadEvent());
    await Future<void>.delayed(const Duration(milliseconds: 10));

    generalBloc.add(const GeneralProvincesLoadEvent());
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(fakeRepo.provincesCallCount, 1);
  });

  test('loads wards for the selected province', () async {
    generalBloc.add(const GeneralProvincesLoadEvent());
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expectLater(
      generalBloc.stream,
      emitsInOrder([
        isA<GeneralLoaded>().having(
          (s) => s.isLoadingWards,
          'isLoadingWards',
          true,
        ),
        isA<GeneralLoaded>().having((s) => s.wards, 'wards', hasLength(1)),
      ]),
    );

    generalBloc.add(const GeneralWardsLoadEvent(1));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(fakeRepo.wardsCallCount, 1);
  });

  test('emits GeneralFailure when provinces load fails', () async {
    fakeRepo.errorToThrow = const NoInternetException();

    expectLater(
      generalBloc.stream,
      emitsInOrder([
        isA<GeneralLoaded>(),
        isA<GeneralFailure>(),
      ]),
    );

    generalBloc.add(const GeneralProvincesLoadEvent());
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(generalBloc.state, isA<GeneralFailure>());
  });

  test('keeps provinces and sets error when wards load fails', () async {
    generalBloc.add(const GeneralProvincesLoadEvent());
    await Future<void>.delayed(const Duration(milliseconds: 10));

    fakeRepo.errorToThrow = const NoInternetException();
    generalBloc.add(const GeneralWardsLoadEvent(1));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final state = generalBloc.state;
    expect(state, isA<GeneralLoaded>());
    expect((state as GeneralLoaded).provinces, hasLength(1));
    expect(state.error, isNotEmpty);
  });
}
