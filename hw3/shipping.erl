-module(shipping).
-compile(export_all).
-include_lib("./shipping.hrl").


get_ship_helper(Ships, Ship_ID) ->
    case Ships of
        [] -> error;
        [Ship | _Other_Ships] when (Ship#ship.id)==Ship_ID -> Ship;
        [_Ship | Other_Ships] -> get_ship_helper(Other_Ships, Ship_ID);
        _Else -> error
    end.

get_ship(Shipping_State, Ship_ID) ->
    % maps:find()
    case get_ship_helper(Shipping_State#shipping_state.ships, Ship_ID) of
        error -> throw(error);
        Ship -> Ship
    end.

get_container_helper(Containers, Container_ID) ->
    case Containers of
        [] -> error;
        [Container | _Other_Containers] when (Container#container.id)==Container_ID -> Container;
        [_Container | Other_Containers] -> get_container_helper(Other_Containers, Container_ID);
        _Else -> error
    end.

get_container(Shipping_State, Container_ID) ->
    case get_container_helper(Shipping_State#shipping_state.containers, Container_ID) of
        error -> throw(error);
        Container -> Container
    end.

get_port(Shipping_State, Port_ID) ->
    case get_port_helper(Shipping_State#shipping_state.ports, Port_ID) of
        error -> throw(error);
        Port -> Port
    end.

get_occupied_docks(Shipping_State, Port_ID) ->
    lists:foldl(
        fun(X, Y) ->
            case X of
                {Pid, Dock, _} when Pid==Port_ID -> [Dock|Y];
                _ -> Y
            end
        end, [], (Shipping_State#shipping_state.ship_locations)).

get_ship_location(Shipping_State, Ship_ID) ->
    case lists:keyfind(Ship_ID, 3, Shipping_State#shipping_state.ship_locations) of
        false -> throw(error);
        {Pid, Did, _Sid} -> {Pid, Did}
    end.


get_container_weight_singular(Shipping_State, Container_ID) ->
    case lists:keyfind(Container_ID, #container.id, Shipping_State#shipping_state.containers) of
        #container{weight = Weight} -> Weight;
        false -> error
    end.

get_container_weight(Shipping_State, Container_IDs) ->
    lists:foldl(
        fun(X, Acc) ->
            case get_container_weight_singular(Shipping_State, X) of
                error -> throw(error);
                Weight -> Acc + Weight
            end
        end, 0, Container_IDs).

get_ship_weight(Shipping_State, Ship_ID) ->
    case maps:find(Ship_ID, Shipping_State#shipping_state.ship_inventory) of
        {ok, Container_IDs} -> get_container_weight(Shipping_State, Container_IDs);
        error -> throw(error)
    end.

load_ship(Shipping_State, Ship_ID, Container_IDs) ->
    {Pid, _Did} = get_ship_location(Shipping_State, Ship_ID),
    Ship = get_ship(Shipping_State, Ship_ID),
    case maps:find(Pid, Shipping_State#shipping_state.port_inventory) of
        {ok, _Port_Inventory} ->
            lists:foldl(
                fun(Container_ID, A) ->
                    {ok, Port_Inventory} = maps:find(Pid, A#shipping_state.port_inventory),
                    case lists:member(Container_ID, Port_Inventory) of
                        true ->
                            {ok, Ship_Inventory} = maps:find(Ship_ID, A#shipping_state.ship_inventory),
                            New_Ship_Inventory = maps:put(Ship_ID, [Container_ID | Ship_Inventory], maps:remove(Ship_ID, A#shipping_state.ship_inventory)),
                            New_Port_Inventory = maps:put(Pid, lists:delete(Container_ID, Port_Inventory), maps:remove(Pid, A#shipping_state.port_inventory)),
                            if
                                length(New_Ship_Inventory) > Ship#ship.container_cap -> throw(error);
                                true -> A#shipping_state{ship_inventory = New_Ship_Inventory, port_inventory = New_Port_Inventory}
                            end;
                        false -> throw(error)
                    end
                end, Shipping_State, Container_IDs);
        error -> throw(error)
    end.

unload_ship_all(Shipping_State, Ship_ID) ->
    case maps:find(Ship_ID, Shipping_State#shipping_state.ship_inventory) of
        {ok, Container_IDs} -> unload_ship(Shipping_State, Ship_ID, Container_IDs);
        error -> throw(error)
    end.

unload_ship(Shipping_State, Ship_ID, Container_IDs) ->
    {Pid, _Did} = get_ship_location(Shipping_State, Ship_ID),
    Port = get_port(Shipping_State, Pid),
    case maps:find(Ship_ID, Shipping_State#shipping_state.ship_inventory) of
        {ok, _Ship_Inventory} ->
            lists:foldl(
                fun(Container_ID, A) -> 
                    {ok, Ship_Inventory} = maps:find(Ship_ID, A#shipping_state.ship_inventory),
                    case lists:member(Container_ID, Ship_Inventory) of
                        true -> 
                            {ok, Port_Inventory} = maps:find(Pid, A#shipping_state.port_inventory),
                            New_Port_Inventory = maps:put(Pid, [Container_ID | Port_Inventory], maps:remove(Container_ID, A#shipping_state.port_inventory)),
                            New_Ship_Inventory = maps:put(Ship_ID, lists:delete(Container_ID, Ship_Inventory), maps:remove(Ship_ID, A#shipping_state.ship_inventory)),
                        if
                            length(New_Port_Inventory) > Port#port.container_cap -> throw(error);
                            true -> A#shipping_state{ship_inventory = New_Ship_Inventory, port_inventory = New_Port_Inventory}
                        end;
                        false -> throw(error)
                    end
                end, Shipping_State, Container_IDs);
        error -> throw(error)
    end.

set_sail(Shipping_State, Ship_ID, {Port_ID, Dock}) ->
    case lists:member(Dock, get_occupied_docks(Shipping_State, Port_ID)) of
        false ->
            Locations = Shipping_State#shipping_state.ship_locations,
            {Old_Pid, Old_Did} = get_ship_location(Shipping_State, Ship_ID), 
            Shipping_State#shipping_state{ship_locations = [{Port_ID, Dock, Ship_ID} | lists:delete({Old_Pid, Old_Did, Ship_ID}, Locations)]};
        true -> throw(error)
    end.


%% Determines whether all of the elements of Sub_List are also elements of Target_List
%% @returns true is all elements of Sub_List are members of Target_List; false otherwise
is_sublist(Target_List, Sub_List) ->
    lists:all(fun (Elem) -> lists:member(Elem, Target_List) end, Sub_List).




%% Prints out the current shipping state in a more friendly format
print_state(Shipping_State) ->
    io:format("--Ships--~n"),
    _ = print_ships(Shipping_State#shipping_state.ships, Shipping_State#shipping_state.ship_locations, Shipping_State#shipping_state.ship_inventory, Shipping_State#shipping_state.ports),
    io:format("--Ports--~n"),
    _ = print_ports(Shipping_State#shipping_state.ports, Shipping_State#shipping_state.port_inventory).


%% helper function for print_ships
get_port_helper([], _Port_ID) -> error;
get_port_helper([ Port = #port{id = Port_ID} | _ ], Port_ID) -> Port;
get_port_helper( [_ | Other_Ports ], Port_ID) -> get_port_helper(Other_Ports, Port_ID).


print_ships(Ships, Locations, Inventory, Ports) ->
    case Ships of
        [] ->
            ok;
        [Ship | Other_Ships] ->
            {Port_ID, Dock_ID, _} = lists:keyfind(Ship#ship.id, 3, Locations),
            Port = get_port_helper(Ports, Port_ID),
            {ok, Ship_Inventory} = maps:find(Ship#ship.id, Inventory),
            io:format("Name: ~s(#~w)    Location: Port ~s, Dock ~s    Inventory: ~w~n", [Ship#ship.name, Ship#ship.id, Port#port.name, Dock_ID, Ship_Inventory]),
            print_ships(Other_Ships, Locations, Inventory, Ports)
    end.

print_containers(Containers) ->
    io:format("~w~n", [Containers]).

print_ports(Ports, Inventory) ->
    case Ports of
        [] ->
            ok;
        [Port | Other_Ports] ->
            {ok, Port_Inventory} = maps:find(Port#port.id, Inventory),
            io:format("Name: ~s(#~w)    Docks: ~w    Inventory: ~w~n", [Port#port.name, Port#port.id, Port#port.docks, Port_Inventory]),
            print_ports(Other_Ports, Inventory)
    end.
%% This functions sets up an initial state for this shipping simulation. You can add, remove, or modidfy any of this content. This is provided to you to save some time.
%% @returns {ok, shipping_state} where shipping_state is a shipping_state record with all the initial content.
shipco() ->
    Ships = [#ship{id=1,name="Santa Maria",container_cap=20},
              #ship{id=2,name="Nina",container_cap=20},
              #ship{id=3,name="Pinta",container_cap=20},
              #ship{id=4,name="SS Minnow",container_cap=20},
              #ship{id=5,name="Sir Leaks-A-Lot",container_cap=20}
             ],
    Containers = [
                  #container{id=1,weight=200},
                  #container{id=2,weight=215},
                  #container{id=3,weight=131},
                  #container{id=4,weight=62},
                  #container{id=5,weight=112},
                  #container{id=6,weight=217},
                  #container{id=7,weight=61},
                  #container{id=8,weight=99},
                  #container{id=9,weight=82},
                  #container{id=10,weight=185},
                  #container{id=11,weight=282},
                  #container{id=12,weight=312},
                  #container{id=13,weight=283},
                  #container{id=14,weight=331},
                  #container{id=15,weight=136},
                  #container{id=16,weight=200},
                  #container{id=17,weight=215},
                  #container{id=18,weight=131},
                  #container{id=19,weight=62},
                  #container{id=20,weight=112},
                  #container{id=21,weight=217},
                  #container{id=22,weight=61},
                  #container{id=23,weight=99},
                  #container{id=24,weight=82},
                  #container{id=25,weight=185},
                  #container{id=26,weight=282},
                  #container{id=27,weight=312},
                  #container{id=28,weight=283},
                  #container{id=29,weight=331},
                  #container{id=30,weight=136}
                 ],
    Ports = [
             #port{
                id=1,
                name="New York",
                docks=['A','B','C','D'],
                container_cap=200
               },
             #port{
                id=2,
                name="San Francisco",
                docks=['A','B','C','D'],
                container_cap=200
               },
             #port{
                id=3,
                name="Miami",
                docks=['A','B','C','D'],
                container_cap=200
               }
            ],
    %% {port, dock, ship}
    Locations = [
                 {1,'B',1},
                 {1, 'A', 3},
                 {3, 'C', 2},
                 {2, 'D', 4},
                 {2, 'B', 5}
                ],
    Ship_Inventory = #{
      1=>[14,15,9,2,6],
      2=>[1,3,4,13],
      3=>[],
      4=>[2,8,11,7],
      5=>[5,10,12]},
    Port_Inventory = #{
      1=>[16,17,18,19,20],
      2=>[21,22,23,24,25],
      3=>[26,27,28,29,30]
     },
    #shipping_state{ships = Ships, containers = Containers, ports = Ports, ship_locations = Locations, ship_inventory = Ship_Inventory, port_inventory = Port_Inventory}.
