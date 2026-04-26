#pragma once

class HX711 {
public:
    void  begin(int, int)               {}
    bool  is_ready()                    { return true; }
    float get_units(int = 1)            { return 0.0f; }
    void  tare(int = 10)                {}
    void  set_scale(float = 1.0f)       {}
    void  set_offset(long = 0)          {}
    long  get_offset()                  { return 0; }
    float get_scale()                   { return 1.0f; }
    long  read()                        { return 0; }
    long  read_average(int = 10)        { return 0; }
    long  get_value(int = 1)            { return 0; }
};
