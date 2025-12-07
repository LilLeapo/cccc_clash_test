package com.mihomoflutter.core;

import android.app.Activity;
import android.content.Intent;
import android.net.VpnService;
import android.util.Log;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

import java.util.HashMap;
import java.util.Map;

public class MainActivity extends FlutterActivity {
    private static final String TAG = "MihomoFlutter";
    private static final String CHANNEL_NAME = "com.mihomoflutter.core/mihomo";
    private static final int VPN_PERMISSION_REQUEST = 1001;

    private MihomoTunService mihomoTunService;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL_NAME)
                .setMethodCallHandler((call, result) -> {
                    Log.d(TAG, "Method called: " + call.method);

                    switch (call.method) {
                        case "initializeMihomo":
                            String configPath = call.argument("configPath");
                            result.success(initializeMihomo(configPath));
                            break;

                        case "startProxy":
                            result.success(startProxy());
                            break;

                        case "stopProxy":
                            result.success(stopProxy());
                            break;

                        case "getStatus":
                            result.success(getStatus());
                            break;

                        case "startTun":
                            result.success(startTun());
                            break;

                        case "stopTun":
                            result.success(stopTun());
                            break;

                        case "ping":
                            result.success("pong");
                            break;

                        default:
                            result.notImplemented();
                            break;
                    }
                });
    }

    private boolean initializeMihomo(String configPath) {
        Log.d(TAG, "初始化Mihomo核心: " + configPath);
        try {
            // TODO: 通过JNI调用Go内核初始化
            Log.i(TAG, "Mihomo核心初始化成功");
            return true;
        } catch (Exception e) {
            Log.e(TAG, "初始化失败: " + e.getMessage(), e);
            return false;
        }
    }

    private boolean startProxy() {
        Log.d(TAG, "启动Mihomo代理");
        try {
            // TODO: 通过JNI调用Go内核启动代理
            Log.i(TAG, "Mihomo代理启动成功");
            return true;
        } catch (Exception e) {
            Log.e(TAG, "启动失败: " + e.getMessage(), e);
            return false;
        }
    }

    private boolean stopProxy() {
        Log.d(TAG, "停止Mihomo代理");
        try {
            // TODO: 通过JNI调用Go内核停止代理
            Log.i(TAG, "Mihomo代理已停止");
            return true;
        } catch (Exception e) {
            Log.e(TAG, "停止失败: " + e.getMessage(), e);
            return false;
        }
    }

    private Map<String, Object> getStatus() {
        Log.d(TAG, "获取Mihomo状态");
        try {
            Map<String, Object> status = new HashMap<>();
            status.put("status", "running");
            status.put("config", "default");
            status.put("version", "v0.1.0-alpha");
            status.put("tunActive", mihomoTunService != null);
            return status;
        } catch (Exception e) {
            Log.e(TAG, "获取状态失败: " + e.getMessage(), e);
            Map<String, Object> errorStatus = new HashMap<>();
            errorStatus.put("status", "error");
            errorStatus.put("error", e.getMessage());
            return errorStatus;
        }
    }

    private boolean startTun() {
        Log.d(TAG, "启动TUN模式");
        try {
            // 检查VPN权限
            Intent permissionIntent = VpnService.prepare(this);
            if (permissionIntent != null) {
                Log.i(TAG, "需要VPN权限，正在请求用户授权");
                startActivityForResult(permissionIntent, VPN_PERMISSION_REQUEST);
                return false;
            }

            // 创建并启动TUN服务
            mihomoTunService = new MihomoTunService();
            MihomoTunService.startTun(this);
            Log.i(TAG, "TUN模式启动成功");
            return true;
        } catch (Exception e) {
            Log.e(TAG, "TUN启动失败: " + e.getMessage(), e);
            return false;
        }
    }

    private boolean stopTun() {
        Log.d(TAG, "停止TUN模式");
        try {
            if (mihomoTunService != null) {
                MihomoTunService.stopTun(this);
                mihomoTunService = null;
                Log.i(TAG, "TUN模式已停止");
            }
            return true;
        } catch (Exception e) {
            Log.e(TAG, "TUN停止失败: " + e.getMessage(), e);
            return false;
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

        switch (requestCode) {
            case VPN_PERMISSION_REQUEST:
                if (resultCode == Activity.RESULT_OK) {
                    Log.i(TAG, "VPN权限已授予，重新启动TUN");
                    startTun();
                } else {
                    Log.w(TAG, "VPN权限被拒绝");
                }
                break;
        }
    }
}