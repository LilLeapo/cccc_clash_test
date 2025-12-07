package com.mihomo.flutter_cross.vpn;

import android.app.Activity;
import android.content.Intent;
import android.net.VpnService;
import android.os.ParcelFileDescriptor;
import android.util.Log;

import java.io.IOException;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * Mihomo VpnService核心实现
 * 用于Android设备上的TUN模式代理流量接管
 * 
 * 功能:
 * - 申请VPN权限
 * - 建立TUN接口
 * - 流量转发管理
 * - 与Go核心交互
 */
public class MihomoVpnService {
    private static final String TAG = "MihomoVpnService";
    private static final int VPN_REQUEST_CODE = 1001;

    private Activity _activity;
    private VpnService _vpnService;
    private ParcelFileDescriptor _tunInterface;
    private AtomicBoolean _isRunning = new AtomicBoolean(false);

    // JNI external function declarations
    static {
        System.loadLibrary("mihomo_core");
    }

    // External JNI functions for TUN operations
    public static native int tunCreate(String interfaceName);
    public static native int tunStart();
    public static native int tunStop();
    public static native int tunReadPacket(byte[] buffer, int bufferSize);
    public static native int tunWritePacket(byte[] buffer, int bufferSize);
    public static native String getTunStats();
    
    // 回调接口
    public interface VpnStatusCallback {
        void onVpnStarted();
        void onVpnStopped();
        void onVpnError(String error);
    }
    
    private VpnStatusCallback _callback;
    
    /**
     * 构造函数
     */
    public MihomoVpnService(Activity activity, VpnStatusCallback callback) {
        _activity = activity;
        _callback = callback;
        _vpnService = VpnService.prepare(_activity);
    }
    
    /**
     * 检查并申请VPN权限
     */
    public boolean checkVpnPermission() {
        if (_vpnService == null) {
            Log.w(TAG, "VPN Service准备就绪，无需权限申请");
            return true;
        }
        
        try {
            Intent intent = _vpnService.getIntent();
            if (intent != null) {
                _activity.startActivityForResult(intent, VPN_REQUEST_CODE);
                return false;
            }
        } catch (Exception e) {
            Log.e(TAG, "申请VPN权限失败", e);
            if (_callback != null) {
                _callback.onVpnError("权限申请失败: " + e.getMessage());
            }
        }
        
        return true;
    }
    
    /**
     * 创建TUN接口
     */
    public boolean createTunInterface(String tunName) {
        try {
            if (_vpnService == null) {
                Log.e(TAG, "VpnService未初始化");
                return false;
            }
            
            // 构建VPN配置
            VpnService.Builder builder = _vpnService.new Builder();
            
            // 设置TUN接口名称
            builder.setSession(tunName != null ? tunName : "MihomoVPN");
            
            // 配置网络规则
            builder.addAddress("10.0.0.2", 32);
            builder.addRoute("0.0.0.0", 0);
            
            // 配置DNS
            builder.addDnsServer("8.8.8.8");
            builder.addDnsServer("1.1.1.1");
            
            // 配置应用规则 (可选)
            // builder.addAllowedApplication(packageName);
            
            // 配置MTU
            builder.setMtu(1500);
            
            // 创建TUN接口
            _tunInterface = builder.establish();
            if (_tunInterface == null) {
                Log.e(TAG, "TUN接口创建失败");
                return false;
            }
            
            Log.i(TAG, "TUN接口创建成功: " + tunName);
            return true;
            
        } catch (Exception e) {
            Log.e(TAG, "创建TUN接口异常", e);
            if (_callback != null) {
                _callback.onVpnError("TUN创建失败: " + e.getMessage());
            }
            return false;
        }
    }
    
    /**
     * 启动VPN服务
     */
    public boolean startVpn() {
        try {
            if (_tunInterface == null) {
                Log.e(TAG, "TUN接口未创建，无法启动VPN");
                return false;
            }
            
            if (_isRunning.get()) {
                Log.w(TAG, "VPN服务已在运行");
                return true;
            }
            
            _isRunning.set(true);
            
            // 调用Go核心创建TUN
            if (!callGoCoreTunCreate()) {
                _isRunning.set(false);
                return false;
            }
            
            // 启动TUN流量处理
            if (!callGoCoreTunStart()) {
                _isRunning.set(false);
                callGoCoreTunStop();
                return false;
            }
            
            Log.i(TAG, "VPN服务启动成功");
            if (_callback != null) {
                _callback.onVpnStarted();
            }
            
            return true;
            
        } catch (Exception e) {
            Log.e(TAG, "启动VPN服务异常", e);
            _isRunning.set(false);
            if (_callback != null) {
                _callback.onVpnError("启动失败: " + e.getMessage());
            }
            return false;
        }
    }
    
    /**
     * 停止VPN服务
     */
    public void stopVpn() {
        try {
            if (!_isRunning.get()) {
                Log.w(TAG, "VPN服务未在运行");
                return;
            }
            
            _isRunning.set(false);
            
            // 通知Go核心停止TUN
            callGoCoreTunStop();
            
            Log.i(TAG, "VPN服务已停止");
            if (_callback != null) {
                _callback.onVpnStopped();
            }
            
        } catch (Exception e) {
            Log.e(TAG, "停止VPN服务异常", e);
        }
    }
    
    /**
     * 释放资源
     */
    public void dispose() {
        try {
            stopVpn();
            
            if (_tunInterface != null) {
                _tunInterface.close();
                _tunInterface = null;
            }
            
        } catch (Exception e) {
            Log.e(TAG, "释放资源异常", e);
        }
    }
    
    /**
     * 获取运行状态
     */
    public boolean isRunning() {
        return _isRunning.get();
    }
    
    // ==================== Go核心调用 ====================
    
    /**
     * 调用Go核心创建TUN
     */
    private boolean callGoCoreTunCreate() {
        try {
            Log.d(TAG, "调用Go核心创建TUN");
            int result = tunCreate("mihomo-tun");
            if (result == 0) {
                Log.i(TAG, "Go核心TUN创建成功");
                return true;
            } else {
                Log.e(TAG, "Go核心TUN创建失败，错误码: " + result);
                return false;
            }
        } catch (Exception e) {
            Log.e(TAG, "Go核心TUN创建异常", e);
            return false;
        }
    }
    
    /**
     * 调用Go核心启动TUN
     */
    private boolean callGoCoreTunStart() {
        try {
            Log.d(TAG, "调用Go核心启动TUN");
            int result = tunStart();
            if (result == 0) {
                Log.i(TAG, "Go核心TUN启动成功");
                return true;
            } else {
                Log.e(TAG, "Go核心TUN启动失败，错误码: " + result);
                return false;
            }
        } catch (Exception e) {
            Log.e(TAG, "Go核心TUN启动异常", e);
            return false;
        }
    }
    
    /**
     * 调用Go核心停止TUN
     */
    private void callGoCoreTunStop() {
        try {
            Log.d(TAG, "调用Go核心停止TUN");
            int result = tunStop();
            if (result == 0) {
                Log.i(TAG, "Go核心TUN停止成功");
            } else {
                Log.e(TAG, "Go核心TUN停止失败，错误码: " + result);
            }
        } catch (Exception e) {
            Log.e(TAG, "Go核心TUN停止异常", e);
        }
    }
}
