#ifndef ELEMENT_H
#define ELEMENT_H

#include <utility>

struct Element
{
    enum Source
    {
        database,
        model,
        user
    };

    // nice solution to make IDs typesafe
    // https://www.ilikebigbits.com/2014_05_06_type_safe_handles.html
    template <typename Tag>
    struct ID
    {
    public:
        // explicit prevents implicit conversion of ints
        explicit ID(int x) : m_val{ x } {}
        // allowing default constructor for sim objects
        ID() = default;

        bool isValid() const { return m_val != s_invalidVal; }

        // force explicit cast to int
        explicit operator int() const { return m_val; }

        friend bool operator==(ID a, ID b) { return a.m_val == b.m_val; }
        friend bool operator!=(ID a, ID b) { return a.m_val != b.m_val; }

    private:
        // default state is invalid
        static constexpr int s_invalidVal{ -1 };
        int m_val{ s_invalidVal };
    };

    Source source{ model };
};

struct Game : Element
{
    using ID = ID<struct GameTag>;

    ID id{ };

};

struct Team : Element
{
    using ID = ID<struct TeamTag>;

    ID id{ };

};

struct Season : Element
{
    using ID = ID<struct SeasonTag>;

    ID id{ };

};

struct Stage : Element
{
    using IDPair = std::pair<Season::ID, int>;

    IDPair idPair{ };

};

#endif