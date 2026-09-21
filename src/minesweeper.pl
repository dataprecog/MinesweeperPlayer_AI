%==============================================================================
% Minesweeper Player using symbolic AI
%==============================================================================
% Description.......: Minesweeper player using symbolic AI
% Author............: Data Precog
% Email.............: info@dataprecog.com
% Date..............: 2000.11.02
% Version...........: 1.2


%==============================================================================
%
%==============================================================================
:- module(minesweeper, [
    new_game/4,
    open_cell/2,
    flag_cell/2,
    unflag_cell/2,
    print_board/0,
    print_board/1,
    solve/0,
    solve/1,
    game_status/1
]).

:- use_module(library(lists)).

:- dynamic board_width/1.
:- dynamic board_height/1.
:- dynamic mine/2.
:- dynamic cell/3.
:- dynamic game_status/1.

%==============================================================================
% Game creation
%==============================================================================
new_game(Width, Height, Mines, InitialOpen) :-
    integer(Width),
    integer(Height),
    Width > 0,
    Height > 0,

    retractall(board_width(_)),
    retractall(board_height(_)),
    retractall(mine(_, _)),
    retractall(cell(_, _, _)),
    retractall(game_status(_)),

    assertz(board_width(Width)),
    assertz(board_height(Height)),
    assertz(game_status(running)),

    forall(
        member(X-Y, Mines),
        (
            inside(X, Y),
            assertz(mine(X, Y))
        )
    ),

    forall(
        (
            between(1, Width, X),
            between(1, Height, Y)
        ),
        assertz(cell(X, Y, hidden))
    ),

    forall(
        member(X-Y, InitialOpen),
        open_cell(X, Y)
    ).

%==============================================================================
% Coordinates and neighbours
%==============================================================================
inside(X, Y) :-
    board_width(W),
    board_height(H),
    between(1, W, X),
    between(1, H, Y).

neighbour(X, Y, NX, NY) :-
    DX = [-1, 0, 1],
    DY = [-1, 0, 1],
    member(DX0, DX),
    member(DY0, DY),
    (DX0 \= 0 ; DY0 \= 0),
    NX is X + DX0,
    NY is Y + DY0,
    inside(NX, NY).

neighbours(X, Y, Positions) :-
    findall(
        NX-NY,
        neighbour(X, Y, NX, NY),
        Positions
    ).

%==============================================================================
% Game operations
%==============================================================================
open_cell(X, Y) :-
    game_status(running),
    cell(X, Y, hidden),
    !,
    (
        mine(X, Y)
    ->
        retract(cell(X, Y, hidden)),
        assertz(cell(X, Y, exploded)),
        retractall(game_status(_)),
        assertz(game_status(lost))
    ;
        adjacent_mine_count(X, Y, Count),

        retract(cell(X, Y, hidden)),
        assertz(cell(X, Y, open(Count))),

        (
            Count =:= 0
        ->
            neighbours(X, Y, Neighbours),
            forall(
                member(NX-NY, Neighbours),
                open_cell(NX, NY)
            )
        ;
            true
        ),

        check_win
    ).

open_cell(_, _).

flag_cell(X, Y) :-
    game_status(running),
    cell(X, Y, hidden),
    !,
    retract(cell(X, Y, hidden)),
    assertz(cell(X, Y, flagged)).

flag_cell(_, _).

unflag_cell(X, Y) :-
    cell(X, Y, flagged),
    !,
    retract(cell(X, Y, flagged)),
    assertz(cell(X, Y, hidden)).

unflag_cell(_, _).

adjacent_mine_count(X, Y, Count) :-
    neighbours(X, Y, Neighbours),
    findall(
        X1-Y1,
        (
            member(X1-Y1, Neighbours),
            mine(X1, Y1)
        ),
        Mines
    ),
    length(Mines, Count).

adjacent_flag_count(X, Y, Count) :-
    neighbours(X, Y, Neighbours),
    findall(
        X1-Y1,
        (
            member(X1-Y1, Neighbours),
            cell(X1, Y1, flagged)
        ),
        Flags
    ),
    length(Flags, Count).

hidden_neighbours(X, Y, Hidden) :-
    neighbours(X, Y, Neighbours),
    include(hidden_position, Neighbours, Hidden).

hidden_position(X-Y) :-
    cell(X, Y, hidden).

check_win :-
    \+ cell(_, _, hidden),
    retractall(game_status(_)),
    assertz(game_status(won)),
    !.

check_win.

%==============================================================================
% Print the board in ASCII
%==============================================================================
print_board :-
    print_board(false).

print_board(RevealMines) :-
    board_width(W),
    board_height(H),

    nl,
    write('    '),
    forall(
        between(1, W, X),
        format('~|~`0t~d~2+ ', [X])
    ),
    nl,

    write('   +'),
    forall(between(1, W, _), write('---+')),
    nl,

    print_rows(H, W, RevealMines),

    game_status(Status),
    format('Status: ~w~n', [Status]),
    nl.

print_rows(0, _, _).

