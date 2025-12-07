// iOS Network Extension 实现
// 用于iOS平台的TUN模式代理

import NetworkExtension
import os.log

class MihomoPacketTunnelProvider: NEPacketTunnelProvider {

    private let logger = OSLog(subsystem: "com.mihomo.flutter_cross", category: "PacketTunnel")
    private var isRunning = false

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        os_log("开始启动隧道", log: logger, type: .info)

        // 配置隧道设置
        let tunnelSettings = NEPacketTunnelNetworkSettings(
            tunnelRemoteAddress: "127.0.0.1"
        )

        // 配置DNS设置
        let dnsSettings = NEDNSSettings(servers: ["8.8.8.8", "8.8.4.4"])
        dnsSettings.searchDomains = ["local"]
        tunnelSettings.dnsSettings = dnsSettings

        // 配置代理设置（如果需要）
        // let proxySettings = NEProxySettings()
        // proxySettings.httpEnabled = true
        // proxySettings.httpsEnabled = true
        // tunnelSettings.proxySettings = proxySettings

        // 应用设置
        setTunnelNetworkSettings(tunnelSettings) { [weak self] error in
            if let error = error {
                os_log("隧道设置失败: %{public}s", log: self?.logger ?? OSLog, type: .error, error.localizedDescription)
                completionHandler(error)
                return
            }

            self?.isRunning = true
            os_log("隧道启动成功", log: self?.logger ?? OSLog, type: .info)

            // 开始处理数据包
            self?.startPacketProcessing()

            completionHandler(nil)
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        os_log("停止隧道, 原因: %{public}d", log: logger, type: .info, reason.rawValue)

        isRunning = false
        completionHandler()
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        os_log("收到应用消息", log: logger, type: .debug)

        // 处理来自主应用的消息
        if let response = processMessage(messageData) {
            completionHandler?(response)
        } else {
            completionHandler?(nil)
        }
    }

    private func startPacketProcessing() {
        os_log("开始数据包处理", log: logger, type: .info)

        // 这里应该实现数据包的处理逻辑
        // 1. 从packetFlow读取数据包
        // 2. 传递给Go内核处理
        // 3. 将处理后的数据包写回packetFlow

        // 模拟数据包处理
        processPackets()
    }

    private func processMessage(_ data: Data) -> Data? {
        // 处理来自主应用的控制消息
        let message = String(data: data, encoding: .utf8) ?? ""

        switch message {
        case "start":
            return "started".data(using: .utf8)
        case "stop":
            return "stopped".data(using: .utf8)
        case "status":
            let status = isRunning ? "running" : "stopped"
            return status.data(using: .utf8)
        default:
            return nil
        }
    }

    private func processPackets() {
        // 模拟数据包处理循环
        // 在实际实现中，这里会：
        // 1. 调用packetFlow.readPackets()
        // 2. 将数据包传递给Mihomo内核
        // 3. 调用packetFlow.writePackets()

        os_log("数据包处理循环运行中", log: logger, type: .debug)
    }

    deinit {
        os_log("PacketTunnelProvider 释放", log: logger, type: .info)
    }
}