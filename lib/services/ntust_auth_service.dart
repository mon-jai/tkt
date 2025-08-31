import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:html/parser.dart' as parser;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' as io; // 用於 io.Cookie
import 'demo_service.dart';

// 定義登入狀態枚舉 (類似 NTUSTConnector 中的)
// enum NtustLoginStatus { success, fail, error } // 如果需要更細緻的狀態管理，可以啟用

class NtustAuthService with ChangeNotifier {
  // static const String _baseUrl = 'https://i.ntust.edu.tw'; // 備用，主要看登入頁
  static const String _loginUrl = 'https://stuinfosys.ntust.edu.tw/NTUSTSSOServ/SSO/Login/CourseSelection';

  // 儲存登入狀態和 cookie
  bool _isLoggedIn = false;
  String? _studentId;
  List<io.Cookie>? _cookies; // 使用 dart:io 的 Cookie
  bool _isDemoMode = false; // 演示模式狀態

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  String? get studentId => _studentId;
  List<io.Cookie>? get sessionCookies => _cookies;
  bool get isDemoMode => _isDemoMode;


  // SharedPreferences 的鍵名
  static const String _cookiesKey = 'ntust_sso_cookies_v2'; // 更新鍵名以避免與舊格式衝突
  static const String _studentIdKey = 'ntust_sso_student_id_v2';
  static const String _lastLoginTimeKey = 'ntust_sso_last_login_time_v2';

  // 建構函數：嘗試從 SharedPreferences 恢復 session
  NtustAuthService() {
    _loadSession();
  }

  // 載入已儲存的 session
  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cookiesJsonString = prefs.getString(_cookiesKey); // 儲存為 JSON 字串
      _studentId = prefs.getString(_studentIdKey);
      final lastLoginTimeString = prefs.getString(_lastLoginTimeKey);

      // 檢查是否為演示模式會話
      final isDemoSession = prefs.getBool('demo_mode_session_ntust') ?? false;
      
      if (isDemoSession && _studentId != null) {
        _isLoggedIn = true;
        _isDemoMode = true;
        debugPrint("NtustAuthService: 演示模式會話已恢復. Student ID: $_studentId");
        notifyListeners();
        return;
      }
      
