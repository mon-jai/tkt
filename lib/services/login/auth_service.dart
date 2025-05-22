import 'dart:convert'; // 已在上方 auth_model.dart 區域導入
import 'dart:async'; // 已在上方 auth_model.dart 區域導入
import 'package:flutter/foundation.dart'; // 已在上方 auth_model.dart 區域導入
import 'package:http/http.dart' as http; // 已在上方 auth_model.dart 區域導入
import 'package:shared_preferences/shared_preferences.dart'; // 已在上方 auth_model.dart 區域導入
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // 已在上方 auth_model.dart 區域導入
import 'package:jwt_decoder/jwt_decoder.dart'; // 已在上方 auth_model.dart 區域導入
import '../../models/auth_model.dart'; // 假設路徑

// API 基礎 URL (從您提供的 AuthService 複製)
const String _apiBaseUrl = "http://218.161.51.17:5001"; 

// SharedPreferences 和 SecureStorage 的鍵名 (從您提供的 AuthService 複製)
const String _authTokenKey = 'auth_token';
const String _userAccountKey = 'user_account'; // 這將儲存學號
const String _isLoggedInKey = 'is_logged_in';

// --- API 結果封裝類 (從您提供的 AuthService 複製) ---
abstract class ApiResult<T> {
  const ApiResult();
}

class Success<T> extends ApiResult<T> {
  final T data;
  const Success(this.data);
}

class Error<T> extends ApiResult<T> {
  final String message;
  final int? statusCode;
  const Error(this.message, {this.statusCode});
}

class ApiException<T> extends ApiResult<T> {
  final Exception exception;
  const ApiException(this.exception);
}
// --- API 結果封裝類結束 ---

class AuthService with ChangeNotifier {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final http.Client _client;

  String? _token;
  String? _userAccount; // 儲存學號 (例如 "b1234567")
  bool _isLoggedIn = false;
  bool _isLoading = false;
  UserProfile? _userProfile; // 新增: 用於儲存完整的 UserProfile

  AuthService({http.Client? client}) : _client = client ?? http.Client() {
    _loadUserSession();
  }

  String? get token => _token;
  String? get userAccount => _userAccount; // 代表學號
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  UserProfile? get userProfile => _userProfile; // 提供 UserProfile 的 getter

  Future<void> _saveUserSession(String token, String account) async { // account 參數是學號
    await _secureStorage.write(key: _authTokenKey, value: token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userAccountKey, account); // 儲存學號
    await prefs.setBool(_isLoggedInKey, true);
    _token = token;
    _userAccount = account; // 設定學號
    _isLoggedIn = true;
    // 登入成功後，立即嘗試獲取完整的 UserProfile
    // 這樣 UI 可以立即反應，而不是等待下一次 getProfile 調用
    final profileResult = await getProfile();
    if (profileResult is Success<GetProfileResponse>) {
        _userProfile = profileResult.data.profile;
    } else {
        // 如果獲取 profile 失敗，至少保留學號和 token
        debugPrint("AuthService: Failed to fetch profile immediately after login, but session is saved.");
    }
    notifyListeners();
    debugPrint("AuthService: Session saved. Token: $token, Account (學號): $account, Profile fetched: ${profileResult is Success}");
  }

