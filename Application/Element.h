#ifndef ELEMENT_H
#define ELEMENT_H

enum class Source
{
    database,
    model,
    user
};

struct Element
{
    Source source{ Source::database };
};

struct Game : Element
{

};

struct Team : Element
{

};

struct Stage : Element
{

};

struct Season : Element
{

};

#endif