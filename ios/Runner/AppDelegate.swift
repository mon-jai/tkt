import Flutter
import UIKit
import UserNotifications
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // 配置 App Group 支援
    configureAppGroup()

    // 讓 iOS 前景也能顯示通知
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func configureAppGroup() {
    let appGroupId = "group.com.example.tkt.TKTWidget" // 與 entitlements 中的 App Group ID 一致
    
    // 為 Flutter 的 shared_preferences 套件配置 App Group
    if let controller = window?.rootViewController as? FlutterViewController {
      let methodChannel = FlutterMethodChannel(name: "app_group_preferences", binaryMessenger: controller.binaryMessenger)
      
      // Widget 更新通道
      let widgetChannel = FlutterMethodChannel(name: "widget_update", binaryMessenger: controller.binaryMessenger)
      
      widgetChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
        if call.method == "reloadAllTimelines" {
          if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
            print("🔄 已觸發 Widget 更新")
            result(true)
          } else {
            print("❌ Widget 更新需要 iOS 14.0+")
            result(false)
          }
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
      
      methodChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
        guard let userDefaults = UserDefaults(suiteName: appGroupId) else {
          print("❌ 無法存取 App Group: \(appGroupId)")
          result(false)
          return
        }
        
        switch call.method {
        case "getAppGroupSuiteName":
          result(appGroupId)
          
        case "setStringList":
          if let args = call.arguments as? [String: Any],
             let key = args["key"] as? String,
             let value = args["value"] as? [String] {
            userDefaults.set(value, forKey: key)
            userDefaults.synchronize()
            print("✅ 已儲存 StringList: \(key) = \(value.count) 項目")
            result(true)
          } else {
            print("❌ setStringList 參數錯誤")
            result(false)
          }
          
        case "getStringList":
          if let args = call.arguments as? [String: Any],
             let key = args["key"] as? String {
            let value = userDefaults.stringArray(forKey: key)
            print("🔍 讀取 StringList: \(key) = \(value?.count ?? 0) 項目")
            result(value)
          } else {
            print("❌ getStringList 參數錯誤")
            result(nil)
          }
          
        case "setInt":
          if let args = call.arguments as? [String: Any],
             let key = args["key"] as? String,
             let value = args["value"] as? Int {
            userDefaults.set(value, forKey: key)
            userDefaults.synchronize()
            print("✅ 已儲存 Int: \(key) = \(value)")
            result(true)
          } else {
            print("❌ setInt 參數錯誤")
            result(false)
          }
          
        case "getInt":
          if let args = call.arguments as? [String: Any],
             let key = args["key"] as? String {
            let value = userDefaults.object(forKey: key) as? Int
            print("🔍 讀取 Int: \(key) = \(value ?? -1)")
            result(value)
          } else {
            print("❌ getInt 參數錯誤")
            result(nil)
          }
          
        case "remove":
          if let args = call.arguments as? [String: Any],
             let key = args["key"] as? String {
            userDefaults.removeObject(forKey: key)
            userDefaults.synchronize()
            print("🗑️ 已移除: \(key)")
            result(true)
          } else {
            print("❌ remove 參數錯誤")
            result(false)
          }
          
        case "containsKey":
          if let args = call.arguments as? [String: Any],
             let key = args["key"] as? String {
            let exists = userDefaults.object(forKey: key) != nil
            print("🔍 檢查 Key: \(key) = \(exists)")
            result(exists)
          } else {
            print("❌ containsKey 參數錯誤")
            result(false)
          }
          
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    
    // 測試 App Group 存取
    if let appGroupDefaults = UserDefaults(suiteName: appGroupId) {
      appGroupDefaults.set("iOS_app_group_configured", forKey: "test_ios_key")
      appGroupDefaults.synchronize()
      print("✅ iOS App Group 配置成功: \(appGroupId)")
      
      // 列出所有現有的鍵值
      let allKeys = Array(appGroupDefaults.dictionaryRepresentation().keys)
      print("📋 iOS App Group 現有鍵值: \(allKeys)")
    } else {
      print("❌ iOS App Group 配置失敗: \(appGroupId)")
    }
  }
}
