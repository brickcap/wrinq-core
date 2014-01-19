-module(wrinq_app).
-behaviour(application).


-export([start/2]).
-export([stop/1]).

start(_Type, _Args) ->
    {ok,C} = eredis:start_link(),
    Dispatch = cowboy_router:compile(wrinq_routes:routes_configuration(C)),
    {ok, _} = cowboy:start_http(http, 100, [{port, 4000}],
				[{env, [{dispatch, Dispatch}]}]),
    pg2:start(),   
    gen_event:start({global,wrinq_channel_events}),
    gen_event:add_handler({global,wrinq_channel_events},wrinq_event_handler,[C]),
    wrinq_sup:start_link().

stop(_State) ->
    ok.
