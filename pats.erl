-module(pats).
-compile(export_all).
-compile(nowarn_export_all).

start(P, J) ->
    S = spawn(?MODULE, server, [0, false]),
    [spawn(?MODULE, pats, [S]) || _ <- lists:seq(1, P)],
    [spawn(?MODULE, jets, [S]) || _ <- lists:seq(1, J)],
    timer:sleep(10000),
    S!{itGotLate}.



pats(S) ->
    S!{pats}.

jets(S) ->
    S!{self(), jets},
    receive
        {ok} -> ok
    end.

flush_and_notify() ->
    receive
        {From, jets} -> From!{ok},
        flush_and_notify();
        _ -> flush_and_notify()
    after 0 ->
        ok
    end.

server(Delta, false) ->
    receive
        {pats} -> server(Delta+1, false);
        {From, jets} when Delta > 1 ->
            From!{ok},
            server(Delta - 2, false);
        {itGotLate} -> 
            flush_and_notify(),
            server(Delta, true)
    end;
server(Delta, true) ->
    receive
        {pats} -> server(Delta, true);
        {From, jets} ->
            From!{ok},
            server(Delta, true)
    end.