%%% Stub for Quiz 6
%%Jason Qiu and Britney Yang

-module(calc).
-compile(nowarn_export_all).
-compile(export_all).

env() -> #{"x"=>3, "y"=>7}. %% Sample environment

e1() -> %% Sample calculator expression
    {add, 
     {const,3},
     {divi,
      {var,"x"},
      {const,4}}}.

e2() -> %% Sample calculator expression
    {add, 
     {const,3},
     {divi,
      {var,"x"},
      {const,0}}}.

e3() -> %% Sample calculator expression
    {add, 
     {const,3},
     {divi,
      {var,"r"},
      {const,4}}}.

eval({const,N},_E) ->
    N;

eval({var,Id},E) ->
    try
    {ok, X} = maps:find(Id, E),
    X
    catch
        _:_ -> throw(unbound_identifier_error)
    end;
    % if
    %     EE==ok -> X;
    %     EE==error -> throw(unbound_identifier_error);
    %     true -> throw(error)
    % end;

eval({add,E1,E2},E) ->
    try
    X = eval(E1, E),
    Y = eval(E2, E),
    X+Y
    catch
        _:unbound_identifier_error -> throw(unbound_identifier_error);
        _:division_by_zero_error -> throw(division_by_zero_error)
    end;

eval({sub,E1,E2},E) ->
    try
    X = eval(E1, E),
    Y = eval(E2, E),
    X-Y
    catch
        _:unbound_identifier_error -> throw(unbound_identifier_error);
        _:division_by_zero_error -> throw(division_by_zero_error)
    end;

eval({mult,E1,E2},E) ->
    try
    X = eval(E1, E),
    Y = eval(E2, E),
    X*Y
    catch
        _:unbound_identifier_error -> throw(unbound_identifier_error);
        _:division_by_zero_error -> throw(division_by_zero_error)
    end;

eval({divi,E1,E2},E) ->
    try
    X = eval(E1, E),
    Y = eval(E2, E),
    if Y==0 -> throw(division_by_zero_error);
    true -> X div Y
    end
    catch
        _:unbound_identifier_error -> throw(unbound_identifier_error);
        _:division_by_zero_error -> throw(division_by_zero_error)
    end.


