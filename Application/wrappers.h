#ifndef WRAPPERS_H
#define WRAPPERS_H

namespace Wrapper
{
    // typesafe IDs
    // https://www.ilikebigbits.com/2014_05_06_type_safe_handles.html
    template <typename Tag, typename T=int, T sentinel=-1>
    struct ID
    {
    public:
        // explicit prevents implicit conversion of integrals
        explicit ID(T x) : m_val{ x } {}
        // allowing default constructor for sim objects
        ID() = default;

        static ID invalid() { return ID{ sentinel }; }
        static ID next()    { return ID{ s_nextVal++ }; }

        // force explicit cast to integral
        explicit operator T() const { return m_val; }

        friend bool operator==(ID a, ID b) { return a.m_val == b.m_val; }
        friend bool operator!=(ID a, ID b) { return a.m_val != b.m_val; }

    private:
        // default state is invalid
        T m_val{ sentinel };
        static T s_nextVal{ 1 };
    };

}

#endif