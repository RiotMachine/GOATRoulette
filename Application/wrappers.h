#ifndef WRAPPERS_H
#define WRAPPERS_H

#include <atomic>

namespace Wrapper
{
    // typesafe IDs
    // https://www.ilikebigbits.com/2014_05_06_type_safe_handles.html
    template <typename Tag, typename T=int, T sentinelVal=-1, T startVal=1>
    struct ID
    {
    public:
        // explicit prevents implicit conversion of integrals
        explicit ID(T x) : m_val{ x } {}
        // allowing default constructor for sim objects
        ID() = default;

        static ID sentinel() { return ID{ sentinelVal }; }
        static ID next()     { return ID{ s_nextVal++ }; }

        // force explicit cast to integral
        explicit operator T() const { return m_val; }

        friend bool operator< (ID a, ID b) { return a.m_val <  b.m_val; }
        friend bool operator> (ID a, ID b) { return a.m_val >  b.m_val; }
        friend bool operator==(ID a, ID b) { return a.m_val == b.m_val; }
        friend bool operator!=(ID a, ID b) { return a.m_val != b.m_val; }

    private:
        // default state is invalid
        T m_val{ sentinelVal };
        // atomic prevents race conditions
        static inline std::atomic<T> s_nextVal{ startVal };
    };

}

#endif