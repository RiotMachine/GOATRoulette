#ifndef CONFIG_H
#define CONFIG_H

#include <chrono>
#include <string>

struct Config
{
    std::string dbPath{ };
    std::chrono::days defaultLookback{ };
};

#endif