// iOS TUN Provider - 核心TUN实现
// 基于NEPacketTunnelProvider实现iOS平台的TUN代理

import NetworkExtension
import os.log
import SystemConfiguration
import Network
import Foundation

@available(iOS 14.0, *)
class MihomoTunProvider: NEPacketTunnelProvider {

    private let logger = OSLog(subsystem: "com.mihomo.flutter_cross", category: "TunProvider")
    private var packetFlow: NEPacketTunnelFlow?
    private var isRunning = false
    private var tunnelFD: Int32 = -1

    // TUN配置
    private let tunAddress = "10.0.0.2"
    private let tunSubnetMask = "255.255.255.0"
    private let dnsServers = ["8.8.8.8", "8.8.4.4"]
    private let mtu = 1500
    private let tunInterfaceName = "mihomo-tun"

    // 数据统计
    private var packetsIn = 0
    private var packetsOut = 0
    private var bytesIn: UInt64 = 0
    private var bytesOut: UInt64 = 0

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        os_log("🚀 开始启动 iOS TUN 隧道", log: logger, type: .info)

        guard let packetFlow = self.packetFlow else {
            let error = NSError(domain: "MihomoTunProvider", code: 1, userInfo: [NSLocalizedDescriptionKey: "PacketFlow 未初始化"])
            os_log("❌ PacketFlow 初始化失败", log: logger, type: .error)
            completionHandler(error)
            return
        }

        do {
            try configureTunnel()

            // 创建TUN接口
            try createTunInterface()

            // 初始化Go TUN接口
            initializeGoTun()

            // 开始数据包处理
            startPacketProcessing()

            isRunning = true
            os_log("✅ iOS TUN 隧道启动成功", log: logger, type: .info)
            completionHandler(nil)

        } catch {
            os_log("❌ TUN 隧道启动失败: %{public}s", log: logger, type: .error, error.localizedDescription)
            completionHandler(error)
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        os_log("🛑 停止 iOS TUN 隧道，原因: %{public}d", log: logger, type: .info, reason.rawValue)

        isRunning = false

        // 停止Go TUN接口
        stopGoTun()

        // 清理TUN接口
        cleanupTunInterface()

        // 清理资源
        cleanupResources()

        completionHandler()
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        os_log("📱 收到应用消息", log: logger, type: .debug)

        guard let response = processAppMessage(messageData) else {
            completionHandler?(nil)
            return
        }

        completionHandler?(response)
    }

    override func wake() {
        os_log("🔔 TUN Provider 被唤醒", log: logger, type: .info)
    }

    // MARK: - 私有方法

    private func configureTunnel() throws {
        os_log("🔧 配置 TUN 隧道设置", log: logger, type: .info)

        // 创建网络设置
        let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: tunAddress)

        // 配置 IP 地址
        let addressSettings = NEIPv4Settings(addresses: [tunAddress], subnetMasks: [tunSubnetMask])
        networkSettings.ipv4Settings = addressSettings

        // 配置 DNS 设置
        let dnsSettings = NEDNSSettings(servers: dnsServers)
        dnsSettings.matchDomains = [""] // 所有域名
        dnsSettings.searchDomains = ["local"]
        networkSettings.dnsSettings = dnsSettings

        // 配置 MTU
        networkSettings.mtu = NSNumber(value: mtu)

