:- use_module(minesweeper).

test3 :-
    format('~n========== TEST 3 ==========~n'),
    new_game(
        10,
        8,
        [
            2-2,
            5-2,
            8-2,
            3-4,
            7-4,
            1-6,
            5-6,
            9-7
        ],
        [5-4]
    ),
    print_board,
    solve(300),
    game_status(Status),
    format('Test 3 result: ~w~n', [Status]),
    print_board(true).
