%==============================================================================
% Minesweeper Player using symbolic AI
%==============================================================================
% Description.......: Minesweeper player using symbolic AI
% Author............: Data Precog
% Email.............: info@dataprecog.com
% Date..............: 2000.11.02
% Version...........: 1.0


%==============================================================================
%
%==============================================================================
:- dynamic '$mina'/2.
:- dynamic '$abertas'/1.
:- dynamic '$errados'/1.
:- dynamic '$marcadas'/1.
:- dynamic aberta/2.
:- dynamic dimensao/2.
:- dynamic marca/2.

ler_campo(Ficheiro) :-
    limpar_base_dados,
    reconsult(Ficheiro),
    inicializar_base_dados.

limpar_base_dados :-
    retractall('$mina'(_, _)),
    retractall('$abertas'(_)),
    retractall('$errados'(_)),
    retractall('$marcadas'(_)),
    retractall(aberta(_, _)),
    retractall(dimensao(_, _)),
    retractall(marca(_, _)).

inicializar_base_dados :-
    assertz('$abertas'(0)),
    assertz('$errados'(0)),
    assertz('$marcadas'(0)).

abrir( X, Y ) :-
	retract( '$abertas'(N) ),
	N1 is N + 1,
	assert( '$abertas'(N1) ),
	( not aberta(X,Y) -> assert( aberta(X,Y) ) ; true ), !,
	( not '$mina' (X,Y) -> true ; 	retract ( '$errados' (E) ),
									E1 is E + 1,
									assert( '$errados' (E1) ),
!, fail
	).

mina( X, Y ) :-
	aberta(X,Y),
	'$mina'(X,Y).

%================================================================================
%
%================================================================================
minas(X, Y, N) :-
	aberta(X,Y),
	'$contar'(X,Y,N).

%================================================================================
%
%================================================================================
marcar(X, Y) :-
	(not marca(X,Y) -> 	assert( marca(X,Y) ),
						retract ( '$marcadas'(N) ),
						N1 is N + 1,
						assert( '$marcadas'(N1) )
	;
						true
	).

%================================================================================
%
%================================================================================
'$contar'(X,Y,N) :-
	findall( 1, (
		member(Dx, [-1,0,1]), member( Dy, [-1,0,1]), Vx is X + Dx, Vy is Y + Dy,
			not (X = Vx, Y = Vy), '$mina' (Vx,Vy)
		),
		M
	),
	length (M,N).

%================================================================================
%
%================================================================================
pontuacao(A, M, E) :-
    '$abertas'(A),
    '$errados'(E),
    '$marcadas'(M).

%================================================================================
%================================================================================
% Inicio de código %
%================================================================================
%================================================================================

%================================================================================
% toLst(+L, -L). função auxiliar. Devolve a própria lista 
%================================================================================
toLst(L, L) :- !.

%================================================================================
% viz_fechada(+Pos, -N, -L )
% entrada: Pos(X, Y).
% saida: n. de casas na vizinhanca de (X,Y) que nao foram abertas e nao foram 
% 	marcadas, e a lista dessas mesmas posicoes.
%================================================================================
viz_fechada_rec([], 0, []).

viz_fechada_rec([(X, Y)|Xs], N, L) :-
	aberta(X, Y), !,
	viz_fechada_rec(Xs, N, L).

viz_fechada_rec([(X, Y)|Xs], N, [(X,Y)|L1]) :-
	not aberta(X, Y),
	not marca(X, Y), !,
	viz_fechada_rec(Xs, N1, L1),
	N is N1 +1, !.

viz_fechada_rec([(X, Y)|Xs], N, L) :-
	marca(X, Y), !,
	viz_fechada_rec(Xs, N, L).

viz_fechada((X, Y), N, L) :-
	vizinhanca((X, Y), V),
	viz_fechada_rec(V, N, L), !.

%================================================================================
% viz_aberta(+Pos, -N, -L )
% entrada: Pos(X, Y).
% saida: n. de casas abertas que estao na vizinhanca de (X,Y), e a lista dessas mesmas posicoes.
%================================================================================
viz_aberta_rec([], 0, []).

