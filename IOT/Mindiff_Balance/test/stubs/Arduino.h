#pragma once
#include <string>
#include <cstring>
#include <cstdio>
#include <cstdlib>
#include <vector>
#include <cctype>

// ── String ────────────────────────────────────────────────────────────────────
class String {
    std::string _s;
public:
    String() {}
    String(const char* s) : _s(s ? s : "") {}
    String(const std::string& s) : _s(s) {}
    String(int n)          : _s(std::to_string(n)) {}
    String(long n)         : _s(std::to_string(n)) {}
    String(unsigned int n) : _s(std::to_string(n)) {}
    String(bool b)         : _s(b ? "1" : "0") {}
    String(float n, int dec = 2) {
        char buf[32];
        std::snprintf(buf, sizeof(buf), "%.*f", dec, (double)n);
        _s = buf;
    }

    unsigned int length() const { return (unsigned int)_s.size(); }
    const char*  c_str()  const { return _s.c_str(); }

    // Required by ArduinoJson v6 Arduino String adapter (ARDUINOJSON_ENABLE_ARDUINO_STRING)
    bool concat(const char* s, size_t n) { if (s && n > 0) _s.append(s, n); return true; }
    bool concat(const char* s)            { if (s) _s += s; return true; }
    bool concat(char c)                   { _s += c; return true; }
    bool reserve(unsigned int n)           { _s.reserve(n); return true; }

    bool endsWith(const char* suffix) const {
        if (!suffix) return false;
        std::string sf(suffix);
        if (sf.size() > _s.size()) return false;
        return _s.compare(_s.size() - sf.size(), sf.size(), sf) == 0;
    }
    String substring(unsigned int start, unsigned int end) const {
        if (start >= _s.size()) return String("");
        if (end > _s.size()) end = (unsigned int)_s.size();
        if (end <= start) return String("");
        return String(_s.substr(start, end - start));
    }
    void trim() {
        size_t first = 0;
        while (first < _s.size() && std::isspace((unsigned char)_s[first])) first++;
        size_t last = _s.size();
        while (last > first && std::isspace((unsigned char)_s[last - 1])) last--;
        _s = _s.substr(first, last - first);
    }

    // std::string passthrough for find/npos usage in tests
    std::string::size_type find(const char* s) const { return _s.find(s); }
    static const std::string::size_type npos = std::string::npos;

    String& operator=(const char* s)    { _s = s ? s : ""; return *this; }
    String& operator=(const String& s)  { _s = s._s;       return *this; }
    String& operator+=(const String& s) { _s += s._s;      return *this; }
    String& operator+=(const char* s)   { if (s) _s += s;  return *this; }
    String& operator+=(char c)          { _s += c;          return *this; }

    String operator+(const String& s) const { return String(_s + s._s); }
    String operator+(const char* s)   const { return String(_s + (s ? s : "")); }

    bool operator==(const String& s) const { return _s == s._s; }
    bool operator==(const char* s)   const { return _s == (s ? s : ""); }
    bool operator!=(const String& s) const { return _s != s._s; }
    bool operator!=(const char* s)   const { return _s != (s ? s : ""); }

    friend String operator+(const char* lhs, const String& rhs) {
        return String(std::string(lhs ? lhs : "") + rhs._s);
    }
};

// ── Serial ────────────────────────────────────────────────────────────────────
struct SerialClass {
    std::string rx;
    std::vector<std::string> printed;

    void begin(int) {}
    void println(const char* s)   { printed.push_back(std::string(s ? s : "")); }
    void println(const String& s) { printed.push_back(s.c_str()); }
    void println(int n)           { printed.push_back(std::to_string(n)); }
    void print(const char* s)     { printed.push_back(std::string(s ? s : "")); }
    void print(const String& s)   { printed.push_back(s.c_str()); }

    int available() { return (int)rx.size(); }
    char read() {
        if (rx.empty()) return '\0';
        char c = rx[0];
        rx.erase(0, 1);
        return c;
    }

    void inject(const char* s) { rx += (s ? s : ""); }
    void clearOutput() { printed.clear(); }
};

// ── ESP ───────────────────────────────────────────────────────────────────────
struct EspClass {
    void restart() {}
};

// Singletons — all translation units share one instance
inline SerialClass& _serial_singleton() { static SerialClass s; return s; }
inline EspClass&    _esp_singleton()    { static EspClass    e; return e; }
#define Serial (_serial_singleton())
#define ESP    (_esp_singleton())

// ── Timing ────────────────────────────────────────────────────────────────────
inline unsigned long& __test_millis_ref() {
    static unsigned long v = 0;
    return v;
}
inline void          delay(unsigned long ms) { __test_millis_ref() += ms; }
inline unsigned long millis()                { return __test_millis_ref(); }
inline void          setMillis(unsigned long ms) { __test_millis_ref() = ms; }

inline int& __test_analog_mv_ref() {
    static int v = 0;
    return v;
}
inline int analogReadMilliVolts(int) { return __test_analog_mv_ref(); }
inline void setAnalogMilliVolts(int mv) { __test_analog_mv_ref() = mv; }

template <typename T>
inline T constrain(T x, T a, T b) {
    return (x < a) ? a : ((x > b) ? b : x);
}
