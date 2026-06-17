:- module(app, [
    start/0
]).

:- use_module(db).
:- use_module(parser).
:- use_module(reasoner).

start :- print_welcome, repl.

% Ciclo REPL
repl :-
    write('Pergunta > '),
    flush_output,
    read_line_to_string(user_input, String),
    (   (String == "sair" ; String == "exit")
    ->  write('A sair...'), nl
    ;   String == ""
    ->  repl
    ;   process_input(String),
        repl
    ).

% Processa o input de texto do utilizador
process_input(String) :-
    (   parser:parse_sentence(String, Query)
    ->  (   execute_query(Query)
        ->  true
        ;   write('Erro ao processar a query na base de dados.'), nl
        )
    ;   print_help
    ).

% Execução de queries
% Consulta demográfica simples de população residente de um concelho em especifico
execute_query(populacao(Concelho)) :-
    (   db:concelho_info(Concelho, Cod, Pop, Edificios)
    ->  print_table_header(['Concelho', 'Codigo DICO', 'Populacao Res.', 'Edificios']),
        print_table_row([Concelho, Cod, Pop, Edificios]),
        print_table_footer(['Concelho', 'Codigo DICO', 'Populacao Res.', 'Edificios'])
    ;   format('Nao foi possivel encontrar informacao para o concelho: ~w~n', [Concelho])
    ).

% Consulta comparativa que identifica e mostra o concelho com maior populacao
execute_query(mais_populoso) :-
    (   reasoner:concelho_mais_populoso(Concelho, Pop)
    ->  db:concelho_info(Concelho, Cod, _, Edificios),
        print_table_header(['Concelho', 'Codigo DICO', 'Populacao', 'Edificios']),
        print_table_row([Concelho, Cod, Pop, Edificios]),
        print_table_footer(['Concelho', 'Codigo DICO', 'Populacao', 'Edificios'])
    ;   write('Erro ao obter dados.'), nl
    ).

% Consulta comparativa que identifica e mostra o concelho com maior número de edificios
execute_query(mais_edificios) :-
    (   reasoner:concelho_mais_edificios(Concelho, Edificios)
    ->  db:concelho_info(Concelho, Cod, Pop, _),
        print_table_header(['Concelho', 'Codigo DICO', 'Populacao', 'Edificios']),
        print_table_row([Concelho, Cod, Pop, Edificios]),
        print_table_footer(['Concelho', 'Codigo DICO', 'Populacao', 'Edificios'])
    ;   write('Erro ao obter dados.'), nl
    ).

% Consulta comparativa que identifica e mostra o concelho com menor populacao
execute_query(menos_populoso) :-
    ( reasoner:concelho_menos_populoso(Concelho, Pop)
    -> db:concelho_info(Concelho, Cod, _, Edificios),
       print_table_header(['Concelho', 'Codigo DICO', 'Populacao', 'Edificios']),
       print_table_row([Concelho, Cod, Pop, Edificios]),
       print_table_footer(['Concelho', 'Codigo DICO', 'Populacao', 'Edificios'])
    ; write('Erro ao obter dados.'), nl
    ).

% Consulta comparativa que identifica e mostra o concelho com menor número de edificios
execute_query(menos_edificios) :-
    ( reasoner:concelho_menos_edificios(Concelho, Edificios)
    -> db:concelho_info(Concelho, Cod, Pop, _),
       print_table_header(['Concelho', 'Codigo DICO', 'Populacao', 'Edificios']),
       print_table_row([Concelho, Cod, Pop, Edificios]),
       print_table_footer(['Concelho', 'Codigo DICO', 'Populacao', 'Edificios'])
    ; write('Erro ao obter dados.'), nl
    ).

% Procura e lista todos os concelhos vizinhos de um certo concelho
execute_query(vizinhos(Concelho)) :-
    findall(V, db:concelho_vizinho(Concelho, V), Vizinhos),
    (   Vizinhos \= []
    ->  format('~nConcelhos vizinhos de ~w:~n', [Concelho]),
        print_table_header(['Concelho Vizinho']),
        forall(member(V, Vizinhos), print_table_row([V])),
        print_table_footer(['Concelho Vizinho'])
    ;   format('Nao foram encontrados concelhos vizinhos para ~w.~n', [Concelho])
    ).

% Proura e imprime a rota de concelhos entre um local A e local B
execute_query(caminho(C1, C2)) :-
    (   reasoner:caminho_concelhos(C1, C2, Caminho)
    ->  format('~nCaminho de contiguidade encontrado entre ~w e ~w:~n', [C1, C2]),
        print_table_header(['Ordem', 'Concelho']),
        print_caminho_passos(Caminho, 1),
        print_table_footer(['Ordem', 'Concelho'])
    ;   format('Nao existe nenhum caminho de concelhos vizinhos contiguos entre ~w e ~w.~n', [C1, C2])
    ).