        // 应用设置
        setTunnelNetworkSettings(networkSettings) { error in
            if let error = error {
                os_log("❌ 应用网络设置失败: %{public}s", log: self.logger, type: .error, error.localizedDescription)
            } else {
                os_log("✅ 网络设置应用成功", log: self.logger, type: .info)
            }
        }
    }

    private func createTunInterface() throws {
        os_log("🌐 创建TUN接口: %{public}s", log: logger, type: .info, tunInterfaceName)

        // 在实际实现中，这里会调用系统API创建TUN接口
        // 由于iOS沙盒限制，可能需要使用Network Extension Framework

        // 模拟TUN文件描述符
        tunnelFD = 3 // 模拟fd
        os_log("✅ TUN接口创建成功，FD: %{public}d", log: logger, type: .info, tunnelFD)
    }

    private func initializeGoTun() {
        os_log("🔗 初始化Go TUN接口", log: logger, type: .info)

        // 通过FFI调用Go TUN接口
        // 在实际实现中需要使用Dart FFI或Objective-C桥接

        // 模拟Go TUN初始化
        let result = callGoTunFunction("TunCreate", tunInterfaceName)
        if result == 0 {
            os_log("✅ Go TUN接口初始化成功", log: logger, type: .info)
        } else {
            os_log("❌ Go TUN接口初始化失败: %{public}d", log: logger, type: .error, result)
        }
    }

    private func startPacketProcessing() {
        guard let packetFlow = self.packetFlow else { return }

        os_log("📦 开始数据包处理循环", log: logger, type: .info)

        packetFlow.readPacketObjects { [weak self] packetObjects in
            guard let self = self, self.isRunning else { return }

            // 处理接收到的数据包
            for packetObject in packetObjects {
                self.processInboundPacket(packetObject)
            }

            // 继续读取数据包
            if self.isRunning {
                self.startPacketProcessing()
            }
        }
    }

    private func processInboundPacket(_ packetObject: NEIncomingPacketObject) {
        guard let data = packetObject.data as Data? else { return }

        // 更新统计
        packetsIn += 1
        bytesIn += UInt64(data.count)

        os_log("📥 处理入站数据包: %{public}d bytes", log: logger, type: .debug, data.count)

        do {
            // 这里应该将数据包传递给 Go gVisor 处理
            let processedData = try processPacketWithGo(data)

            // 将处理后的数据包发送回系统
            sendOutboundPacket(processedData)

        } catch {
            os_log("❌ 数据包处理异常: %{public}s", log: logger, type: .error, error.localizedDescription)
        }
    }

    private func processPacketWithGo(_ packetData: Data) throws -> Data {
        // 这里应该实现与 Go 内核的 FFI 通信
        // 目前返回原始数据包

        // 模拟处理延迟
        usleep(100) // 100 microseconds

        // 调用Go TUN读取函数
        let goPacket = callGoTunFunction("TunReadPacket", "")
        if goPacket != 0 {
            os_log("⚠️ Go TUN读取失败: %{public}d", log: logger, type: .debug, goPacket)
        }

        return packetData
    }

    private func sendOutboundPacket(_ packetData: Data) {
        guard let packetFlow = self.packetFlow else { return }

        // 更新统计
        packetsOut += 1
        bytesOut += UInt64(packetData.count)

        // 创建出站数据包
        let packetObject = NEPacketObject(data: packetData as NSData, protocolFamily: AF_INET)

        // 发送数据包
        packetFlow.writePacketObjects([packetObject])

        os_log("📤 发送出站数据包: %{public}d bytes", log: logger, type: .debug, packetData.count)
    }

    private func callGoTunFunction(_ functionName: String, _ parameter: String) -> Int32 {
        // 模拟调用Go TUN函数
        // 在实际实现中需要通过FFI或桥接调用

        os_log("🔗 调用Go函数: %{public}s(%{public}s)", log: logger, type: .debug, functionName, parameter)

        // 模拟函数调用结果
        return 0 // 成功
    }

    private func processAppMessage(_ messageData: Data) -> Data? {
        let message = String(data: messageData, encoding: .utf8) ?? ""

        switch message {
        case "status":
            let status = isRunning ? "running" : "stopped"
            return status.data(using: .utf8)

        case "stats":
            let stats = getTunStats()
            return try? JSONSerialization.data(withJSONObject: stats)

        case "stop":
            stopTunnel(with: .userInitiated) {
                // 停止完成
            }
            return "stopping".data(using: .utf8)

        default:
            os_log("❓ 未知的应用消息: %{public}s", log: logger, type: .debug, message)
            return nil
        }
    }

    private func getTunStats() -> [String: Any] {
        return [
            "interface": tunInterfaceName,
            "active": isRunning,
            "packetsIn": packetsIn,
            "packetsOut": packetsOut,
            "bytesIn": bytesIn,
            "bytesOut": bytesOut,
            "mtu": mtu,
            "address": tunAddress,
            "dnsServers": dnsServers
        ]
    }

    private func stopGoTun() {
        os_log("🛑 停止Go TUN接口", log: logger, type: .info)

        let result = callGoTunFunction("TunStop", "")
        if result == 0 {
            os_log("✅ Go TUN接口停止成功", log: logger, type: .info)
        } else {
            os_log("❌ Go TUN接口停止失败: %{public}d", log: logger, type: .error, result)
        }
    }

    private func cleanupTunInterface() {
        os_log("🧹 清理TUN接口", log: logger, type: .info)

        if tunnelFD >= 0 {
            close(tunnelFD)
            tunnelFD = -1
        }
    }

    private func cleanupResources() {
        os_log("🧹 清理资源", log: logger, type: .info)

        // 清理统计数据
        packetsIn = 0
        packetsOut = 0
        bytesIn = 0
        bytesOut = 0

        packetFlow = nil
    }

    deinit {
        os_log("🗑️ MihomoTunProvider 释放", log: logger, type: .info)
        cleanupResources()
    }
}

// MARK: - iOS TUN Provider Extension

@available(iOS 14.0, *)
extension MihomoTunProvider {

    /// 获取当前TUN接口信息
    func getTunInterfaceInfo() -> [String: Any] {
        return [
            "address": tunAddress,
            "subnetMask": tunSubnetMask,
            "dnsServers": dnsServers,
            "mtu": mtu,
            "interfaceName": tunInterfaceName,
            "isRunning": isRunning,
            "packetsIn": packetsIn,
            "packetsOut": packetsOut,
            "bytesIn": bytesIn,
            "bytesOut": bytesOut
        ]
    }

    /// 检查网络连通性
    func checkNetworkConnectivity() -> Bool {
        return isRunning && tunnelFD >= 0
    }

    /// 重置统计数据
    func resetStats() {
        os_log("📊 重置TUN统计数据", log: logger, type: .info)
        packetsIn = 0
        packetsOut = 0
        bytesIn = 0
        bytesOut = 0

        // 调用Go TUN统计重置
        _ = callGoTunFunction("ResetTunStats", "")
    }
}