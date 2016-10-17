package com.yuanyinguoji.im;

import android.support.annotation.Nullable;
import android.util.Log;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.netease.nimlib.sdk.NIMClient;
import com.netease.nimlib.sdk.Observer;
import com.netease.nimlib.sdk.RequestCallback;
import com.netease.nimlib.sdk.StatusCode;
import com.netease.nimlib.sdk.auth.AuthService;
import com.netease.nimlib.sdk.auth.AuthServiceObserver;
import com.netease.nimlib.sdk.auth.LoginInfo;
import com.netease.nimlib.sdk.avchat.AVChatManager;
import com.netease.nimlib.sdk.avchat.model.AVChatAttachment;
import com.netease.nimlib.sdk.avchat.model.AVChatData;
import com.netease.nimlib.sdk.msg.MsgService;
import com.netease.nimlib.sdk.msg.model.IMMessage;
import com.netease.nimlib.sdk.team.constant.TeamFieldEnum;
import com.netease.nimlib.sdk.team.model.IMMessageFilter;
import com.netease.nimlib.sdk.team.model.UpdateTeamAttachment;
import com.yuanyinguoji.im.config.preference.UserPreferences;

import org.json.JSONObject;

import java.util.Map;

/**
 * Created by ltjin on 2016/10/9.
 */
public class IMModule extends ReactContextBaseJavaModule {

    private static String TAG = "<<<<<<< IMModule >>>>>>>";
    private ReactContext mRCT;

    public IMModule(ReactApplicationContext reactContext) {
        super(reactContext);
        mRCT = reactContext;
        Cache.setContext(getReactApplicationContext());
    }

    @Override
    public String getName() {
        return "IMModule";
    }

    @ReactMethod
    public void login(ReadableMap account, String appKey){
        try {
            Log.e(TAG, "登录............");
            JSONObject accJson = ReadableMapUtil.readableMap2JSON(account);
            String acc = accJson.getString("accId");
            String token = accJson.getString("accToken");
            LoginInfo loginInfo = new LoginInfo(acc, token);

            NIMClient.getService(AuthService.class).login(loginInfo).setCallback(new RequestCallback<LoginInfo>() {
                @Override
                public void onSuccess(LoginInfo info) {
                    Log.i(TAG, "登录成功！");
                    //监听多端登录
                    onKick();

                    // 注册通知消息过滤器
                    registerIMMessageFilter();

                    // 初始化消息提醒
                    NIMClient.toggleNotification(UserPreferences.getNotificationToggle());

                    // 注册网络通话来电
                    enableAVChat();
                }

                @Override
                public void onFailed(int i) {
                    Log.w(TAG, "登录失败！code: " + i);
                }

                @Override
                public void onException(Throwable throwable) {
                    Log.e(TAG, "登录异常！");
                    throwable.printStackTrace();
                }
            });
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void onKick(){
        NIMClient.getService(AuthServiceObserver.class).observeOnlineStatus(
                new Observer<StatusCode>() {
                    public void onEvent(StatusCode status) {
                        Log.i(TAG, "登录状态："+status.toString());
                        if(status == StatusCode.KICKOUT){
                            WritableMap params = Arguments.createMap();
                            params.putString("code", status.ordinal()+"");
                            sendEvent(mRCT, "onKick", params);
                        }
                    }
                }, true);
    }

    private void sendEvent(ReactContext reactContext,
                           String eventName,
                           @Nullable WritableMap params) {
        reactContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit(eventName, params);
    }

    /**
     * 通知消息过滤器（如果过滤则该消息不存储不上报）
     */
    private void registerIMMessageFilter() {
        NIMClient.getService(MsgService.class).registerIMMessageFilter(new IMMessageFilter() {
            @Override
            public boolean shouldIgnore(IMMessage message) {
                if (UserPreferences.getMsgIgnore() && message.getAttachment() != null) {
                    if (message.getAttachment() instanceof UpdateTeamAttachment) {
                        UpdateTeamAttachment attachment = (UpdateTeamAttachment) message.getAttachment();
                        for (Map.Entry<TeamFieldEnum, Object> field : attachment.getUpdatedFields().entrySet()) {
                            if (field.getKey() == TeamFieldEnum.ICON) {
                                return true;
                            }
                        }
                    } else if (message.getAttachment() instanceof AVChatAttachment) {
                        return true;
                    }
                }
                return false;
            }
        });
    }

    /**
     * 音视频通话配置与监听
     */
    private void enableAVChat() {
        registerAVChatIncomingCallObserver(true);
    }

    private void registerAVChatIncomingCallObserver(boolean register) {
        AVChatManager.getInstance().observeIncomingCall(new Observer<AVChatData>() {
            @Override
            public void onEvent(AVChatData data) {
                long callId = data.getChatId();
                Log.e(TAG, "callId->" + callId);
                WritableMap params = Arguments.createMap();
                params.putString("callId", callId+"");
                sendEvent(mRCT, "onReceive", params);
            }
        }, register);
    }

}
