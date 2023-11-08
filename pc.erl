-module(pc).
-compile(export_all).
-compile(nowarn_export_all).

start(P, C, N) ->
    B = spawn(?MODULE, buffer, [N, 0, 0, 0]),
    [spawn(?MODULE, producer, [B]) || _ <- lists:seq(1, P)],
    [spawn(?MODULE, consumer, [B]) || _ <- lists:seq(1, C)].



%% N is size of buffer
%% Oc is the numer of occupied slots
%% PSP is the number of producers that have started producing
%% CSC is the number of consumers that have started consuming
buffer(N, Oc, PSP, CSC) ->
    receive
        {From, start_producing} when Oc + PSP < N->
            From!{ok},
            buffer(N, Oc, PSP + 1, CSC);
        {From, start_consuming} when Oc-CSC>0->
            From!{ok},
            buffer(N, Oc, PSP, CSC+1);
        {_From, stop_producing} ->
            buffer(N, Oc+1, PSP-1, CSC);
        {_From, stop_consuming} ->
            buffer(N, Oc-1, PSP, CSC-1)
    end.

producer(B) ->
    B!{self(), start_producing},
    receive
        %% start producing
        {ok} -> ok
    end,
    time:sleep(2000),
    B!{self(), stop_producing}.

consumer(B) ->
    B!{self(), start_consuming},
    receive
        %% start consuming
        {ok} -> ok
    end,
    time:sleep(2000),
    B!{self(), stop_consuming}.