#ifndef ELEMENT_H
#define ELEMENT_H

#include "aliases.h"
#include "wrappers.h"
#include <cstdint>
// for std::is_aggregate
#include <type_traits>

// Preventing Element instantiation would ruin inheritors' aggreg status
struct Element
{
    // IDs map to SQL IDs or array indices at crossover points
    using IDType = std::int32_t;

    enum Source
    {
        database,
        model,
        user
    };

    Source source{ model };
};


// Team maps to SQL.franchise
// Team takes most-recent SQL.team info as printing data
/// determined by most-recent startDate
struct Team : Element
{
    static_assert(std::is_aggregate_v<Team>);
    using ID = Wrapper::ID<struct TeamTag, IDType>;

    ID id{ ID::next() };
    std::string city{ };
    std::string mascot{ };
    Alias::UnixTime startDate{ };
};

struct Season : Element
{
    static_assert(std::is_aggregate_v<Season>);
    using ID = Wrapper::ID<struct SeasonTag, IDType>;

    ID id{ ID::next() };
    int stages{ };
    Alias::UnixTime startDate{ };
    Alias::UnixTime endDate{ };
};

struct Stage : Element
{
    static_assert(std::is_aggregate_v<Stage>);
    struct IDPair
    {
        Season::ID seasonID{ };
        int number{ };
    };

    IDPair idPair{ };
    bool isPlayoff{ };
};

struct Game : Element
{
    static_assert(std::is_aggregate_v<Game>);
    using ID = Wrapper::ID<struct GameTag, IDType>;
    struct Opponent
    {
        Team::ID teamID{ };
        int score{ };
    };

    ID id{ ID::next() };
    Stage::IDPair stage{ };
    Alias::UnixTime startTime{ };
    bool atNeutralSite{ };
    Opponent home{ };
    Opponent away{ };
};

#endif