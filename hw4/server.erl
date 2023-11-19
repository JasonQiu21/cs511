-module(server).

-export([start_server/0]).

-include_lib("./defs.hrl").

-spec start_server() -> _.
-spec loop(_State) -> _.
-spec do_join(_ChatName, _ClientPID, _Ref, _State) -> _.
-spec do_leave(_ChatName, _ClientPID, _Ref, _State) -> _.
-spec do_new_nick(_State, _Ref, _ClientPID, _NewNick) -> _.
-spec do_client_quit(_State, _Ref, _ClientPID) -> _NewState.

start_server() ->
    catch (unregister(server)),
    register(server, self()),
    case whereis(testsuite) of
        undefined -> ok;
        TestSuitePID -> TestSuitePID ! {server_up, self()}
    end,
    loop(
        #serv_st{
            %% nickname map. client_pid => "nickname"
            nicks = maps:new(),
            %% registration map. "chat_name" => [client_pids]
            registrations = maps:new(),
            %% chatroom map. "chat_name" => chat_pid
            chatrooms = maps:new()
        }
    ).

loop(State) ->
    receive
        %% initial connection
        {ClientPID, connect, ClientNick} ->
            NewState =
                #serv_st{
                    nicks = maps:put(ClientPID, ClientNick, State#serv_st.nicks),
                    registrations = State#serv_st.registrations,
                    chatrooms = State#serv_st.chatrooms
                },
            loop(NewState);
        %% client requests to join a chat
        {ClientPID, Ref, join, ChatName} ->
            NewState = do_join(ChatName, ClientPID, Ref, State),
            loop(NewState);
        %% client requests to join a chat
        {ClientPID, Ref, leave, ChatName} ->
            NewState = do_leave(ChatName, ClientPID, Ref, State),
            loop(NewState);
        %% client requests to register a new nickname
        {ClientPID, Ref, nick, NewNick} ->
            NewState = do_new_nick(State, Ref, ClientPID, NewNick),
            loop(NewState);
        %% client requests to quit
        {ClientPID, Ref, quit} ->
            NewState = do_client_quit(State, Ref, ClientPID),
            loop(NewState);
        {TEST_PID, get_state} ->
            TEST_PID ! {get_state, State},
            loop(State)
    end.

%% executes join protocol from server perspective
do_join(ChatName, ClientPID, Ref, State) ->
    %% Spawn chatroom if doesn't exist
    case maps:find(ChatName, State#serv_st.chatrooms) of
        {ok, ChatPid} ->
            {ok, ClientNick} = maps:find(ClientPID, State#serv_st.nicks),
            ChatPid ! {self(), Ref, register, ClientPID, ClientNick},
            {ok, Regs} = maps:find(ChatName, State#serv_st.registrations),
            State#serv_st{
                registrations = maps:put(
                    ChatName, lists:append(Regs, [ClientPID]), State#serv_st.registrations
                )
            };
        error ->
            ChatPid = spawn(chatroom, start_chatroom, [ChatName]),
            {ok, ClientNick} = maps:find(ClientPID, State#serv_st.nicks),
            ChatPid ! {self(), Ref, register, ClientPID, ClientNick},
            State#serv_st{
                chatrooms = maps:put(ChatName, ChatPid, State#serv_st.chatrooms),
                registrations = maps:put(ChatName, [ClientPID], State#serv_st.registrations)
            }
    end.

%% executes leave protocol from server perspective
do_leave(ChatName, ClientPID, Ref, State) ->
    {ok, Regs} = maps:find(ChatName, State#serv_st.registrations),
    {ok, ChatPid} = maps:find(ChatName, State#serv_st.chatrooms),
    ChatPid ! {self(), Ref, unregister, ClientPID},
    ClientPID ! {self(), Ref, ack_leave},

    State#serv_st{
        registrations = maps:put(
            ChatName, lists:delete(ClientPID, Regs), State#serv_st.registrations
        )
    }.

%% executes new nickname protocol from server perspective
do_new_nick(State, Ref, ClientPID, NewNick) ->
    case lists:member(NewNick, maps:values(State#serv_st.nicks)) of
        true ->
            ClientPID ! {self(), Ref, err_nick_used},
            State;
        false ->
            ClientPID ! {self(), Ref, ok_nick},
            lists:foreach(
                fun(El) ->
                    {ok, Regs} = maps:find(El, State#serv_st.registrations),
                    case lists:member(ClientPID, Regs) of
                        true ->
                            {ok, ChatPid} = maps:find(El, State#serv_st.chatrooms),
                            ChatPid ! {self(), Ref, update_nick, ClientPID, NewNick};
                        false ->
                            ok
                    end
                end,
                maps:keys(State#serv_st.registrations)
            ),
            State#serv_st{
                nicks = maps:put(ClientPID, NewNick, State#serv_st.nicks)
            }
    end.

%% executes client quit protocol from server perspective
do_client_quit(State, Ref, ClientPID) ->
    case maps:find(ClientPID, State#serv_st.registrations) of
        {ok, Chatrooms} ->
            lists:foreach(fun(El) -> El ! {self(), Ref, unregister, ClientPID} end, Chatrooms);
        error ->
            ok
    end,
    ClientPID ! {self(), Ref, ack_quit},
    State#serv_st{
        nicks = maps:remove(ClientPID, State#serv_st.nicks),
        registrations = maps:remove(ClientPID, State#serv_st.registrations)
    }.
