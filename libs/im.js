/**
 * Created by ltjin on 16/9/23.
 */
import { NativeModules } from 'react-native';
export default class IM {
    static login(account, appKey){
        NativeModules.IMModule.login(account, appKey);
    }
};