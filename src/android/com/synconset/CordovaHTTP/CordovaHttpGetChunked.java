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
        try {
            HttpRequest request = HttpRequest.get(this.getUrlString(), this.getParams(), false);
            this.setupSecurity(request);
            request.acceptCharset(CHARSET);
            request.acceptGzipEncoding().uncompress(true);
            request.headers(this.getHeaders());
            int code = request.code();
            InputStream body = request.stream();
            if (code >= 200 && code < 300) {
                byte[] data = new byte[100000];
                int bytesRead = body.read(data);
                while (bytesRead != -1) {
                    JSONObject message = new JSONObject();
                    String bodyPart = new String(data);
                    message.put("content", bodyPart);

                    PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, message);
                    pluginResult.setKeepCallback(true);
                    this.getCallbackContext().sendPluginResult(pluginResult);

                    data = new byte[100000];
                    bytesRead = body.read(data);
                }
                body.close();

                JSONObject message = new JSONObject();
                message.put("end", true);
                PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, message);
                this.getCallbackContext().sendPluginResult(pluginResult);
            } else {
                String bodyString = request.body(CHARSET);
                JSONObject response = new JSONObject();
                response.put("error", bodyString);
                this.getCallbackContext().error(response);
            }
        } catch (JSONException e) {
            this.respondWithError("There was an error generating the response");
        } catch (HttpRequestException e) {
            if (e.getCause() instanceof UnknownHostException) {
                this.respondWithError(0, "The host could not be resolved");
            } else if (e.getCause() instanceof SSLHandshakeException) {
                this.respondWithError("SSL handshake failed");
            } else {
                this.respondWithError("There was an error with the request");
            }
        } catch (IOException e) {
            this.respondWithError("There was an error generating the response");
        }
    }
}