#pragma once
#include <Arduino.h>

class HTTPClient {
public:
    static int& nextGetCodeRef() {
        static int v = 200;
        return v;
    }
    static int& nextPostCodeRef() {
        static int v = 200;
        return v;
    }
    static String& nextResponseBodyRef() {
        static String v = "{}";
        return v;
    }
    static String& lastBeginUrlRef() {
        static String v = "";
        return v;
    }
    static String& lastAuthHeaderRef() {
        static String v = "";
        return v;
    }
    static String& lastContentTypeHeaderRef() {
        static String v = "";
        return v;
    }
    static String& lastPostBodyRef() {
        static String v = "";
        return v;
    }

    static int getNextGetCode() { return nextGetCodeRef(); }
    static void setNextGetCode(int code) { nextGetCodeRef() = code; }
    static int getNextPostCode() { return nextPostCodeRef(); }
    static void setNextPostCode(int code) { nextPostCodeRef() = code; }
    static String getLastBeginUrl() { return lastBeginUrlRef(); }
    static String getLastAuthHeader() { return lastAuthHeaderRef(); }
    static String getLastContentTypeHeader() { return lastContentTypeHeaderRef(); }
    static String getLastPostBody() { return lastPostBodyRef(); }

    void begin(const String& url) { lastBeginUrlRef() = url; }
    void setTimeout(int) {}

    void addHeader(const String& key, const String& value) {
        if (key == "Authorization") lastAuthHeaderRef() = value;
        if (key == "Content-Type") lastContentTypeHeaderRef() = value;
    }

    int GET() { return nextGetCodeRef(); }

    int POST(const String& body) {
        lastPostBodyRef() = body;
        return nextPostCodeRef();
    }

    String getString() { return nextResponseBodyRef(); }
    String errorToString(int code) { return String("err:") + String(code); }
    void end() {}

    static void resetStub() {
        nextGetCodeRef() = 200;
        nextPostCodeRef() = 200;
        nextResponseBodyRef() = "{}";
        lastBeginUrlRef() = "";
        lastAuthHeaderRef() = "";
        lastContentTypeHeaderRef() = "";
        lastPostBodyRef() = "";
    }
};
