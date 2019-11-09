/**
 * A HTTP plugin for Cordova / Phonegap
 */
package com.synconset;

import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.UnknownHostException;
import java.util.Map;

import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLContext;
import javax.net.ssl.HostnameVerifier;

import javax.net.ssl.SSLHandshakeException;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.PluginResult;
import org.json.JSONException;
import org.json.JSONObject;

import android.util.Log;

import com.github.kevinsawicki.http.HttpRequest;
import com.github.kevinsawicki.http.HttpRequest.HttpRequestException;
 
public class CordovaHttpGetChunked extends CordovaHttp implements Runnable {
    public CordovaHttpGetChunked(String urlString, Map<?, ?> params, Map<String, String> headers, CallbackContext callbackContext) {
        super(urlString, params, headers, callbackContext);
    }
    
    @Override
    public void run() {
        // try {
            HttpRequest request = HttpRequest.get(this.getUrlString(), this.getParams(), false);
            this.setupSecurity(request);
            request.acceptCharset(CHARSET);
            request.acceptGzipEncoding().uncompress(true);
            request.headers(this.getHeaders());
            int code = request.code();
            // String body = request.body(CHARSET);
            // JSONObject response = new JSONObject();
            // this.addResponseHeaders(request, response);
            // response.put("status", code);
            // if (code >= 200 && code < 300) {
            //     response.put("data", body);
            //     String responseString = response.toString();
            //     int responseStringLength = responseString.length();
            //     int chunkSize = 10000; // 10000 chars
            //     int numCalls = (int) Math.ceil((double) responseStringLength / (double) chunkSize);
            //     for (int i = 0; i < numCalls; i++) {
            //         JSONObject message = new JSONObject();
            //         if (i == numCalls - 1) {
            //             message.put("end", true);
            //         }
            //         message.put("content", responseString.substring(i*chunkSize, Math.min(responseStringLength, (i + 1) * chunkSize)));
            //         PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, message);
            //         if (i != numCalls - 1) {
            //             pluginResult.setKeepCallback(true);
            //         }
            //         this.getCallbackContext().sendPluginResult(pluginResult);
            //     }
            // } else {
            //     response.put("error", body);
            //     this.getCallbackContext().error(response);
            // }
        // } catch (JSONException e) {
        //     this.respondWithError("There was an error generating the response");
        // } catch (HttpRequestException e) {
        //     if (e.getCause() instanceof UnknownHostException) {
        //         this.respondWithError(0, "The host could not be resolved");
        //     } else if (e.getCause() instanceof SSLHandshakeException) {
        //         this.respondWithError("SSL handshake failed");
        //     } else {
        //         this.respondWithError("There was an error with the request");
        //     }
        // }
    }
}