  Future<void> _loadUserSession() async {
    _isLoading = true;
    notifyListeners();

    _token = await _secureStorage.read(key: _authTokenKey);
    final prefs = await SharedPreferences.getInstance();
    _userAccount = prefs.getString(_userAccountKey); // 載入學號

    if (_token != null) {
      try {
        if (JwtDecoder.isExpired(_token!)) {
          debugPrint("AuthService: Token expired, clearing session.");
          await clearUserSession();
        } else {
          _isLoggedIn = true;
          // 嘗試獲取用戶資料以填充 _userProfile
          final profileResult = await getProfile();
          if (profileResult is Success<GetProfileResponse>) {
            _userProfile = profileResult.data.profile;
          } else {
            debugPrint("AuthService: Token valid but failed to fetch profile on load. User Account: $_userAccount");
          }
          debugPrint("AuthService: Session loaded. Token found, User Account (學號): $_userAccount, Profile loaded: ${profileResult is Success}");
        }
      } catch (e) {
        debugPrint("AuthService: Error decoding/validating token during load: $e. Clearing session.");
        await clearUserSession();
      }
    } else {
      _isLoggedIn = false;
      _userProfile = null;
      debugPrint("AuthService: No token found during session load.");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> clearUserSession() async {
    await _secureStorage.delete(key: _authTokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userAccountKey);
    await prefs.remove(_isLoggedInKey);
    _token = null;
    _userAccount = null;
    _isLoggedIn = false;
    _userProfile = null; // 清除 UserProfile
    notifyListeners();
    debugPrint("AuthService: User session cleared.");
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final currentToken = _token ?? await _secureStorage.read(key: _authTokenKey);
    if (currentToken == null) {
      debugPrint("AuthService: Attempted to get auth headers but token is null.");
      return {'Content-Type': 'application/json; charset=UTF-8'};
    }
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $currentToken',
    };
  }

  Future<ApiResult<R>> _handleApiCall<R>({
    required Future<http.Response> Function() apiCall,
    required R Function(Map<String, dynamic> json) fromJson,
    required String actionName,
  }) async {
    try {
      final response = await apiCall().timeout(const Duration(seconds: 15));
      debugPrint('AuthService ($actionName): Response status: ${response.statusCode}');
      debugPrint('AuthService ($actionName): Response body: ${response.body}');
      
      if (response.body.isEmpty && (response.statusCode < 200 || response.statusCode >= 300)) {
          return Error('$actionName 失敗 (HTTP ${response.statusCode} - 無回應內容)', statusCode: response.statusCode);
      }
      if (response.body.isEmpty && response.statusCode >=200 && response.statusCode <300){
          // 假設對於某些成功的請求 (例如沒有內容的204)，fromJson 可能不需要 map
          // 但我們的模型都有 fromJson(Map)，所以這裡假設成功時總是有 JSON body
          // 如果您的 API 對於某些成功請求不返回 JSON body，需要調整此處邏輯
          // 例如，如果 fromJson 可以處理 null map，或者有一個不需要 map 的成功構造函數
          try {
             return Success(fromJson({} as Map<String,dynamic>)); // 嘗試用空 map 構造，可能失敗
          } catch (e) {
             return Error('$actionName 成功但回應為空 (HTTP ${response.statusCode})', statusCode: response.statusCode);
          }
      }

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // 檢查 'success' 欄位 (如果存在)
        if (responseData.containsKey('success') && responseData['success'] != true) {
          return Error(responseData['message'] as String? ?? '$actionName 失敗 (來自伺服器)', statusCode: response.statusCode);
        }
        // 如果沒有 'success' 欄位但狀態碼是 2xx，也視為成功 (例如 getProfile)
        return Success(fromJson(responseData));
      } else {
        // 處理 HTTP 錯誤狀態碼
        if (response.statusCode == 401) { // 未授權，可能是 token 過期
            await clearUserSession(); // 清除本地 session
            debugPrint("AuthService ($actionName): Unauthorized (401). Session cleared.");
        }
        return Error(responseData['message'] as String? ?? '$actionName 失敗 (HTTP ${response.statusCode})', statusCode: response.statusCode);
      }
    } on TimeoutException catch (e, s) {
      debugPrint('AuthService ($actionName): Timeout error: $e\n$s');
      return Error('請求逾時，請檢查您的網路連線。');
    } on http.ClientException catch (e, s) {
      debugPrint('AuthService ($actionName): Client/Network error: $e\n$s');
      return Error('網路連線錯誤，請稍後再試: ${e.message}');
    } catch (e, s) { // 包括 JsonDecodeException
      debugPrint('AuthService ($actionName): General error / JSON decode error: $e\n$s');
      return ApiException(e is Exception ? e : Exception(e.toString()));
    }
  }

