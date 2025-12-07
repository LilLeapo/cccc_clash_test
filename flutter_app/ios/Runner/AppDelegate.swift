import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // 设置MethodChannel
    let controller = window?.rootViewController as! FlutterViewController
    let methodChannel = FlutterMethodChannel(
      name: "mihomo_flutter_cross",
      binaryMessenger: controller.binaryMessenger
    )

    methodChannel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "initializeCore":
        let configPath = call.arguments as? String ?? ""
        result(self?.initializeCore(configPath: configPath))

      case "getVersion":
        result(self?.getVersion())

      case "startProxy":
        result(self?.startProxy())

      case "stopProxy":
        result(self?.stopProxy())

      case "ping":
        result("pong")

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func initializeCore(configPath: String) -> Int {
    print("初始化核心: \(configPath)")
    // TODO: 实际调用Swift/Objective-C桥接层
    return 0 // 成功
  }

  private func getVersion() -> String {
    print("获取版本")
    // TODO: 实际调用版本获取
    return "v0.1.0-alpha-ios"
  }

  private func startProxy() -> Int {
    print("启动代理")
    // TODO: 实际调用代理启动
    return 0 // 成功
  }

  private func stopProxy() -> Int {
    print("停止代理")
    // TODO: 实际调用代理停止
    return 0 // 成功
  }
}