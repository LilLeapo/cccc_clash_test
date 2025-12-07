import UIKit
import Flutter

// MihomoCore桥接类
class MihomoCore {
    static let shared = MihomoCore()

    // 初始化核心
    func initialize(configPath: String) -> Int {
        print("初始化Mihomo核心: \(configPath)")
        // 实际调用Go核心初始化
        // 这里通过Go Mobile生成的接口调用
        return 0 // 成功
    }

    // 获取版本
    func getVersion() -> String {
        print("获取版本信息")
        return "0.1.0-alpha"
    }

    // 启动代理
    func startProxy() -> Int {
        print("启动代理服务")
        // 实际调用Go核心TUN启动
        // 通过Go Mobile接口启动TUN模式
        return 0 // 成功
    }

    // 停止代理
    func stopProxy() -> Int {
        print("停止代理服务")
        // 实际调用Go核心TUN停止
        // 通过Go Mobile接口停止TUN模式
        return 0 // 成功
    }
}

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
    // 实际调用Swift/Objective-C桥接层
    return MihomoCore.shared.initialize(configPath: configPath)
  }

  private func getVersion() -> String {
    print("获取版本")
    // 实际调用版本获取
    return MihomoCore.shared.getVersion()
  }

  private func startProxy() -> Int {
    print("启动代理")
    // 实际调用代理启动
    return MihomoCore.shared.startProxy()
  }

  private func stopProxy() -> Int {
    print("停止代理")
    // 实际调用代理停止
    return MihomoCore.shared.stopProxy()
  }
}