viz_aberta_rec([(X, Y)|Xs], N, L) :-
	not aberta(X, Y),
	viz_aberta_rec(Xs, N, L), !.

viz_aberta_rec([(X, Y)|Xs], N, [(X, Y)|L1]) :-
	aberta(X, Y),
	viz_aberta_rec(Xs, N1, L1),
	N is N1 + 1, !.

viz_aberta((X, Y), N, L) :-
	vizinhanca((X, Y), V),
	viz_aberta_rec(V, N, L), !.

%================================================================================
% minas_viz(+Pos, -N,)
% entrada: Pos(X, Y).
% saida: n. de casas na vizinhanca de que contem minas marcadas ou
% despoletadas
%================================================================================
minas_viz_rec([], 0) :- !.

minas_viz_rec([(X, Y)|Xs], N) :-
	not mina(X, Y),
	not marca(X, Y), !,
	minas_viz_rec(Xs, N).

minas_viz_rec([(X, Y)|Xs], N) :-
	minas_viz_rec(Xs, N1),
	N is N1 + 1, !.

minas_viz((X,Y), N) :-
	vizinhanca((X, Y), V),
	minas_viz_rec(V, N), !.

%================================================================================
% vizinhanca( +Pos, -V). 
% entrada: Pos(X, Y). 
% saida: lista das posicoes das casas adjecentes a casa da posicao (X, Y).
%================================================================================
% casa nao esta junto as margens.
vizinhanca((X, Y), V) :-
	dimensao (Xd, Yd),
	X > 1,
	X < Xd,
	Y > 1,
	Y < Yd,
	X1 is X - 1,
	X2 is X + 1,
	Y1 is Y - 1,
	Y2 is Y + 1,
	toLst ([(X1,Y)|[(X1,Y2)|[(X,Y2)|[(X2,Y2)|[(X2,Y)|[(X2,Y1)|[(X,Y1)|[(X1,Y1)]]]]]]]], V).
	
% casa esta em cima.
vizinhanca((X, Y), V) :-
	dimensao (Xd, Yd),
	X > 1,
	X < Xd,
	Y = 1,
	X1 is X - 1,
	X2 is X + 1,
	Y2 is Y + 1,
	toLst([(X1,Y)|[(X1,Y2)|[(X,Y2)|[(X2,Y2)|[(X2,Y)]]]]], V).


% casa esta em baixo.
vizinhanca((X, Y), V) :-

	dimensao (Xd, Yd),
	X > 1,
	X < Xd,
	Y = Yd,
	X1 is X - 1,
	X2 is X + 1,
	Y1 is Y - 1,
	toLst([(X1,Y)|[(X2,Y)|[(X2,Y1)|[(X,Y1)|[(X1,Y1)]]]]], V).

%================================================================================
% casa esta junto a esquerda.
%================================================================================
vizinhanca((X, Y), V) :-
	dimensao (Xd, Yd),
	X = 1,
	Y > 1,
	Y < Yd,
	X2 is X + 1,
	Y1 is Y - 1,
	Y2 is Y + 1,
	toLst ([(X,Y2)|[(X2,Y2)|[(X2,Y)|[(X2,Y1)|[(X,Y1)]]]]], V).

%================================================================================
% casa esta a direita.
%================================================================================
vizinhanca((X, Y), V) :-
	dimensao (Xd, Yd),
	X = Xd,
	Y > 1,
	Y < Yd,
	X1 is X - 1,
	Y1 is Y - 1,
	Y2 is Y + 1,
	toLst([(X1,Y)|[(X1,Y2)|[(X,Y2)|[(X,Y1)|[(X1,Y1)]]]]], V).

%================================================================================
% casa do canto sup. esq.
%================================================================================
vizinhanca((X, Y), V) :-
	X = 1,
	Y = 1,
	X2 is X + 1,
	Y2 is Y + 1,
	toLst([(X,Y2)|[(X2,Y2)|[(X2,Y)]]], V).