print_rows(Y, W, RevealMines) :-
    Y > 0,

    format('~|~`0t~d~2+ |', [Y]),
    print_cells(1, Y, W, RevealMines),
    nl,

    write('   +'),
    forall(between(1, W, _), write('---+')),
    nl,

    Y2 is Y - 1,
    print_rows(Y2, W, RevealMines).

print_cells(X, _, W, _) :-
    X > W,
    !.

print_cells(X, Y, W, RevealMines) :-
    display_cell(X, Y, RevealMines, Character),
    format(' ~w |', [Character]),
    X2 is X + 1,
    print_cells(X2, Y, W, RevealMines).

display_cell(X, Y, _, '*') :-
    cell(X, Y, exploded),
    !.

display_cell(X, Y, true, '*') :-
    mine(X, Y),
    cell(X, Y, hidden),
    !.

display_cell(X, Y, _, 'F') :-
    cell(X, Y, flagged),
    !.

display_cell(X, Y, _, Number) :-
    cell(X, Y, open(Number)),
    !.

display_cell(_, _, _, '#').

%==============================================================================
% Probabilistic solver
%==============================================================================
solve :-
    solve(200).

solve(MaxSteps) :-
    format('Starting probabilistic solver.~n'),
    print_board,
    solve_loop(0, MaxSteps).

solve_loop(Step, _) :-
    game_status(Status),
    Status \= running,
    format('Game finished: ~w~n', [Status]),
    print_board(true),
    !.

solve_loop(Step, MaxSteps) :-
    Step >= MaxSteps,
    format('Maximum number of steps reached: ~d~n', [MaxSteps]),
    print_board,
    !.

solve_loop(Step, MaxSteps) :-
    calculate_probabilities(Probabilities),

    (
        Probabilities = []
    ->
        format('No hidden cells remain.~n'),
        check_win
    ;
        choose_move(Probabilities, Move),
        perform_move(Move),
        format_move(Step, Move),
        print_board,
        Step2 is Step + 1,
        solve_loop(Step2, MaxSteps)
    ).

perform_move(flag(X, Y)) :-
    flag_cell(X, Y).

perform_move(open(X, Y)) :-
    open_cell(X, Y).

format_move(Step, flag(X, Y)) :-
    format('Step ~d: flagging (~d,~d)~n', [Step, X, Y]).

format_move(Step, open(X, Y)) :-
    format('Step ~d: opening (~d,~d)~n', [Step, X, Y]).

%==============================================================================
% Choosing a move
%==============================================================================
choose_move(Probabilities, flag(X, Y)) :-
    member(probability(1.0, X, Y), Probabilities),
    !.

choose_move(Probabilities, open(X, Y)) :-
    member(probability(0.0, X, Y), Probabilities),
    !.

choose_move(Probabilities, open(X, Y)) :-
    sort_probabilities(Probabilities, Sorted),
    Sorted = [probability(_, X, Y)|_].

sort_probabilities(Probabilities, Sorted) :-
    predsort(compare_probability, Probabilities, Sorted).

compare_probability(Order,
                    probability(P1, X1, Y1),
                    probability(P2, X2, Y2)) :-
    compare(P, P1, P2),
    (
        P \= (=)
    ->
        Order = P
    ;
        compare(XOrder, X1, X2),
        (
            XOrder \= (=)
        ->
            Order = XOrder
        ;
            compare(Order, Y1, Y2)
        )
    ).

%==============================================================================
% Probability calculation
%==============================================================================
calculate_probabilities(Probabilities) :-
    hidden_cells(Hidden),
    Hidden \= [],
    frontier_cells(Frontier),

    length(Frontier, FrontierSize),

    (
        Frontier = []
    ->
        fallback_probabilities(Hidden, Probabilities)
    ;
        FrontierSize =< 18
    ->
        enumerate_frontier(Frontier, Assignments),
        (
            Assignments = []
        ->
            fallback_probabilities(Hidden, Probabilities)
        ;
            probabilities_from_assignments(
                Hidden,
                Frontier,
                Assignments,
                Probabilities
            )
        )
    ;
        format(
            'Frontier has ~d cells; using local probabilities.~n',
            [FrontierSize]
        ),
        local_probabilities(Hidden, Probabilities)
    ).

fallback_probabilities(Hidden, Probabilities) :-
    total_mines(TotalMines),
    flagged_count(Flagged),
    length(Hidden, HiddenCount),

    RemainingMines is TotalMines - Flagged,
    Probability is RemainingMines / HiddenCount,

    findall(
        probability(Probability, X, Y),
        member(X-Y, Hidden),
        Probabilities
    ).

local_probabilities(Hidden, Probabilities) :-
    findall(
        probability(Probability, X, Y),
        (
            member(X-Y, Hidden),
            local_cell_probability(X, Y, Probability)
        ),
        Probabilities
    ).

