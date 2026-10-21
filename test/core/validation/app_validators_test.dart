import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/localization/app_localizations.dart';
import 'package:roomee/core/validation/app_validators.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({});
    await AppLocalizations.preload();
  });

  group('ValidationConfig', () {
    test('constants have expected values', () {
      expect(ValidationConfig.emailMax, 255);
      expect(ValidationConfig.passwordMin, 8);
      expect(ValidationConfig.passwordMax, 255);
      expect(ValidationConfig.fullNameMax, 100);
      expect(ValidationConfig.bioMax, 500);
      expect(ValidationConfig.otpLength, 6);
    });
  });

  group('Validators atomic rules', () {
    test('compose runs rules sequentially and stops at first failure', () {
      final validator = Validators.compose<String>([
        Validators.required(),
        Validators.minLength(5),
      ]);

      expect(validator(null), 'Vui lòng nhập trường này');
      expect(validator('   '), 'Vui lòng nhập trường này');
      expect(validator('abc'), 'Tối thiểu 5 ký tự');
      expect(validator('abcdef'), isNull);
    });

    test('required returns error when null or whitespace', () {
      final validator = Validators.required();
      expect(validator(null), 'Vui lòng nhập trường này');
      expect(validator(''), 'Vui lòng nhập trường này');
      expect(validator('   '), 'Vui lòng nhập trường này');
      expect(validator('ok'), isNull);
    });

    test('requiredValue works with non-string values', () {
      final validator = Validators.requiredValue<int>();
      expect(validator(null), 'Vui lòng nhập trường này');
      expect(validator(42), isNull);
    });

    test('minLength validates length and interpolates {min}', () {
      final validator = Validators.minLength(6);
      expect(validator(null), isNull); // optional if empty
      expect(validator(''), isNull);
      expect(validator('12345'), 'Tối thiểu 6 ký tự');
      expect(validator('123456'), isNull);
      expect(validator('1234567'), isNull);
    });

    test('maxLength validates length and interpolates {max}', () {
      final validator = Validators.maxLength(5);
      expect(validator(null), isNull);
      expect(validator(''), isNull);
      expect(validator('12345'), isNull);
      expect(validator('123456'), 'Tối đa 5 ký tự');
    });

    test('pattern validates with regex', () {
      final validator = Validators.pattern(
        RegExp(r'^\d+$'),
        'validateErrors.invalidDigits',
      );
      expect(validator(null), isNull);
      expect(validator('123'), isNull);
      expect(validator('abc'), 'Định dạng chữ số không hợp lệ');
    });

    test('email validator checks email format', () {
      final validator = Validators.email();
      expect(validator(null), isNull);
      expect(validator('valid@test.com'), isNull);
      expect(validator('user@domain.vn'), isNull);
      expect(validator('invalid-email'), 'Email không hợp lệ');
      expect(validator('user@'), 'Email không hợp lệ');
    });

    test('vnPhone validator checks Vietnamese phone numbers', () {
      final validator = Validators.vnPhone();
      expect(validator(null), isNull);
      expect(validator('0901234567'), isNull);
      expect(validator('+84901234567'), isNull);
      expect(validator('0321234567'), isNull);
      expect(validator('0123456789'), 'Số điện thoại không hợp lệ');
      expect(validator('12345'), 'Số điện thoại không hợp lệ');
    });

    test('digits validator checks exact number of digits', () {
      final validator = Validators.digits(6);
      expect(validator(null), isNull);
      expect(validator('123456'), isNull);
      expect(validator('12345'), 'Định dạng chữ số không hợp lệ');
      expect(validator('1234567'), 'Định dạng chữ số không hợp lệ');
      expect(validator('abcdef'), 'Định dạng chữ số không hợp lệ');
    });

    test('matches validator compares with another value', () {
      String otherValue = 'secret123';
      final validator = Validators.matches(() => otherValue);

      expect(validator('secret123'), isNull);
      expect(validator('different'), 'Mật khẩu xác nhận không khớp');
    });
  });

  group('FieldRules', () {
    test('FieldRules.email validates presence, max length and format', () {
      final requiredEmail = FieldRules.email(required: true);
      expect(requiredEmail(null), 'Vui lòng nhập trường này');
      expect(requiredEmail('invalid'), 'Email không hợp lệ');
      expect(requiredEmail('user@roomee.vn'), isNull);

      final optionalEmail = FieldRules.email(required: false);
      expect(optionalEmail(null), isNull);
      expect(optionalEmail(''), isNull);
      expect(optionalEmail('user@roomee.vn'), isNull);
    });

    test('FieldRules.password validates required and min 8 characters', () {
      final validator = FieldRules.password();
      expect(validator(null), 'Vui lòng nhập trường này');
      expect(validator('1234567'), 'Mật khẩu phải có ít nhất 8 ký tự');
      expect(validator('12345678'), isNull);
    });

    test('FieldRules.loginPassword only requires non-empty value', () {
      final validator = FieldRules.loginPassword();
      expect(validator(null), 'Vui lòng nhập trường này');
      expect(validator(''), 'Vui lòng nhập trường này');
      expect(validator('123'), isNull);
    });

    test('FieldRules.confirmPassword checks against password getter', () {
      final validator = FieldRules.confirmPassword(() => 'my_password');
      expect(validator(null), 'Vui lòng nhập trường này');
      expect(validator('wrong_password'), 'Mật khẩu xác nhận không khớp');
      expect(validator('my_password'), isNull);
    });

    test('FieldRules.phone handles both required and optional', () {
      final optionalPhone = FieldRules.phone(required: false);
      expect(optionalPhone(null), isNull);
      expect(optionalPhone(''), isNull);
      expect(optionalPhone('0912345678'), isNull);
      expect(optionalPhone('invalid'), 'Số điện thoại không hợp lệ');

      final requiredPhone = FieldRules.phone(required: true);
      expect(requiredPhone(null), 'Vui lòng nhập trường này');
      expect(requiredPhone('0912345678'), isNull);
    });

    test('FieldRules.fullName requires non-empty and max 100 characters', () {
      final validator = FieldRules.fullName();
      expect(validator(null), 'Vui lòng nhập trường này');
      expect(validator('Nguyen Van A'), isNull);
      expect(validator('a' * 101), 'Tối đa 100 ký tự');
    });

    test('FieldRules.bio validates max 500 characters', () {
      final validator = FieldRules.bio();
      expect(validator(null), isNull);
      expect(validator('Some bio'), isNull);
      expect(validator('a' * 501), 'Tối đa 500 ký tự');
    });

    test('FieldRules.otp requires exactly 6 digits', () {
      final validator = FieldRules.otp();
      expect(validator(null), 'Vui lòng nhập đủ 6 chữ số mã OTP');
      expect(validator('12345'), 'Vui lòng nhập đủ 6 chữ số mã OTP');
      expect(validator('123456'), isNull);
      expect(validator('abcdef'), 'Vui lòng nhập đủ 6 chữ số mã OTP');
    });
  });
}
