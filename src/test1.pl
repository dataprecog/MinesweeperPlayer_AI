:- use_module(minesweeper).

test1 :-
    format('~n================ TEST 1 ================~n'),

    new_game(
        6,
        6,
        [
            2-2,
            5-2,
            4-4,
            1-6
        ],
        [
            6-1
        ]
    ),

    print_board,
    solve,

    game_status(Status),
    format('Test 1 final result: ~w~n', [Status]),
    print_board(true).
