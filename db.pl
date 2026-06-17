:- module(db, [
    db_connect/1,
    db_disconnect/1,
    concelho_info/4,        
    concelho_vizinho/2,     
    distrito_info/3,        
    concelho_nome_exists/2  
]).

:- use_module(library(sqlite)).

% Predicados utilizados para guardar os dados na RAM após a primeira leitura da BD
:- dynamic cached_concelho/4.
:- dynamic cached_vizinho/2.
:- dynamic cached_distrito/3.
:- dynamic db_loaded/0.

% Inicia a cache na memória, Abre a BD executa consultas de agregação e carrega os resultados em memória. Garante que a ligação ao ficheiro fecha após a leitura
db_init :-db_loaded, !.

db_init :-
    sqlite_open('portugal2001.gpkg', Conn, []),
    % Carrega os concelhos com a sua população e edifícios
    forall(
        sqlite_query(Conn, 
            'SELECT dc.name, dc.code, SUM(b.RESIDENTES_T), SUM(b.EDIFICIOS) FROM BGRI01_CONT b JOIN dico_concelhos dc ON b.DTCC01 = dc.code GROUP BY dc.code',
            row(NomeStr, CodStr, Populacao, Edificios)),
        (   atom_string(Nome, NomeStr),
            atom_string(Cod, CodStr),
            assertz(cached_concelho(Nome, Cod, Populacao, Edificios))
        )
    ),
    
    % Carrega todas as relações de vizinhança entre concelhos (em minúsculas para indexação O(1))
    forall(
        sqlite_query(Conn, 
            'SELECT dc1.name, dc2.name FROM dico_vizinhos dv JOIN dico_concelhos dc1 ON dv.concelho_code1 = dc1.code JOIN dico_concelhos dc2 ON dv.concelho_code2 = dc2.code',
            row(C1Str, C2Str)),
        (   atom_string(C1, C1Str),
            atom_string(C2, C2Str),
            downcase_atom(C1, C1Min),
            downcase_atom(C2, C2Min),
            assertz(cached_vizinho(C1Min, C2Min))
        )
    ),
    
    % Carrega todos os distritos e a soma da sua população total
    forall(
        sqlite_query(Conn,
            'SELECT dd.name, dd.code, SUM(b.RESIDENTES_T) FROM BGRI01_CONT b JOIN dico_distritos dd ON b.DT01 = dd.code GROUP BY dd.code',
            row(NomeDistritoStr, CodDistritoStr, Populacao)),
        (   atom_string(NomeDistrito, NomeDistritoStr),
            atom_string(CodDistrito, CodDistritoStr),
            assertz(cached_distrito(NomeDistrito, CodDistrito, Populacao))
        )
    ),
    % Acaba com a ligação para libertar recursos e evitar bloqueios rw
    sqlite_close(Conn),
    assertz(db_loaded).

% Obtem os dados demográficos de um concelho a partir da cache a pesquisa pode ser feita com o Nome ou com o codigo DICO
concelho_info(Nome, Cod, Populacao, Edificios) :-
    db_init,
    (   nonvar(Nome)
    ->  downcase_atom(Nome, NomeMin),
        once((cached_concelho(NomeVal, Cod, Populacao, Edificios),
              downcase_atom(NomeVal, NomeMin)))
    ;   nonvar(Cod)
    ->  once(cached_concelho(Nome, Cod, Populacao, Edificios))
    ;   cached_concelho(Nome, Cod, Populacao, Edificios)
    ).

% Verifica relações de vizinhança entre dois concelhos na cache
concelho_vizinho(Concelho1, Concelho2) :-
    db_init,
    (   nonvar(Concelho1) -> downcase_atom(Concelho1, C1Min) ; true ),
    (   nonvar(Concelho2) -> downcase_atom(Concelho2, C2Min) ; true ),
    cached_vizinho(V1Min, V2Min),
    (   nonvar(Concelho1) -> V1Min = C1Min ; true ),
    (   nonvar(Concelho2) -> V2Min = C2Min ; true ),
    (   nonvar(Concelho1) -> true ; concelho_nome_exists(V1Min, Concelho1) ),
    (   nonvar(Concelho2) -> true ; concelho_nome_exists(V2Min, Concelho2) ).

% Dá o valor da população num distrito em especifico
distrito_info(NomeDistrito, CodDistrito, Populacao) :-
    db_init,
    (   nonvar(NomeDistrito)
    ->  downcase_atom(NomeDistrito, NomeMin),
        once((cached_distrito(NomeVal, CodDistrito, Populacao),
              downcase_atom(NomeVal, NomeMin)))
    ;   nonvar(CodDistrito)
    ->  once(cached_distrito(NomeDistrito, CodDistrito, Populacao))
    ;   cached_distrito(NomeDistrito, CodDistrito, Populacao)
    ).

% Nova função rápida para verificar a existência de um concelho durante o parsing
concelho_nome_exists(NomeMin, NomeCapitalizado) :-
    db_init,
    once((cached_concelho(NomeCapitalizado, _, _, _),
          downcase_atom(NomeCapitalizado, NomeMin))).

db_connect(Conn) :- sqlite_open('portugal2001.gpkg', Conn).
db_disconnect(Conn) :- sqlite_close(Conn).

% Wrappers auxiliares para o swiplite
sqlite_open(File, Conn) :- sqlite_open(File, Conn, []).
sqlite_query(Conn, SQL, RowTemplate) :- sqlite_query(Conn, SQL, RowTemplate, []).

sqlite_query(Conn, SQL, RowTemplate, Bindings) :-
    sqlite_prepare(Conn, SQL, Stmt),
    (   setup_call_cleanup(
            (   Bindings = []
            ->  true
            ;   BindingsTerm =.. [bv | Bindings],
                sqlite_bind(Stmt, BindingsTerm)
            ),
            findall(RowTemplate, sqlite_row(Stmt, RowTemplate), List),
            sqlite_finalize(Stmt)
        ),
        member(RowTemplate, List)
    ).