% Procura e lista a região conexa de concelhos com populacao >= 10% da media nacional
execute_query(ricolandia(Concelho)) :-
    (   reasoner:ricolandia(Concelho, Cluster)
    ->  length(Cluster, ListSize),
        format('~nRegiao "Ricolandia" a partir de ~w (~d concelhos ricos contiguos):~n', [Concelho, ListSize]),
        print_table_header(['Concelho da Ricolandia']),
        forall(member(C, Cluster), print_table_row([C])),
        print_table_footer(['Concelho da Ricolandia'])
    ;   format('O concelho ~w nao qualifica para iniciar a Ricolandia (populacao abaixo da media).~n', [Concelho])
    ).

% Consulta demográfica simples do número total de edificios de um concelho
execute_query(edificios(Concelho)) :-
    (   db:concelho_info(Concelho, _, _, Edificios)
    ->  print_table_header(['Concelho', 'Edificios Totais']),
        print_table_row([Concelho, Edificios]),
        print_table_footer(['Concelho', 'Edificios Totais'])
    ;   format('Nao foi possivel obter edificios para ~w.~n', [Concelho])
    ).

% Calcula e mostra a media de habitantes por edificio num concelho
execute_query(media_edificio(Concelho)) :-
    (   reasoner:habitantes_por_edificio(Concelho, Media)
    ->  nl,
        print_table_header(['Concelho', 'Habitantes / Edificio']),
        format('| ~w~t~20+ | ~2f~t~20+ |~n', [Concelho, Media]),
        print_table_footer(['Concelho', 'Habitantes / Edificio'])
    ;   format('Nao foi possivel calcular a media para ~w.~n', [Concelho])
    ).

% Parte responsável por imprimir tabelas de resultados de forma organizada
print_table_header(Cols) :- print_divider(Cols), print_row(Cols), print_divider(Cols).
print_table_row(Cols) :- print_row(Cols).
print_table_footer(Cols) :- print_divider(Cols), nl.
print_divider(Cols) :- length(Cols, N), print_divider_segments(N).
print_divider_segments(0) :- write('+'), nl.

print_divider_segments(N) :-
    N > 0,
    write('+----------------------'),
    N1 is N - 1,
    print_divider_segments(N1).

print_row(Cols) :-
    write('|'),
    forall(member(Col, Cols), 
           (   pad_atom(Col, 20, Padded),
               format(' ~w |', [Padded])
           )),
    nl.

pad_atom(Val, Width, Padded) :-
    format(string(Str), '~w', [Val]),
    string_chars(Str, Chars),
    length(Chars, Len),
    (   Len >= Width
    ->  atom_chars(Padded, Chars)
    ;   PadLen is Width - Len,
        generate_spaces(PadLen, Spaces),
        append(Chars, Spaces, PaddedChars),
        atom_chars(Padded, PaddedChars)
    ).

% Helper para gerar uma lista de N espaços
generate_spaces(0, []) :- !.
generate_spaces(N, [' '|T]) :- N > 0, N1 is N - 1, generate_spaces(N1, T).

print_caminho_passos([], _).
print_caminho_passos([H|T], Passo) :- print_table_row([Passo, H]), Proximo is Passo + 1, print_caminho_passos(T, Proximo).

print_welcome :-
    nl,
    write('                    BASE DE DADOS                    '), nl,
    write('====================================================='), nl,
    write(' Escreve as tuas perguntas em Portugues.                    '), nl,
    write(' Escreve "sair" ou "exit" para terminar o programa.         '), nl,
    write('====================================================='), nl,
    write(' Exemplos de perguntas que podes fazer:                     '), nl,
    write('  - "Quantas pessoas vivem no Porto?"                       '), nl,
    write('  - "Qual a populacao de Sintra?"                           '), nl,
    write('  - "Quais sao os vizinhos de Matosinhos?"                  '), nl,
    write('  - "Qual o caminho entre Porto e Lisboa?"                  '), nl,
    write('  - "Qual a ricolandia a partir do Porto?"                  '), nl,
    write('  - "Quantos edificios tem Leiria?"                         '), nl,
    write('  - "Media de habitantes por edificio em Loures?"           '), nl,
    write('  - "Qual o concelho mais populoso?"                        '), nl,
    write('  - "Qual o concelho com mais edificios?"                   '), nl, nl.

print_help :-
    write('Tenta formular a pergunta de outra maneira.'), nl,
    write('Exemplos de perguntas que podes fazer:'), nl,
    write('  - "Quantas pessoas vivem no Porto?"'), nl,
    write('  - "Qual a populacao de Sintra?"'), nl,
    write('  - "Quais sao os vizinhos de Matosinhos?"'), nl,
    write('  - "Qual o caminho entre Porto e Lisboa?"'), nl,
    write('  - "Qual a ricolandia a partir do Porto?"'), nl,
    write('  - "Quantos edificios tem Leiria?"'), nl,
    write('  - "Media de habitantes por edificio em Loures?"'), nl,
    write('  - "Qual o concelho mais populoso?"'), nl,
    write('  - "Qual o concelho com mais edificios?"'), nl, nl.