:- begin_tests(ine_database_tests).

:- use_module(db).
:- use_module(reasoner).
:- use_module(parser).

% Testa a consulta por nome do concelho obtém os dados corretos
test(concelho_porto_info) :-
    db:concelho_info('Porto', Cod, Pop, Edificios),
    Cod == '1312',
    Pop == 263131,
    Edificios == 46681.

% Testar se a consulta por código DICO obtém o nome correto
test(concelho_codigo_info) :-
    db:concelho_info(Nome, '1106', Pop, _),
    Nome == 'Lisboa',
    Pop == 564657.

% Testar se a contiguidade direta funciona (vizinhos)
test(concelhos_vizinhos_directos) :-
    db:concelho_vizinho('Porto', 'Matosinhos'),
    db:concelho_vizinho('Matosinhos', 'Porto'),
    db:concelho_vizinho('Porto', 'Vila Nova de Gaia').

% Testar se concelhos distantes não são considerados vizinhos diretos
test(concelhos_nao_vizinhos, [fail]) :-
    db:concelho_vizinho('Porto', 'Lisboa').

% Testar se encontra um caminho de vizinhança entre concelhos adjacentes
test(caminho_simples) :-
    reasoner:caminho_concelhos('Porto', 'Matosinhos', Caminho),
    Caminho == ['Porto', 'Matosinhos'].

% Testar se encontra um caminho mais longo
test(caminho_longo) :-
    reasoner:caminho_concelhos('Porto', 'Maia', Caminho),
    member(Caminho, [['Porto', 'Maia'], ['Porto', 'Matosinhos', 'Maia']]).

% Testar o cálculo de habitantes por edifício
test(habitantes_por_edificio_calculo) :-
    reasoner:habitantes_por_edificio('Porto', Media),
    Media > 5.0,
    Media < 6.0.

% Testar se um concelho grande é considerado acima da média
test(concelho_acima_media) :-
    reasoner:concelho_acima_da_media('Porto'),
    reasoner:concelho_acima_da_media('Lisboa').

% Testar a tokens de strings
test(tokenize_frase) :-
    parser:tokenize("Quantas pessoas vivem no Porto?", Tokens),
    Tokens == [quantas, pessoas, vivem, no, porto].

% Testar o parsing de consulta de população
test(parse_populacao) :-
    parser:parse_sentence("Quantas pessoas vivem no Porto?", Query),
    Query == populacao('Porto').

% Testar o parsing de consulta de vizinhos
test(parse_vizinhos) :-
    parser:parse_sentence("Quais sao os vizinhos de Matosinhos?", Query),
    Query == vizinhos('Matosinhos').

% Testar o parsing de caminhos entre concelhos
test(parse_caminho) :-
    parser:parse_sentence("Qual o caminho entre Porto e Lisboa?", Query),
    Query == caminho('Porto', 'Lisboa').

% Testar o parsing de nomes compostos
test(parse_concelho_composto) :-
    parser:parse_sentence("populacao de Vila Nova de Gaia", Query),
    Query == populacao('Vila Nova de Gaia').

% Testar as queries de comparação no reasoner
test(concelho_mais_populoso_test) :-
    reasoner:concelho_mais_populoso(Concelho, Pop),
    Concelho == 'Lisboa',
    Pop == 564657.

test(concelho_mais_edificios_test) :-
    reasoner:concelho_mais_edificios(Concelho, Edificios),
    Concelho == 'Vila Nova de Gaia',
    Edificios == 63742.

% Testar o parsing das novas queries de comparação
test(parse_mais_populoso) :-
    parser:parse_sentence("Qual o concelho mais populoso?", Query),
    Query == mais_populoso.

test(parse_mais_edificios) :-
    parser:parse_sentence("Qual o concelho com mais edificios?", Query),
    Query == mais_edificios.

:- end_tests(ine_database_tests).