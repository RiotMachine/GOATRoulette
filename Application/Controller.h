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
    SQLMap m_sqlMap{ };
    ModelMap m_modelMap{ };
    Warehouse m_warehouse{ };
    std::chrono::days m_lookback{ };

};

#endif