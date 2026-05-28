#ifndef ELEMENT_H
#define ELEMENT_H

#include "aliases.h"
#include "wrappers.h"
#include <cstdint>
#include <optional>
#include <string>
#include <type_traits> // for std::is_aggregate

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

// Default plan is to enforce invariants at boundaries
// Leaving seemingly-derived fields for invariant purposes

// Maps to SQL.franchise
// Takes most-recent SQL.team info as printing data
/// determined by most-recent team.startDate w/in config window
struct Franchise : Element
{
    static_assert(std::is_aggregate_v<Franchise>);
    using ID = Wrapper::ID<struct FranchiseTag, IDType>;

    ID id{ };
    std::string city{ };
    std::string mascot{ };
    Alias::UnixTime startDate{ };
    std::optional<Alias::UnixTime> endDate{ };
};

// keeping Season and Stage separate for now
// seasons owning stages complicates stage-specific logic
struct Season : Element
{
    static_assert(std::is_aggregate_v<Season>);
    using ID = Wrapper::ID<struct SeasonTag, IDType>;

    ID id{ };
    Alias::UnixTime startDate{ };
    Alias::UnixTime endDate{ };
    int maxStage{ };
    int playoffStageBoundary{ };
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
        Franchise::ID franchiseID{ };
        int score{ };
    };

    ID id{ };
    Opponent home{ };
    Opponent away{ };
    bool atNeutralSite{ };
    Stage::IDPair stage{ };
    Alias::UnixTime startTime{ };
};

#endif