%================================================================================
% casa do canto inf. esq.
%================================================================================
vizinhanca((X, Y), V) :-
	dimensao(Xd, Yd),
	X = 1,
	Y = Yd,
	X2 is X + 1,
	Y1 is Y - 1,
	toLst([(X2,Y)|[(X2,Y1)|[(X,Y1)]]], V).

%================================================================================
% casa do canto sup. dir.
%================================================================================
vizinhanca((X, Y), V) :-
	dimensao (Xd, Yd),
	X = Xd,
	Y = 1,
	X1 is X - 1,
	Y2 is Y + 1,
	toLst([(X1,Y)|[(X1,Y2)|[(X,Y2)]]], V).

%================================================================================
% casa do canto inf. dir.
%================================================================================
vizinhanca((X, Y), V) :-
	dimensao (Xd, Yd),
	X = Xd,
	Y = Yd,
	X1 is X - 1,
	Y1 is Y - 1,
	toLst([(X1,Y)|[(X,Y1)|[(X1,Y1)]]], V).

%================================================================================
% remove_front(+F, +(X, Y), -Fa).
%
% F 	-> lista de casas fechadas que fazem fronteira com casas abertas
% (X,Y) -> coordenadas (X, Y) de uma casa
% Fa	-> lista resultado de retirar da lista F a casa (X, Y).
%================================================================================
remove_front([], C, []) :- !.

remove_front([C|Xs], C, Xs) :- !.

remove_front([C|Xs], C2, [C|F2]) :-
	remove_front(Xs, C2, F2), !.

 
%================================================================================
% actualiza_front(+F, +NF, —Fa).
%
% F 	-> lista de casas fechadas que fazem fronteira com casas abertas
% NF	-> sub-lista de casas de fronteira
% Fa 	-> lista resultado de adicionar a lista F a lista NF sem repeticoes.
%================================================================================
actualiza_front([], F, F) :- !.

actualiza_front(F, [], F) :- !.

actualiza_front([C|Xs], [C2|Xs2], [C2|F2]) :
	not member(C2, [C|Xs]), !,
	actualiza_front([C|Xs], Xs2, F2).

actualiza_front([C|Xs], [C2|Xs2], F) :-
	member(C2, [C|Xs]), !,
	actualiza_front([C|Xs], Xs2, F).

%================================================================================
% insere_prob(+P, +PL, -Lr)
% 	insere P na lista PL de forma ordenada por Prob. e devolve o resultado em Lr
%================================================================================
insere_prob(P, [], [P]) :- !.

insere_prob((X, Y, Prob), [(X2, Y2, P2)|Xs], [(X2, Y2, P2)|Res2])
 :- 
	Prob > P2, !,
	insere_prob((X, Y, Prob), Xs, Res2).

insere_prob((X, Y, Prob), [(X2, Y2, P2)|Xs], [(X, Y, Prob)|[(X2, Y2, P2)|Xs]]) :-
	Prob =< P2, !.

%================================================================================
% probab_rec(+F, -Fp).
% entrada: uma lista de casas fechadas que fazem fronteira com casas abertas.
% saida: uma lista de elementos (X, Y, Prob) em que Prob e a probabilidade da casa 
%	(X, Y) conter uma mina
%================================================================================
probab_rec([], []) :- !.

probab_rec([(X, Y)|Xs], Fp) :-
	viz_aberta((X, Y), Na, La),
	get_prob(La, Prob),
	probab_rec(Xs, Fp2),
	insere_prob((X, Y, Prob), Fp2, Fp), !.

%================================================================================
% get_prob(+L, -Prob).
% entrada: a lista de casas abertas que fazem fronteira com uma casa fechada F
% saida: a probabilidade da casa F ter mina
%================================================================================
get_prob([], 0) :- !.

get_prob([(X, Y)|Xs], 1) :-
	get_prob(Xs, Prob2),
	Prob2 = 1, !.
get_prob([(X, Y)|Xs], 1) :-
	minas(X, Y, N),
	viz_fechada((X, Y), Nf, Lf),
	minas_viz((X, Y), Nm),
	Pt is (N - Nm) / Nf,
	Pt = 1, !.