local_cell_probability(X, Y, Probability) :-
    findall(
        Clue-Ratio,
        (
            neighbour(X, Y, NX, NY),
            cell(NX, NY, open(Clue)),
            adjacent_flag_count(NX, NY, Flags),
            hidden_neighbours(NX, NY, Hidden),
            length(Hidden, HiddenCount),

            Remaining is Clue - Flags,

            (
                HiddenCount > 0
            ->
                Ratio is Remaining / HiddenCount
            ;
                Ratio = 1.0
            )
        ),
        Estimates
    ),

    (
        Estimates = []
    ->
        Probability = 0.5
    ;
        findall(Ratio, member(_-Ratio, Estimates), Ratios),
        sum_list(Ratios, Sum),
        length(Ratios, Count),
        Probability0 is Sum / Count,
        Probability is max(0.0, min(1.0, Probability0))
    ).

hidden_cells(Hidden) :-
    findall(
        X-Y,
        cell(X, Y, hidden),
        Hidden
    ).

frontier_cells(Frontier) :-
    findall(
        X-Y,
        (
            cell(CX, CY, open(_)),
            hidden_neighbours(CX, CY, Hidden),
            member(X-Y, Hidden)
        ),
        Frontier0
    ),
    sort(Frontier0, Frontier).

flagged_count(Count) :-
    findall(X-Y, cell(X, Y, flagged), Flags),
    length(Flags, Count).

total_mines(Count) :-
    findall(X-Y, mine(X, Y), Mines),
    length(Mines, Count).

%==============================================================================
% Enumerating legal mine assignments
%==============================================================================
enumerate_frontier(Frontier, Assignments) :-
    findall(
        Assignment,
        (
            binary_assignment(Frontier, Assignment),
            assignment_satisfies_clues(Assignment)
        ),
        Assignments
    ).

binary_assignment([], []).

binary_assignment([Position|Rest], Assignment) :-
    (
        Assignment = [Position|Tail]
    ;
        Assignment = Tail
    ),
    binary_assignment(Rest, Tail).

assignment_satisfies_clues(Assignment) :-
    forall(
        cell(X, Y, open(Number)),
        clue_is_satisfied(X, Y, Number, Assignment)
    ).

clue_is_satisfied(X, Y, Number, Assignment) :-
    neighbours(X, Y, Neighbours),
    count_assigned_mines(Neighbours, Assignment, Count),
    adjacent_flag_count(X, Y, FlagCount),
    Required is Number - FlagCount,
    Count =:= Required.

count_assigned_mines([], _, 0).

count_assigned_mines([Position|Rest], Assignment, Count) :-
    count_assigned_mines(Rest, Assignment, RestCount),
    (
        memberchk(Position, Assignment)
    ->
        Count is RestCount + 1
    ;
        Count = RestCount
    ).

%==============================================================================
% Converting assignments into probabilities
%==============================================================================
probabilities_from_assignments(
    Hidden,
    Frontier,
    Assignments,
    Probabilities
) :-
    length(Assignments, AssignmentCount),

    findall(
        probability(Probability, X, Y),
        (
            member(X-Y, Hidden),
            mine_probability(
                X-Y,
                Frontier,
                Assignments,
                AssignmentCount,
                Probability
            )
        ),
        Probabilities
    ).

mine_probability(
    Position,
    Frontier,
    Assignments,
    AssignmentCount,
    Probability
) :-
    (
        memberchk(Position, Frontier)
    ->
        count_assignments_containing(Position, Assignments, MineCount),
        Probability is MineCount / AssignmentCount
    ;
        unobserved_probability(
            Position,
            Assignments,
            AssignmentCount,
            Probability
        )
    ).

count_assignments_containing(_, [], 0).

count_assignments_containing(Position, [Assignment|Rest], Count) :-
    count_assignments_containing(Position, Rest, RestCount),
    (
        memberchk(Position, Assignment)
    ->
        Count is RestCount + 1
    ;
        Count = RestCount
    ).

unobserved_probability(
    _Position,
    Assignments,
    AssignmentCount,
    Probability
) :-
    total_mines(TotalMines),
    flagged_count(Flagged),
    remaining_mines_from_assignments(
        Assignments,
        AssignmentMineCounts
    ),
    sum_list(AssignmentMineCounts, SumAssigned),
    AverageAssigned is SumAssigned / AssignmentCount,
    Remaining is TotalMines - Flagged - AverageAssigned,

    unconstrained_hidden_count(Count),
    (
        Count > 0
    ->
        Probability is max(0.0, min(1.0, Remaining / Count))
    ;
        Probability = 1.0
    ).

remaining_mines_from_assignments([], []).

remaining_mines_from_assignments([Assignment|Rest], [Count|Counts]) :-
    length(Assignment, Count),
    remaining_mines_from_assignments(Rest, Counts).

unconstrained_hidden_count(Count) :-
    hidden_cells(Hidden),
    frontier_cells(Frontier),
    subtract(Hidden, Frontier, Unconstrained),
    length(Unconstrained, Count).

%==============================================================================
% Test launcher
%==============================================================================
run_tests :-
    ensure_loaded('test1.pl'),
    ensure_loaded('test2.pl'),
    ensure_loaded('test3.pl'),
    test1,
    test2,
    test3.

%==============================================================================
% EOF
%==============================================================================
