#ifndef CONFIG_H
#define CONFIG_H

#include <chrono>
#include <string>

struct Config
{
    std::string dBPath{ };
    std::chrono::hours defaultLookback{ };

};

#endif