      if (cookiesJsonString != null && _studentId != null && lastLoginTimeString != null) {
        final lastLogin = DateTime.parse(lastLoginTimeString);
        final now = DateTime.now();
        // 考慮將 session 有效期縮短，例如 12 小時，或每次啟動時都驗證 session
        if (now.difference(lastLogin).inHours < 12) { // 假設 12 小時有效期
          // 從 JSON 字串恢復 List<io.Cookie>
          // 這裡需要一個方法將 JSON 轉回 List<io.Cookie>
          // 為了簡化，這裡假設 _saveSession 儲存的是可以直接使用的 cookie 字串，
          // 但更好的做法是儲存 cookie 的各個屬性。
          // 或者，直接使用 CookieManager 的持久化能力（如果它支持）。

          // 由於 flutter_inappwebview 的 CookieManager 主要在 WebView 實例中運作，
          // 跨 App 啟動的持久化最好是自己管理 Cookie 字串或其屬性。
          // 這裡我們假設 _saveSession 儲存了必要的 cookie 信息，
          // 並且在需要時，這些 cookie 會被用於後續的網路請求 (例如 Dio 的 CookieJar)。
          // 對於 HeadlessInAppWebView，每次登入都會重新獲取。
          // _loadSession 的主要目的是在 App 重啟後，UI 層能知道之前是否登入過。

          // 重新驗證 session 的有效性可能更可靠
          // _cookies = _parseCookiesFromString(cookiesJsonString); // 假設有此方法
          // if (await checkSessionValidityOnServer()) { // 需要一個實際請求來驗證
          //   _isLoggedIn = true;
          // } else {
          //   await _clearSession();
          // }

          // 簡化：如果本地有記錄且未過期，則認為已登入，但實際請求時仍需驗證
          _isLoggedIn = true;
          debugPrint('已從本地標記為已登入：$_studentId (實際有效性需後續請求驗證)');
          notifyListeners();
          return;
        } else {
          debugPrint('本地 Session 已過期。');
        }
      }
      await _clearSession(notify: false); // 初始載入時如果清除，可以不用立即通知
    } catch (e) {
      debugPrint('載入 session 時發生錯誤：$e');
      await _clearSession(notify: false);
    }
  }

  // 儲存 session 到 SharedPreferences
  Future<void> _saveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_cookies != null && _studentId != null) {
        // 將 List<io.Cookie> 轉換為 JSON 字串儲存
        // 這裡只儲存 name 和 value，更完整的應包含 domain, path, expires 等
        final cookiesToSave = _cookies!
            .map((c) => {'name': c.name, 'value': c.value, 'domain': c.domain, 'path': c.path})
            .toList();
        // final cookiesJsonString = jsonEncode(cookiesToSave); // 需要 import 'dart:convert';
        // 為了避免引入 dart:convert，這裡用一個簡單的格式，但 JSON 更好
        final simpleCookiesString = _cookies!.map((c) => '${c.name}=${c.value}').join('|||'); // 使用特殊分隔符

        await prefs.setString(_cookiesKey, simpleCookiesString);
        await prefs.setString(_studentIdKey, _studentId!);
        await prefs.setString(_lastLoginTimeKey, DateTime.now().toIso8601String());
        debugPrint('已儲存 session 到本地：$_studentId');
      }
    } catch (e) {
      debugPrint('儲存 session 時發生錯誤：$e');
    }
  }

  // 清除儲存的 session
  Future<void> _clearSession({bool notify = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cookiesKey);
      await prefs.remove(_studentIdKey);
      await prefs.remove(_lastLoginTimeKey);
      await prefs.remove('demo_mode_session_ntust');

      final cookieManager = CookieManager.instance();
      await cookieManager.deleteAllCookies(); // 清除 WebView 中的 Cookies

      _cookies = null;
      _studentId = null;
      _isLoggedIn = false;
      _isDemoMode = false;
      if (notify) {
        notifyListeners();
      }
      debugPrint('已清除 session (本地和 WebView)');
    } catch (e) {
      debugPrint('清除 session 時發生錯誤：$e');
    }
  }

  // 登入台科大校務系統
  Future<String> login(String studentId, String password) async {
    // 檢查是否為演示模式帳號
    if (DemoService.isDemoAccount(studentId)) {
      debugPrint("NtustAuthService: 偵測到演示模式帳號，啟用演示模式登入");
      return await _handleDemoLogin(studentId);
    }
    bool pageLoaded = false; // 用於追蹤初始頁面是否載入完成
    HeadlessInAppWebView? headlessWebView; // 移到外部以便在 finally 中 dispose

    try {
      final WebUri loginUri = WebUri(_loginUrl);
      final cookieManager = CookieManager.instance();

      await _clearSession(notify: false); // 登入前先清除舊的 session 和 cookies
      debugPrint('[LoginProcess] 開始登入，目標 URL: $loginUri');

      String? currentLoadedUrl;

      headlessWebView = HeadlessInAppWebView(
        initialUrlRequest: URLRequest(url: loginUri),
        onLoadStart: (controller, url) {
          debugPrint('[WebView] onLoadStart: $url');
          currentLoadedUrl = url?.toString();
        },
        onLoadStop: (controller, url) async {
          debugPrint('[WebView] onLoadStop: $url');
          currentLoadedUrl = url?.toString();
          // String? html = await controller.getHtml();
          // debugPrint('[WebView] HTML on stop (前500字): ${html?.substring(0, html.length > 500 ? 500 : html.length)}...');
          pageLoaded = true; // 標記頁面已載入（至少一次）
        },
        onUpdateVisitedHistory: (controller, url, androidIsReload) {
          debugPrint('[WebView] onUpdateVisitedHistory: $url, isReload: $androidIsReload');
          currentLoadedUrl = url?.toString();
        },
        onConsoleMessage: (controller, consoleMessage) {
          debugPrint('[WebView] Console: [${consoleMessage.messageLevel?.toString() ?? ''}] ${consoleMessage.message}');
        },
        onLoadError: (controller, url, code, message) {
          debugPrint('[WebView] onLoadError: $url, Code: $code, Message: $message');
          pageLoaded = true; // 即使出錯也標記為 loaded 以便跳出等待迴圈
        },
        onLoadHttpError: (controller, url, statusCode, description) {
          debugPrint('[WebView] onLoadHttpError: $url, StatusCode: $statusCode, Description: $description');
          pageLoaded = true;
        },
      );

      await headlessWebView.run();
      debugPrint('[LoginProcess] HeadlessWebView 已啟動');

      // 等待初始頁面載入完成
      int initialLoadWaitTime = 0;
      while (!pageLoaded && initialLoadWaitTime < 150) { // 最多等 15 秒
        await Future.delayed(const Duration(milliseconds: 100));
        initialLoadWaitTime++;
      }

      if (!pageLoaded) {
        throw Exception('登入頁面載入超時或失敗');
      }
      debugPrint('[LoginProcess] 初始頁面載入完成/超時，當前 URL: $currentLoadedUrl');


      // 確保當前 URL 是登入頁面才注入 JS
      if (currentLoadedUrl == null || !currentLoadedUrl!.startsWith(loginUri.toString().split('?')[0])) {
           // 有時 loginUri 可能帶有 query params，比較時忽略
        throw Exception('WebView 未停留在預期的登入頁面 ($loginUri)，而是在 $currentLoadedUrl');
      }

      debugPrint('[LoginProcess] 準備注入 JavaScript 以填寫表單...');
      // 使用您確認的元素名稱
      await headlessWebView.webViewController?.evaluateJavascript(
          source: 'document.getElementsByName("UserName")[0].value = "$studentId";');
      await headlessWebView.webViewController?.evaluateJavascript(
          source: 'document.getElementsByName("Password")[0].value = "$password";');
      debugPrint('[LoginProcess] 學號和密碼已填寫');

      pageLoaded = false; // 重置 pageLoaded 以等待點擊後的新頁面載入
      await headlessWebView.webViewController?.evaluateJavascript(
          source: 'document.getElementById("btnLogIn").click();');
      debugPrint('[LoginProcess] 登入按鈕已點擊');

      // 等待點擊後頁面反應（跳轉或原地更新）
      int afterClickWaitTime = 0;
      while (!pageLoaded && afterClickWaitTime < 150) { // 最多再等 15 秒
        await Future.delayed(const Duration(milliseconds: 100));
        afterClickWaitTime++;
      }
       debugPrint('[LoginProcess] 點擊後等待結束，當前 URL: $currentLoadedUrl');


      // 檢查登入結果
      WebUri? finalUrl = await headlessWebView.webViewController?.getUrl();
      debugPrint('[LoginProcess] 最終檢查 URL: $finalUrl');
      String? htmlContent = await headlessWebView.webViewController?.getHtml();

      if (htmlContent != null) {
        var document = parser.parse(htmlContent);
        // SSO 頁面錯誤訊息 class 可能不同，需要實際觀察
        var errorNodes = document.getElementsByClassName("validation-summary-errors"); // 這是 ASP.NET MVC 常用的
        if (errorNodes.isNotEmpty && errorNodes[0].text.trim().isNotEmpty) {
          final errorMessage = errorNodes[0].text.replaceAll(RegExp(r'\s+'), " ").trim(); // 清理空白
          debugPrint('[LoginProcess] 偵測到驗證錯誤訊息: "$errorMessage"');
          throw Exception(errorMessage);
        }

        // 嘗試從當前 finalUrl (或 loginUri 如果未跳轉) 獲取 cookies
        final Uri cookieUriToQuery = finalUrl ?? loginUri;
        List<Cookie> retrievedCookies = await cookieManager.getCookies(url: WebUri.uri(cookieUriToQuery));

        debugPrint('[LoginProcess] 從 $cookieUriToQuery 獲取到的所有 Cookies (${retrievedCookies.length} 個):');
        for (var cookie in retrievedCookies) {
          debugPrint('  Name: ${cookie.name}, Value: ${cookie.value}, Domain: ${cookie.domain}, Path: ${cookie.path}, Expires: ${cookie.expiresDate}, Secure: ${cookie.isSecure}, HttpOnly: ${cookie.isHttpOnly}');
        }

        List<io.Cookie> extractedIoCookies = [];
        bool requiredCookieFound = false;
        // SSO 系統的關鍵 Cookie 名稱可能變化，以下是一些常見的或根據之前討論的
        List<String> targetCookieNames = [
          ".ASPXAUTH", // 舊式
          "ntustjwtsecret", // JWT 相關
          "ntustsecret", // JWT 相關
          "SESSION", // 通用 Session
          "JSESSIONID", // Java 系統 Session
          "ARRAffinity", // Azure App Service
          // 實際登入後，觀察 WebView 印出的所有 Cookie，找出真正用於身份驗證的
        ];

        for (var cookie in retrievedCookies) {
          // 轉換為 dart:io.Cookie
          io.Cookie ioCookie = io.Cookie(cookie.name, cookie.value.toString())
            ..domain = cookie.domain // InAppWebView 的 Cookie domain 可能為 null
            ..path = cookie.path ?? "/"
            ..secure = cookie.isSecure ?? false
            ..httpOnly = cookie.isHttpOnly ?? false;
          if (cookie.expiresDate != null) {
            ioCookie.expires = DateTime.fromMillisecondsSinceEpoch(cookie.expiresDate!);
          }
          
          // 檢查是否為目標 Cookie
          if (targetCookieNames.any((name) => cookie.name.toLowerCase().contains(name.toLowerCase()))) {
            debugPrint('[LoginProcess] 找到目標相關 Cookie: ${cookie.name}');
            extractedIoCookies.add(ioCookie);
            requiredCookieFound = true; // 只要找到一個相關的就認為可能成功
          } else {
            // 也將非目標但看起來重要的 cookies 加入 (例如沒有特定名稱但 domain 正確的)
            if (cookie.domain != null && cookie.domain!.toLowerCase().contains('ntust.edu.tw')) {
                 debugPrint('[LoginProcess] 找到 NTUST domain 的其他 Cookie: ${cookie.name}');
                 extractedIoCookies.add(ioCookie);
            }
          }
        }
        
        // 登入成功的判斷條件可能需要調整：
        // 1. 是否跳轉到特定成功頁面？ (finalUrl 的變化)
        // 2. 是否獲取到了特定的 Session Cookie？
        // 3. HTML 內容是否不再包含登入表單？
        bool isLikelyLoggedIn = requiredCookieFound; // 簡化判斷：只要有目標 cookie
        // 更嚴謹的判斷：檢查 finalUrl 是否不再是登入頁，且 htmlContent 不再包含登入表單的關鍵字
        if (finalUrl != null && !finalUrl.toString().contains('SSO/Login')) {
             debugPrint('[LoginProcess] URL 已跳轉離開登入頁，視為登入成功跡象。');
             isLikelyLoggedIn = true; // 如果跳轉了，成功機率更高
        }


        if (isLikelyLoggedIn && extractedIoCookies.isNotEmpty) {
          _cookies = extractedIoCookies;
          _studentId = studentId;
          _isLoggedIn = true;
          await _saveSession();
          notifyListeners();
          debugPrint('[LoginProcess] 登入成功，已儲存 Session。');
          return '登入成功';
        } else {
          debugPrint('[LoginProcess] 未找到足夠的登入成功跡象或必要的 Cookies。');
          // 可以印出 HTML 內容以供分析
          // debugPrint('[LoginProcess] 當前頁面 HTML (前1000字): ${htmlContent.substring(0, htmlContent.length > 1000 ? 1000 : htmlContent.length)}...');
          throw Exception('登入失敗：未獲取到有效的 Session Cookies 或未跳轉。');
        }
      } else {
        throw Exception('登入失敗：無法獲取最終頁面的 HTML 內容。');
      }
    } catch (e) {
      debugPrint('[LoginProcess] 登入過程中發生嚴重錯誤：$e');
      await _clearSession(); // 清除任何可能不完整的 session
      rethrow; // 將錯誤向上拋出，讓 UI 層處理
    } finally {
      // 確保 HeadlessInAppWebView 被釋放
      if (headlessWebView != null) {
        await headlessWebView.dispose();
        debugPrint('[LoginProcess] HeadlessWebView 已釋放。');
      }
    }
  }

  /// 處理演示模式登入 - 不進行真實登入，直接設置狀態
  Future<String> _handleDemoLogin(String studentId) async {
    try {
      // 模擬短暫的載入時間（比真實登入快很多）
      await DemoService.simulateApiDelay(300);

      // 直接設定演示模式狀態，不進行任何網路請求
      _studentId = studentId;
      _isLoggedIn = true;
      _isDemoMode = true;
      
      // 儲存演示模式會話（僅本地狀態）
      await _saveDemoSession(studentId);
      
      notifyListeners();
      debugPrint("NtustAuthService: 演示模式已啟用，跳過真實登入流程");
      return '演示模式已啟用 - 歡迎使用台科通展示功能';
    } catch (e) {
      debugPrint("NtustAuthService: 演示模式設定失敗: $e");
      return '演示模式設定失敗: $e';
    }
  }

  /// 儲存演示模式會話 - 僅儲存本地狀態，不涉及任何網路或Cookie
  Future<void> _saveDemoSession(String studentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_studentIdKey, studentId);
      await prefs.setBool('demo_mode_session_ntust', true);
      await prefs.setString('demo_mode_message', '演示模式：所有資料均為示例');
      debugPrint("NtustAuthService: 演示模式本地狀態已儲存，無需Cookie或網路連接");
    } catch (e) {
      debugPrint("NtustAuthService: 儲存演示模式本地狀態時發生錯誤: $e");
    }
  }

  // 登出
  Future<void> logout() async {
    await _clearSession();
    debugPrint('使用者已登出。');
  }

  // 檢查 session 是否可能仍然有效 (主要基於本地標記，實際有效性需伺服器驗證)
  // 這個方法可以擴展為實際向伺服器發送一個輕量請求來驗證 cookie
  Future<bool> checkLocalSessionIsValid() async {
    if (!_isLoggedIn || _studentId == null) {
      return false;
    }
    // 可以加入更複雜的檢查，例如上次登入時間是否過期
    final prefs = await SharedPreferences.getInstance();
    final lastLoginTimeString = prefs.getString(_lastLoginTimeKey);
    if (lastLoginTimeString == null) return false;

    final lastLogin = DateTime.parse(lastLoginTimeString);
    if (DateTime.now().difference(lastLogin).inHours >= 12) { // 與 _loadSession 一致
      await _clearSession();
      return false;
    }
    return true;
  }

  // 銷毀時清理資源 (雖然 ChangeNotifier 通常由擁有它的 widget 管理生命週期)
  @override
  void dispose() {
    debugPrint('NtustAuthService disposed.');
    // 如果有其他需要清理的資源可以在這裡處理
    super.dispose();
  }
}
