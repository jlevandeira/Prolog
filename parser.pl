:- module(parser, [
    parse_sentence/2,  
    tokenize/2          
]).

:- use_module(db).
:- use_module(library(apply)).

% Ponto de entrada do parser
parse_sentence(String, Query) :- tokenize(String, Tokens), phrase(sentence(Query), Tokens).

% Converte a string para minúsculas, separa por espaços/pontuação e gera átomos
tokenize(String, Tokens) :-
    string_lower(String, Lower),
    split_string(Lower, " ,.?!;:", " ,.?!;:", StringList),
    exclude(==(""), StringList, CleanList),
    maplist(atom_string, Tokens, CleanList).

% Regras da gramática

% Consulta de População
sentence(populacao(Concelho)) --> [quantas, pessoas, vivem], preposicao, concelho_name(Concelho).
sentence(populacao(Concelho)) --> [pessoas], preposicao, concelho_name(Concelho).
sentence(populacao(Concelho)) --> [qual, a, populacao], preposicao, concelho_name(Concelho).
sentence(populacao(Concelho)) --> [populacao], preposicao, concelho_name(Concelho).
sentence(populacao(Concelho)) --> [populacao], concelho_name(Concelho).
sentence(populacao(Concelho)) --> [quantos, habitantes, tem], concelho_name(Concelho).
sentence(populacao(Concelho)) --> [habitantes], preposicao, concelho_name(Concelho).
sentence(populacao(Concelho)) --> [habitantes], concelho_name(Concelho).

% Consulta de Vizinhos
sentence(vizinhos(Concelho)) --> [quais, sao, os, vizinhos], preposicao, concelho_name(Concelho).
sentence(vizinhos(Concelho)) --> [quais, concelhos, sao, vizinhos], preposicao, concelho_name(Concelho).
sentence(vizinhos(Concelho)) --> [vizinhos], preposicao, concelho_name(Concelho).
sentence(vizinhos(Concelho)) --> [vizinhos], concelho_name(Concelho).

% Consulta de Caminhos
sentence(caminho(C1, C2)) --> [qual, o, caminho, entre], concelho_name(C1), [e], concelho_name(C2).
sentence(caminho(C1, C2)) --> [caminho], preposicao, concelho_name(C1), [a], concelho_name(C2).

% Consulta de Ricolândia
sentence(ricolandia(Concelho)) --> [qual, a, ricolandia, a, partir], preposicao, concelho_name(Concelho).
sentence(ricolandia(Concelho)) --> [ricolandia], preposicao, concelho_name(Concelho).
sentence(ricolandia(Concelho)) --> [ricolandia], concelho_name(Concelho).

% Consulta de Edifícios
sentence(edificios(Concelho)) --> [quantos, edificios, existem], preposicao, concelho_name(Concelho).
sentence(edificios(Concelho)) --> [quantos, edificios, tem], concelho_name(Concelho).
sentence(edificios(Concelho)) --> [edificios], preposicao, concelho_name(Concelho).
sentence(edificios(Concelho)) --> [edificios], concelho_name(Concelho).

% Média de habitantes por edifício
sentence(media_edificio(Concelho)) --> [media, de, habitantes, por, edificio], preposicao, concelho_name(Concelho).

% Comparações
sentence(mais_populoso) --> [qual, o, concelho, mais, populoso].
sentence(mais_populoso) --> [qual, o, concelho, com, maior, populacao].
sentence(mais_populoso) --> [concelho, mais, populoso].

sentence(menos_populoso) --> [qual, o, concelho, menos, populoso].
sentence(menos_populoso) --> [qual, o, concelho, com, menor, populacao].
sentence(menos_populoso) --> [concelho, menos, populoso].

sentence(mais_edificios) --> [qual, o, concelho, com, mais, edificios].
sentence(mais_edificios) --> [concelho, com, mais, edificios].

sentence(menos_edificios) --> [qual, o, concelho, com, menos, edificios].
sentence(menos_edificios) --> [concelho, com, menos, edificios].

% Auxiliar da gramática
preposicao --> [no] ; [na] ; [em] ; [de] ; [do] ; [da] ; [a] ; [para].

concelho_name(NomeCapitalizado) -->[W1, W2, W3, W4],
    {
        atomic_list_concat([W1, W2, W3, W4], ' ', Nome),
        concelho_existe(Nome, NomeCapitalizado)
    }, !.

concelho_name(NomeCapitalizado) --> [W1, W2, W3],
    {
        atomic_list_concat([W1, W2, W3], ' ', Nome),
        concelho_existe(Nome, NomeCapitalizado)
    }, !.

concelho_name(NomeCapitalizado) --> [W1, W2],
    {
        atomic_list_concat([W1, W2], ' ', Nome),
        concelho_existe(Nome, NomeCapitalizado)
    }, !.

concelho_name(NomeCapitalizado) --> [W1],
    {
        concelho_existe(W1, NomeCapitalizado)
    }.

% Verifica se o concelho existe na BD e obtém a sua capitalização correta.
concelho_existe(NomeMin, NomeCapitalizado) :-
    db:concelho_nome_exists(NomeMin, NomeCapitalizado).
