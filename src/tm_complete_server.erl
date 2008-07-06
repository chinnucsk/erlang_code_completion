-module (tm_complete_server).
-export([start/0]).

start() ->
    {ok, Listen} = gen_tcp:listen(2345, [list, {packet, line},
                                         {reuseaddr, true},
                                         {active, true}]),
    spawn(fun() -> par_connect(Listen) end).

par_connect(Listen) ->
    {ok, Socket} = gen_tcp:accept(Listen),
    spawn(fun() -> par_connect(Listen) end),
    complete(Socket).

complete(Socket) ->
    receive
        {tcp, Socket, Module} ->
            gen_tcp:send(tm_complete:string(module(Module), string(Socket)));
        _ -> ok
    end.

module(Module) ->
    {ok, Trimmed, _} = regexp:gsub(Module, "[\r\n]", ""),
    list_to_atom(Trimmed).

string(Socket) ->
    receive
        {tcp, Socket, [$\f|_]} -> [];
        {tcp, Socket, Line} -> [Line|string(Socket)];
        _ -> []
    end.