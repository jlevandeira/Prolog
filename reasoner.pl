:- module(reasoner, [
    caminho_concelhos/3,          
    caminho_restrito/4,           
    ricolandia/2,                 
    habitantes_por_edificio/2,    
    media_nacional_populacao/1,   
    concelho_acima_da_media/1,    
    concelho_mais_populoso/2,     
    concelho_mais_edificios/2,
    concelho_menos_populoso/2,
    concelho_menos_edificios/2     
]).

:- use_module(db).

% Encontra o caminho mais curto de concelhos vizinhos usando BFS com visitados 
caminho_concelhos(Origem, Destino, Caminho) :-
    bfs_caminho([[Origem]], Destino, [Origem], CaminhoReverso),
    reverse(CaminhoReverso, Caminho).

% Caso base do BFS, encontrou o destino no início de um dos caminhos da fila
bfs_caminho([[Destino|Path]|_], Destino, _, [Destino|Path]) :- !.

% Caso recursivo, expande o nó atual
bfs_caminho([[Atual|Path]|Queue], Destino, Visited, Caminho) :-
    findall([Vizinho, Atual|Path],
            (concelho_vizinho(Atual, Vizinho), \+ member(Vizinho, Visited)),
            NewPaths),
    maplist(get_path_head, NewPaths, NewNeighbors),
    append(Visited, NewNeighbors, NewVisited),
    append(Queue, NewPaths, NewQueue),
    bfs_caminho(NewQueue, Destino, NewVisited, Caminho).

% Encontra um caminho de concelhos vizinhos onde todos os concelhos têm população >= MinPop
caminho_restrito(Origem, Destino, MinPop, Caminho) :-
    concelho_info(Origem, _, PopOrigem, _), PopOrigem >= MinPop,
    bfs_caminho_restrito([[Origem]], Destino, MinPop, [Origem], CaminhoReverso),
    reverse(CaminhoReverso, Caminho).

% Caso base do BFS Restrito
bfs_caminho_restrito([[Destino|Path]|_], Destino, _, _, [Destino|Path]) :- !.

% Caso recursivo do BFS Restrito com visitados globais
bfs_caminho_restrito([[Atual|Path]|Queue], Destino, MinPop, Visited, Caminho) :-
    findall([Vizinho, Atual|Path],
            (concelho_vizinho(Atual, Vizinho), 
             \+ member(Vizinho, Visited),
             concelho_info(Vizinho, _, Pop, _),
             Pop >= MinPop),
            NewPaths),
    maplist(get_path_head, NewPaths, NewNeighbors),
    append(Visited, NewNeighbors, NewVisited),
    append(Queue, NewPaths, NewQueue),
    bfs_caminho_restrito(NewQueue, Destino, MinPop, NewVisited, Caminho).

% Função auxiliar para obter a cabeça de um caminho
get_path_head([H|_], H).

% Condição para fazer parte da Ricolândia
concelho_rico(Concelho) :-
    concelho_acima_da_media(Concelho).

% Encontra o cluster máximo contíguo usando BFS
ricolandia(ConcelhoInicio, Cluster) :-
    concelho_rico(ConcelhoInicio),
    bfs_ricolandia([ConcelhoInicio], [ConcelhoInicio], Cluster).

% Caso base, fila de processamento vazia
bfs_ricolandia([], Visitados, Visitados) :- !.

% Caso recursivo, processa o primeiro elemento da fila
bfs_ricolandia([Atual|Fila], Visitados, Cluster) :-
    % Encontra todos os vizinhos do concelho Atual que são ricos e ainda não foram visitados
    findall(Vizinho, 
            (concelho_vizinho(Atual, Vizinho), 
             concelho_rico(Vizinho), 
             \+ member(Vizinho, Visitados)), 
            VizinhosNovos),
    % Remove duplicados e junta à fila e aos visitados
    list_to_set(VizinhosNovos, VizinhosSet),
    append(Fila, VizinhosSet, NovaFila),
    append(Visitados, VizinhosSet, NovosVisitados),
    bfs_ricolandia(NovaFila, NovosVisitados, Cluster).

% Calcula a média de habitantes por edifício num determinado concelho
habitantes_por_edificio(Concelho, Media) :-
    concelho_info(Concelho, _, Pop, Edificios),
    Edificios > 0,
    Media is Pop / Edificios.

% Calcula a média nacional de população por concelho usando Prolog puro
media_nacional_populacao(Media) :-
    findall(Pop, concelho_info(_, _, Pop, _), ListaPop),
    sum_list(ListaPop, Total),
    length(ListaPop, Qtd),
    Qtd > 0,
    Media is round(Total / Qtd).

% Verifica ou lista concelhos cuja população está pelo menos 10% acima da média nacional
concelho_acima_da_media(Concelho) :-
    media_nacional_populacao(Media),
    Limit is Media * 1.10,
    db:concelho_info(Concelho, _, Pop, _),
    Pop > Limit.

% Encontra o concelho com maior população
concelho_mais_populoso(Concelho, MaxPop) :-
    findall(Pop-Nome, db:concelho_info(Nome, _, Pop, _), L),
    keysort(L, Sorted),
    last(Sorted, MaxPop-Concelho).

% Encontra o concelho com maior número de edifícios
concelho_mais_edificios(Concelho, MaxEdificios) :-
    findall(Edif-Nome, db:concelho_info(Nome, _, _, Edif), L),
    keysort(L, Sorted),
    last(Sorted, MaxEdificios-Concelho).

% Enconctra o concelho com menor população
concelho_menos_populoso(Concelho, MinPop) :-
    findall(Pop-Nome, db: concelho_info(Nome, _, Pop, _), L),
    keysort(L, Sorted),
    Sorted = [MinPop-Concelho|_].

% Encontra o concelho com menor numero de edificios
concelho_menos_edificios(Concelho, MinEdificios) :-
    findall(Edif-Nome, db: concelho_info(Nome, _, _, Edif), L),
    keysort(L, Sorted),
    Sorted = [MinEdificios - Concelho|_].