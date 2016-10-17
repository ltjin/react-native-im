package com.yuanyinguoji.im;

import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableMapKeySetIterator;
import com.facebook.react.bridge.ReadableType;

import org.json.JSONException;
import org.json.JSONObject;

/**
 * Created by ltjin on 16/9/8.
 */
public class ReadableMapUtil {

    public static JSONObject readableMap2JSON(ReadableMap readableMap) {
        if (readableMap == null) {
            return null;
        }

        JSONObject jsonObject = new JSONObject();
        ReadableMapKeySetIterator iterator = readableMap.keySetIterator();
        if (!iterator.hasNextKey()) {
            return null;
        }

        while (iterator.hasNextKey()) {
            String key = iterator.nextKey();
            ReadableType readableType = readableMap.getType(key);
            try {
                switch (readableType) {
                    case Null:
                        jsonObject.put(key, null);
                        break;
                    case Boolean:
                        jsonObject.put(key, readableMap.getBoolean(key));
                        break;
                    case Number:
//                        String a = String.valueOf(readableMap.getInt(key));
//                        if (a.length()>=32) {
//                            double b = readableMap.getInt(key);
//                            jsonObject.put(key,readableMap.getDouble(key));
//                        }else {
//                            jsonObject.put(key, readableMap.getInt(key));
//                        }
                        jsonObject.put(key,readableMap.getDouble(key));
                        break;
                    case String:
                        jsonObject.put(key, readableMap.getString(key));
                        break;
                    case Map:
                        jsonObject.put(key, readableMap2JSON(readableMap.getMap(key)));
                        break;
                    case Array:
                        jsonObject.put(key, readableMap.getArray(key));
                    default:
                        break;
                }
            } catch (JSONException ex) {
                ex.printStackTrace();
            }
        }
        return jsonObject;
    }
}
