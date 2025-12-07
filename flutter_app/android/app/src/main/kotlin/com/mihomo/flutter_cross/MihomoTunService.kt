// Android TUN服务实现
// VpnService -> fd -> Go gVisor 数据包传递

package com.mihomo.flutter_cross

import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import kotlinx.coroutines.*
import java.io.FileInputStream
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.util.concurrent.ConcurrentLinkedQueue

class MihomoTunService : VpnService() {

    companion object {
        private const val TAG = "MihomoTunService"
        private const val MTU = 1500
        private const val PACKET_SIZE = 1504 // MTU + headers
    }

    private var vpnInterface: ParcelFileDescriptor? = null
    private var inputStream: FileInputStream? = null
    private var outputStream: FileOutputStream? = null
    private var isRunning = false

    private val serviceScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private val packetQueue = ConcurrentLinkedQueue<ByteArray>()

    // 回调接口
    interface TunCallback {
        fun onPacketReceived(packet: ByteArray)
        fun onPacketSent(packet: ByteArray)
        fun onStatusChanged(isRunning: Boolean)
    }

    private var callback: TunCallback? = null

    fun setCallback(callback: TunCallback?) {
        this.callback = callback
    }

    override fun onCreate() {
        super.onCreate()
        Log.i(TAG, "TUN服务创建")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.i(TAG, "TUN服务启动命令: ${intent?.action}")

        when (intent?.action) {
            ACTION_START_TUN -> startTunnel()
            ACTION_STOP_TUN -> stopTunnel()
            else -> Log.w(TAG, "未知操作: ${intent?.action}")
        }

        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.i(TAG, "TUN服务销毁")
        stopTunnel()
    }

    override fun onRevoke() {
        super.onRevoke()
        Log.i(TAG, "VPN权限被撤销")
        stopTunnel()
    }

    private fun startTunnel() {
        if (isRunning) {
            Log.w(TAG, "TUN服务已在运行")
            return
        }

        try {
            // 检查VPN权限
            val permission = prepare(this)
            if (permission != null) {
                Log.e(TAG, "需要VPN权限")
                return
            }

            // 创建VPN配置
            val builder = Builder()
                .setSession("Mihomo TUN")
                .setMtu(MTU)
                .addAddress("10.0.0.2", 24)
                .addDnsServer("8.8.8.8")
                .addDnsServer("8.8.4.4")
                .addRoute("0.0.0.0", 0)
                .setConfigureIntent(null) // 可选：配置Activity

            // 添加所有接口的流量拦截
            builder.addDisallowedApplication(packageName)

            // Android 14+ 需要显式网络接口
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                builder.setUnderlyingNetworks(arrayOf())
            }

            vpnInterface = builder.establish()
            if (vpnInterface == null) {
                Log.e(TAG, "VPN接口创建失败")
                return
            }

            inputStream = FileInputStream(vpnInterface!!.fileDescriptor)
            outputStream = FileOutputStream(vpnInterface!!.fileDescriptor)

            isRunning = true
            callback?.onStatusChanged(true)
            Log.i(TAG, "TUN接口创建成功")

            // 启动数据包处理协程
            startPacketProcessing()

        } catch (e: Exception) {
            Log.e(TAG, "启动TUN失败: ${e.message}", e)
            stopTunnel()
        }
    }

    private fun stopTunnel() {
        if (!isRunning) return

        Log.i(TAG, "停止TUN服务")
        isRunning = false
        callback?.onStatusChanged(false)

        try {
            serviceScope.cancel()
            inputStream?.close()
            outputStream?.close()
            vpnInterface?.close()
        } catch (e: Exception) {
            Log.e(TAG, "关闭TUN接口失败: ${e.message}", e)
        }

        inputStream = null
        outputStream = null
        vpnInterface = null
    }

    private fun startPacketProcessing() {
        serviceScope.launch {
            try {
                Log.i(TAG, "开始数据包处理循环")

                while (isRunning) {
                    // 处理接收的数据包
                    val receiveJob = async {
                        try {
                            val packet = receivePacket()
                            if (packet != null) {
                                processInboundPacket(packet)
                            }
                        } catch (e: Exception) {
                            if (isRunning) {
                                Log.e(TAG, "接收数据包异常: ${e.message}")
                            }
                        }
                    }

                    // 处理发送的数据包
                    val sendJob = async {
                        try {
                            val packet = packetQueue.poll()
                            if (packet != null) {
                                sendPacket(packet)
                            }
                        } catch (e: Exception) {
                            if (isRunning) {
                                Log.e(TAG, "发送数据包异常: ${e.message}")
                            }
                        }
                    }

                    // 等待完成
                    receiveJob.await()
                    sendJob.await()

                    // 短暂休眠以避免CPU占用过高
                    delay(1)
                }

                Log.i(TAG, "数据包处理循环结束")
            } catch (e: Exception) {
                Log.e(TAG, "数据包处理异常: ${e.message}", e)
            }
        }
    }

    private fun receivePacket(): ByteArray? {
        val buffer = ByteBuffer.allocate(PACKET_SIZE)
        val length = inputStream?.read(buffer.array()) ?: -1

        if (length > 0) {
            val packet = ByteArray(length)
            System.arraycopy(buffer.array(), 0, packet, 0, length)
            return packet
        }

        return null
    }

    private fun processInboundPacket(packet: ByteArray) {
        try {
            // 这里应该将数据包传递给Go gVisor处理
            // 实际实现中需要通过JNI或FFI调用Go代码

            // 模拟处理延迟
            delay(1)

            // 将处理后的数据包排队发送
            packetQueue.offer(packet)

            callback?.onPacketReceived(packet)
            Log.d(TAG, "处理入站数据包: ${packet.size} bytes")

        } catch (e: Exception) {
            Log.e(TAG, "处理入站数据包异常: ${e.message}", e)
        }
    }

    private fun sendPacket(packet: ByteArray) {
        try {
            val buffer = ByteBuffer.wrap(packet)
            val written = outputStream?.write(packet) ?: -1

            if (written == packet.size) {
                callback?.onPacketSent(packet)
                Log.d(TAG, "发送出站数据包: ${packet.size} bytes")
            } else {
                Log.e(TAG, "数据包发送不完整: 期望 ${packet.size}, 实际 $written")
            }
        } catch (e: Exception) {
            Log.e(TAG, "发送数据包异常: ${e.message}", e)
        }
    }

    // 从Flutter应用注入数据包（用于测试）
    fun injectOutboundPacket(packet: ByteArray) {
        if (isRunning) {
            packetQueue.offer(packet)
        }
    }

    // 获取TUN接口信息
    fun getTunInfo(): Map<String, Any> {
        return mapOf(
            "isRunning" to isRunning,
            "mtu" to MTU,
            "interface" to (vpnInterface?.int_fd ?: -1)
        )
    }

    companion object {
        const val ACTION_START_TUN = "start_tun"
        const val ACTION_STOP_TUN = "stop_tun"

        fun startTunnel(context: Context) {
            val intent = Intent(context, MihomoTunService::class.java).apply {
                action = ACTION_START_TUN
            }
            context.startForegroundService(intent)
        }

        fun stopTunnel(context: Context) {
            val intent = Intent(context, MihomoTunService::class.java).apply {
                action = ACTION_STOP_TUN
            }
            context.stopService(intent)
        }
    }
}