get_prob([(X, Y)|Xs], Prob) :-
	minas(X, Y, N),
	viz_fechada((X, Y), Nf, Lf),
	minas_viz((X, Y), Nm),
	Xs \= [], !,
	get_prob(Xs, Prob2),
	Pt is (N - Nm) / Nf,
	Prob is Pt * Prob2.

get_prob([(X, Y)|Xs], Prob) :-
	minas(X, Y, N),
	viz_fechada((X, Y), Nf, Lf),
	minas_viz((X, Y), Nm),
	Xs = [], !,
	Prob is (N - Nm) / Nf.

%================================================================================
% analisa( +F, -Fa).
%================================================================================
analisa(F, Fa) :-
	probab_rec(F, Fp),
	marcar_rec(F, Fp, Fa2),
	abre(Fa2, Fp, Fa).

%================================================================================
% abrir_rec(+F, +Fp, -Fa ).
% entrada: uma lista de casas de fronteira fechadas, uma lista que associa uma
% 	probabilidade de existir minas em cada casa fechada de fronteira.
% saida: uma lista de casas fechadas de fronteira actualizadas apos a abertura
% 	de uma ou mais casas.
%================================================================================
abrir_X(F, (X, Y), Fa) :-
	abrir(X, Y),
	remove_front(F, (X, Y), F2),
	viz_fechada((X, Y), N, Vf),
	actualiza_front(F2, Vf, Fa).
abrir_rec(F, [], F) :- !.

abrir_rec(F, [(X, Y, 0)|Xs], Fa) :-
	abrir_rec(F, Xs, F2),
	abrir_X(F2, (X, Y), Fa), !.

abrir_rec(F, [P|Xs], Fa) :-
	abrir_rec(F, Xs, Fa), !.

 
%================================================================================
% marcar_rec(+F, +Lp, -Fr ).
% entrada: lista de casas fechadas de front., lista de (X, Y, Prob), em que 
% 	X, Y sao as coordenadas de uma casa, e Prob e a probabilidade da casa X, Y ter
% 	mina. este predicado marca as casas X,Y se a casa X, Y tiver probabilidade de
% 	ter mina = 1
% 
% saida: lista de fronteiras actualizada apos a remocao da coordenada (X,Y) da lista F.
%================================================================================
marcar_rec(F, [], F).

marcar_rec(F, [(X, Y, 1)|Xs], Fa) :-
	marcar_rec(F, Xs, Fa2),
	marcar(X, Y),
	remove_front(Fa2, (X, Y), Fa), !.

marcar_rec(F, [(X, Y, Prob)|Xs], Fa) :-
	marcar_rec(F, Xs, Fa), !.
	
%================================================================================
% joga_incerteza(+F, +Fp, —Fa).
%
% F		-> lista contendo as casa fechadas que fazem fronteira com casas abertas.
% Fp 	-> lista de elementos(X, Y, Prob), em que Prob e a probabilidade de
%				existencia de mina na casa de coordenadas (X, Y).
% Fa 	-> lista contendo as casa fechadas que fazem fronteira com casas
%				abertas apos a abertura de uma nova casa.
%================================================================================
joga_incerteza(F, [(X,Y,P)|Ps], Fa) :-
	P =< 0.25, !, 					% 0.34
	remove_front(F, (X, Y), F2),
	viz_fechada((X, Y), N, Vf),
	actualiza_front(F2, Vf, Fa),
	arrisca(X, Y).

joga_incerteza(F, [(X,Y,P)|Ps], Fa) :-
	P > 0.25, !,
	dimensao (Xd, Yd),
	aleatorio(Xd, Yd, F, Fa).

arrisca(X, Y) :-
	abrir(X, Y), !.

arrisca(X, Y) :- !.

%================================================================================
% incerteza(+Fp).
% Fp 	-> lista de elementos(X, Y, Prob), em que Prob e a probabilidade de
% 				existencia de mina na casa de coordenadas (X, Y).
================================================================================
incerteza([]).