  Future<ApiResult<LoginResponse>> login(LoginRequest request) async {
    final result = await _handleApiCall<LoginResponse>(
      apiCall: () => _client.post(
        Uri.parse('$_apiBaseUrl/auth/login'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(request.toJson()),
      ),
      fromJson: (json) => LoginResponse.fromJson(json),
      actionName: 'Login',
    );
    if (result is Success<LoginResponse>) {
      final loginResponse = result.data;
      // 後端 LoginResponse 中的 'account' 欄位是學號
      if (loginResponse.success && loginResponse.token != null && loginResponse.account != null) {
        await _saveUserSession(loginResponse.token!, loginResponse.account!);
      }
    }
    return result;
  }

  Future<ApiResult<RequestOtpResponse>> requestOtp(RequestOtpRequest request) async {
    return _handleApiCall<RequestOtpResponse>(
      apiCall: () => _client.post(
        Uri.parse('$_apiBaseUrl/auth/request-otp'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(request.toJson()),
      ),
      fromJson: (json) => RequestOtpResponse.fromJson(json),
      actionName: 'RequestOTP',
    );
  }

  Future<ApiResult<VerifyOtpResponse>> verifyOtp(VerifyOtpRequest request) async {
    return _handleApiCall<VerifyOtpResponse>(
      apiCall: () => _client.post(
        Uri.parse('$_apiBaseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(request.toJson()),
      ),
      fromJson: (json) => VerifyOtpResponse.fromJson(json),
      actionName: 'VerifyOTP',
    );
  }

  Future<ApiResult<RegisterResponse>> register(RegisterRequest request) async {
    return _handleApiCall<RegisterResponse>(
      apiCall: () => _client.post(
        Uri.parse('$_apiBaseUrl/auth/register'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(request.toJson()),
      ),
      fromJson: (json) => RegisterResponse.fromJson(json),
      actionName: 'Register',
    );
  }

  Future<ApiResult<GetProfileResponse>> getProfile() async {
    if (!isLoggedIn || _token == null) { 
      debugPrint("AuthService (GetProfile): Not logged in or token is null. Clearing session if necessary.");
      // 如果 token 為 null 但 isLoggedIn 為 true，這是一個不一致的狀態，清除 session
      if (_token == null && isLoggedIn) await clearUserSession();
      return Error("使用者未登入或認證無效", statusCode: 401);
    }
    final authHeaders = await _getAuthHeaders();
    if (!authHeaders.containsKey('Authorization')) { 
        await clearUserSession(); // 如果無法獲取有效的 Auth Header (例如 token 突然變 null)
        return Error("無法獲取認證 Token，請重新登入", statusCode: 401);
    }

    final result = await _handleApiCall<GetProfileResponse>(
      apiCall: () => _client.get(
        Uri.parse('$_apiBaseUrl/auth/profile'),
        headers: authHeaders,
      ),
      fromJson: (json) => GetProfileResponse.fromJson(json),
      actionName: 'GetProfile',
    );

    if (result is Success<GetProfileResponse>) {
        if (result.data.success && result.data.profile != null) {
            _userProfile = result.data.profile; // 更新 AuthService 中的 UserProfile
            notifyListeners();
        } else if (!result.data.success) {
            // 如果 API 說 success:false，但 HTTP 200，這可能是一個業務邏輯錯誤
            debugPrint("AuthService (GetProfile): API reported success:false. Message: ${result.data.message}");
        }
    } else if (result is Error<GetProfileResponse> && result.statusCode == 401) {
        // 如果 getProfile 返回 401，則 token 可能已過期
        await clearUserSession();
    }
    return result;
  }

  Future<ApiResult<UpdateProfileResponse>> updateProfile(UpdateProfileRequest request) async {
    if (!isLoggedIn || _token == null) {
      if (_token == null && isLoggedIn) await clearUserSession();
      return Error("使用者未登入或認證無效", statusCode: 401);
    }
    final authHeaders = await _getAuthHeaders();
    if (!authHeaders.containsKey('Authorization')) {
        await clearUserSession();
        return Error("無法獲取認證 Token，請重新登入", statusCode: 401);
    }

    final result = await _handleApiCall<UpdateProfileResponse>(
      apiCall: () => _client.put(
        Uri.parse('$_apiBaseUrl/auth/profile'),
        headers: authHeaders,
        body: jsonEncode(request.toJson()),
      ),
      fromJson: (json) => UpdateProfileResponse.fromJson(json),
      actionName: 'UpdateProfile',
    );
     if (result is Success<UpdateProfileResponse>) {
        if (result.data.success) {
            // 更新成功後，重新獲取 profile 以確保 _userProfile 是最新的
            await getProfile(); 
        }
    } else if (result is Error<UpdateProfileResponse> && result.statusCode == 401) {
        await clearUserSession();
    }
    return result;
  }

  Future<ApiResult<ChangePasswordResponse>> changePassword(ChangePasswordRequest request) async {
    if (!isLoggedIn || _token == null) {
      if (_token == null && isLoggedIn) await clearUserSession();
      return Error("使用者未登入或認證無效", statusCode: 401);
    }
    final authHeaders = await _getAuthHeaders();
    if (!authHeaders.containsKey('Authorization')) {
        await clearUserSession();
        return Error("無法獲取認證 Token，請重新登入", statusCode: 401);
    }

    final result = await _handleApiCall<ChangePasswordResponse>(
      apiCall: () => _client.post(
        Uri.parse('$_apiBaseUrl/auth/change-password'),
        headers: authHeaders,
        body: jsonEncode(request.toJson()),
      ),
      fromJson: (json) => ChangePasswordResponse.fromJson(json),
      actionName: 'ChangePassword',
    );
    if (result is Error<ChangePasswordResponse> && result.statusCode == 401) {
        await clearUserSession(); // 如果密碼更改因認證失敗 (例如舊密碼錯誤導致的401)，也可能需要重新登入
    }
    return result;
  }

  Future<void> logout() async {
    // 可選：通知後端 token 失效 (如果後端有 /logout 端點)
    // if (_token != null) {
    //   try {
    //     final authHeaders = await _getAuthHeaders();
    //     if (authHeaders.containsKey('Authorization')) {
    //        await _client.post(Uri.parse('$_apiBaseUrl/auth/logout'), headers: authHeaders);
    //        debugPrint("AuthService: Logout signal sent to backend.");
    //     }
    //   } catch (e) {
    //     debugPrint("AuthService: Error sending logout signal to backend: $e");
    //   }
    // }
    await clearUserSession(); // 清除本地 session
    debugPrint("AuthService: User logged out.");
  }
}