#ifndef CONTROLLER_H
#define CONTROLLER_H

#include "Config.h"

// Forward declarations
struct Element;


class Controller
{
public:
    Controller(Config config)
        : sqlMap{ config.dbPath },
          lookback{ config.defaultLookback }
    {
        
    }

    ~Controller()
    {
    
    }


    Element pull( )
    {

    }

    bool push(Element e)
    {
    
    }


private:
    SQLMap sqlMap{ };
    DataMap dataMap{ };
    std::array<Repository, > repo{ };
    std::chrono::days lookback{ };

};

#endif