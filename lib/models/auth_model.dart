// --- 登入 ---
class LoginRequest {
  // 'account' 在 Flutter 端將持有從使用者輸入中提取的學號部分
  final String account; 
  final String password;

  LoginRequest({required this.account, required this.password});

  Map<String, dynamic> toJson() => {
        // 後端期望 'account' 作為學號進行登入
        'account': account, 
        'password': password,
      };
}

class LoginResponse {
  final bool success;
  final String? token;
  // 'account' 從後端回應中接收，代表使用者的學號
  final String? account; 
  final String? message;

  LoginResponse({
    required this.success,
    this.token,
    this.account,
    this.message,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] as bool? ?? false,
      token: json['token'] as String?,
      // 後端 login_route 回應的是 'account' (學號)
      account: json['account'] as String?, 
      message: json['message'] as String?,
    );
  }
}

// --- 註冊 ---
class RegisterRequest {
  final String password;
  final String email;    // 完整的學校 Email (例如: b1234567@mail.ntust.edu.tw)
  final String fullName; // 使用者全名

  RegisterRequest({
    required this.password,
    required this.email,
    required this.fullName,
  });

  Map<String, dynamic> toJson() => {
        'password': password,
        'email': email,
        'full_name': fullName, // 與 Flask 後端期望的 'full_name' 一致
      };
}

class RegisterResponse {
  final bool success;
  final String message;
  // 'account' 從後端回應，代表已註冊的學號 (從 Email 提取)
  final String? account; 

  RegisterResponse({
    required this.success,
    required this.message,
    this.account,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '未知錯誤',
      account: json['account'] as String?, // 後端 /register 回應 'account' (學號)
    );
  }
}

// --- 請求 OTP ---
class RequestOtpRequest {
  final String email; // 完整的學校 Email

  RequestOtpRequest({required this.email});

  Map<String, dynamic> toJson() => {
        'email': email,
      };
}

class RequestOtpResponse {
  final bool success;
  final String message;

  RequestOtpResponse({required this.success, required this.message});

  factory RequestOtpResponse.fromJson(Map<String, dynamic> json) {
    return RequestOtpResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '未知錯誤',
    );
  }
}

// --- 驗證 OTP ---
class VerifyOtpRequest {
  final String email; // 完整的學校 Email
  final String otp;

  VerifyOtpRequest({required this.email, required this.otp});

  Map<String, dynamic> toJson() => {
        'email': email,
        'otp': otp,
      };
}

class VerifyOtpResponse {
  final bool success;
  final String message;

  VerifyOtpResponse({required this.success, required this.message});

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '未知錯誤',
    );
  }
}

// --- 獲取個人資料回應模型 ---
class UserProfile {
  final String fullName; // 使用者全名
  final String email;    // 使用者 Email (完整 Email, 例如: b1234567@mail.ntust.edu.tw)
  final String account;  // 使用者學號 (例如: b1234567)

  UserProfile({
    required this.fullName,
    required this.email,
    required this.account,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      account: json['account'] as String? ?? '', // 後端 /profile 回應 'account' (學號)
    );
  }
}

class GetProfileResponse {
  final bool success;
  final UserProfile? profile;
  final String? message;

  GetProfileResponse({required this.success, this.profile, this.message});

  factory GetProfileResponse.fromJson(Map<String, dynamic> json) {
    return GetProfileResponse(
      success: json['success'] as bool? ?? false,
      profile: json['profile'] != null
          ? UserProfile.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
      message: json['message'] as String?,
    );
  }
}

// --- 更新個人資料請求模型 ---
class UpdateProfileRequest {
  final String fullName;

  UpdateProfileRequest({
    required this.fullName,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {'full_name': fullName};
    return data;
  }
}

// --- 更新個人資料回應模型 ---
class UpdateProfileResponse {
  final bool success;
  final String message;
  final String? updatedFullName;

  UpdateProfileResponse({
    required this.success,
    required this.message,
    this.updatedFullName,
  });

  factory UpdateProfileResponse.fromJson(Map<String, dynamic> json) {
    return UpdateProfileResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '未知錯誤',
      updatedFullName: json['updated_full_name'] as String?,
    );
  }
}

// --- 更改密碼請求模型 ---
class ChangePasswordRequest {
  final String currentPassword;
  final String newPassword;

  ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
        'current_password': currentPassword,
        'new_password': newPassword,
      };
}

// --- 更改密碼回應模型 ---
class ChangePasswordResponse {
  final bool success;
  final String message;

  ChangePasswordResponse({required this.success, required this.message});

  factory ChangePasswordResponse.fromJson(Map<String, dynamic> json) {
    return ChangePasswordResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '未知錯誤',
    );
  }
}