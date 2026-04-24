#pragma once
#include <Arduino.h>

class ApiClient {
public:
    ApiClient(const String& baseUrl, const String& token, int userId);

    // POST /user/{userId}/weight  → {"weight": kg, "source": "scale"}
    // Retourne true si HTTP 2xx
    bool postWeight(float weightKg);

private:
    String _baseUrl;
    String _token;
    int    _userId;
};