incerteza([(X, Y, Prob)|Xs]) :-
	Prob > 0,
	Prob < 1, !,
	incerteza(Xs).

%================================================================================
% abre(F, Fp, Fa).
% entrada:a lista actual das casas fechadas que fazem fronteira com casas abertas,
% 	a lista que associa uma probabilidade de existencia de minas a cada uma das
% 	casas de fronteira.
% saida: a lista actualizada das casas de fronteira apos ter aberto uma ou mais
% 	casas.
%================================================================================
abre(F, Fp, Fa) :-
	not incerteza(Fp), !,
	abrir_rec(F, Fp, Fa).

abre(F, Fp, Fa) :-
	incerteza(Fp), !,
	joga_incerteza(F, Fp, Fa).
%================================================================================
% jogar(+F).
% entrada: lista actual das casas fechadas que fazem fronteira com casas abertas.
%================================================================================
jogar(F) :-
	pontuacao(A, M, D),
	Cont is A + M,
	dimensao (Xd, Yd),
	Dim is Xd * Yd,
	Cont < Dim,
	analisa(F, Fa), !,
	jogar(Fa).

jogar(F) :-
	pontuacao(A, M, D),
	Cont is A + M,
	dimensao (Xd, Yd),
	Dim is Xd * Yd,
	Cont < Dim, !,
	aleatorio(Xd, Yd, F, F2),
	jogar(F2).

jogar(F) :-
	pontuacao(A, M, D),
	Cont is A + M,
	dimensao(Xd, Yd),
	Dim is Xd * Yd,
	Cont = Dim, !.

%================================================================================
% aleatorio(+Xd, +Yd, +F, -Fr).
% 	abre uma casa fechada aleatoriamente
%================================================================================
aleatorio(Xd, Yd, F, Fr) :-
	X is int(rand(Xd) + 1),
	Y is int(rand(Yd) + 1),
	not aberta(X, Y),
	not marca(X, Y), !,
	viz_fechada((X, Y), N, V),
	remove_front(F, (X, Y), F2),
	actualiza_front(F2, V, Fr),
	aleatorioX(X, Y).

aleatorio(Xd, Yd, F, Fr) :-
	aleatorio(Xd, Yd, F, Fr), !.

aleatorioX(X, Y) :-
	abrir(X, Y), !.

aleatorioX(X, Y) :- !.

%================================================================================
% inicia(+X, +Y).
% efectua a primeira jogada
%================================================================================
inicia(X, Y) :-
	abrir(X, Y), !,
	viz_fechada((X, Y), N, F),
	jogar(F).

inicia(X, Y) :-
	viz_fechada((X, Y), N, F),
	jogar(F).

%================================================================================
% minas( +Ficheiro, +Pos).
% entrada: nome do ficheiro que contem um campo de minas, e uma posicao (X,Y)
% 	inicial para comecar a jogar.
%================================================================================
minas(Ficheiro, (X, Y)) :-
	ler_campo( Ficheiro ),
	inicia(X, Y).


%================================================================================
% fim do codigo %
%================================================================================

%================================================================================
% baterias de testes %
%================================================================================
bateria(1,Abertas,Marcadas,Destapadas) :-
	minas(bateria1,(3,8)),
	pontuacao(Abertas,Marcadas,Destapadas).

bateria(2,Abertas,Marcadas,Destapadas) :-
	minas(bateria2,(4,10)),
	pontuacao(Abertas,Marcadas,Destapadas) .

bateria(3,Abertas,Marcadas,Destapadas) :-
	minas(bateria3,(7,1)),
	pontuacao(Abertas,Marcadas,Destapadas) .
bateria(4,Abertas,Marcadas,Destapadas) :-
	minas(bateria4,(20,4)),
	pontuacao(Abertas,Marcadas,Destapadas).

bateria(5,Abertas,Marcadas,Destapadas) :-
	minas(bateria5,(35,3)),
	pontuacao(Abertas,Marcadas,Destapadas).

%================================================================================
% EOF
%================================================================================
