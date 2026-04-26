#pragma once
#include <string>
#include <cstring>
#include <cstdio>
#include <cstdlib>

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

    // std::string passthrough for find/npos usage in tests
    std::string::size_type find(const char* s) const { return _s.find(s); }
    static const std::string::size_type npos = std::string::npos;

    String& operator=(const char* s)    { _s = s ? s : ""; return *this; }
    String& operator=(const String& s)  { _s = s._s;       return *this; }
    String& operator+=(const String& s) { _s += s._s;      return *this; }
    String& operator+=(const char* s)   { if (s) _s += s;  return *this; }

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
    void begin(int) {}
    void println(const char*)   {}
    void println(const String&) {}
    void println(int)           {}
    void print(const char*)     {}
    void print(const String&)   {}
};

// ── ESP ───────────────────────────────────────────────────────────────────────
struct EspClass {
    void restart() {}
};

// Static singletons — safe for single-binary native tests
static SerialClass Serial;
static EspClass    ESP;

// ── Timing ────────────────────────────────────────────────────────────────────
inline void          delay(unsigned long) {}
inline unsigned long millis()             { return 0; }
