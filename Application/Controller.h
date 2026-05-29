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

    Element pull( )
    {

    }

    bool push(Element e)
    {
    
    }


private:
    SQLMap sqlMap{ };
    ModelMap modelMap{ };
    Warehouse warehouse{ };
    std::chrono::days lookback{ };

};

#endif