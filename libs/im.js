/**
 * Created by ltjin on 16/9/23.
 */
import { NativeModules, NativeAppEventEmitter} from 'react-native';
export default class IM {
    static login(account, appKey){
        NativeModules.IMModule.login(account, appKey);
    }

    static onReceive(fn){
        NativeAppEventEmitter.addListener("onReceive", fn);
    }

    static onKick(fn){
        NativeAppEventEmitter.addListener("onKick", fn);
    }
};