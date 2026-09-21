:- use_module(minesweeper).

test2 :-
    format('~n========== TEST 2 ==========~n'),
    new_game(
        8,
        5,
        [2-2, 5-1, 7-2, 3-4, 6-5],
        [1-1, 4-3, 8-5]
    ),
    print_board,
    solve(200),
    game_status(Status),
    format('Test 2 result: ~w~n', [Status]),
    print_board(true).
