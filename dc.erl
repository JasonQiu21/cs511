-module(dc).
-compile(export_all).
-compile(no_warn_export_all).

% Jackey Yang and Jason Qiu
% I pledge my honor that I have abided by the Stevens Honor System.

dryCleanerLoop(Clean, Dirty) ->
    receive
        {dropOffOverall} ->
            receive
                {From, dryCleanItem} -> 
                    From!{ok},
                    dryCleanerLoop(Clean + 1, Dirty)
            after 0 ->
                dryCleanerLoop(Clean, Dirty + 1)
            end;
        {From, pickUpOverall} when Clean > 0 ->
            From!{ok},
            dryCleanerLoop(Clean - 1, Dirty);
        {From, dryCleanItem} when Dirty > 0 ->
            From!{ok},
            dryCleanerLoop(Clean + 1, Dirty - 1)
    end.

employee(DC) ->
    io:format("~p: Dropping off overall\n", [self()]),
    DC!{dropOffOverall},
    DC!{self(), pickUpOverall},
    io:format("~p: Waiting for overall\n", [self()]),
    receive
    {ok} -> ok,
    io:format("~p: Got overall\n", [self()])
    end.

dryCleanMachine(DC) ->
    DC!{self(), dryCleanItem},
    receive
        {ok} -> ok
    end,
    io:format("~p: Cleaning\n", [self()]),
    timer:sleep(1000),
    dryCleanMachine(DC).



start (E , M ) -> % E = no . of employees , M = no . of machines
    DC = spawn (? MODULE , dryCleanerLoop ,[ 0 ,0 ]) ,
    [ spawn (? MODULE , employee ,[ DC ]) || _ <- lists : seq (1 , E ) ] ,
    [ spawn (? MODULE , dryCleanMachine ,[ DC ]) || _ <- lists : seq (1 , M ) ].
