#ifndef ELEMENT_H
#define ELEMENT_H

#include "aliases.h"
#include "wrappers.h"
#include <cstdint>

struct Element
{
    using IDType = std::int32_t;

    enum Source
    {
        database,
        model,
        user
    };

    Source source{ model };
};

// IDs map to SQL IDs or array indices at crossover points

struct Team : Element
{
    using ID = Wrapper::ID<struct TeamTag, IDType>;

    ID id{ ID::next() };

};

struct Season : Element
{
    using ID = Wrapper::ID<struct SeasonTag, IDType>;

    ID id{ ID::next() };

};

struct Stage : Element
{
    struct IDPair
    {
        Season::ID seasonID{ };
        int number{ };
    };

    IDPair idPair{ };

};

struct Game : Element
{
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