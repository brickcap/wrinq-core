-module(wrinq_create_user).

-export([init/3]).
-export([handle/2]).
-export([terminate/3]).

init(_Transport, Req, [C]) ->
	{ok, Req, C}.

handle(Req, State) ->
	{Method, Req2} = cowboy_req:method(Req),
	HasBody = cowboy_req:has_body(Req2),
	{ok, Req3} = handle_post(Method, HasBody, Req2,State),
	{ok, Req3, State}.

handle_post(<<"POST">>, true, Req,State) ->
    {ok,PostVals, Req2} = cowboy_req:body_qs(Req),
    create_user(PostVals,Req2,State);

handle_post(<<"POST">>, false, Req,_) ->
	cowboy_req:reply(400, [], <<"Missing body.">>, Req);

handle_post(_, _, Req,_) ->
    cowboy_req:reply(405, Req).

create_user(Details,Req,State)->
    User_Name = proplists:get_value(<<"username">>,Details),
    Password = proplists:get_value(<<"password">>,Details),
    UUID =  uuid:to_string(uuid:uuid1()),
    UB = erlang:list_to_binary(UUID),
    Data = jiffy:encode({[{n,User_Name},{p,Password},{id,UB}]}),
    Check = wrinq_check_user:check_user(User_Name,State),
    P = jiffe:encode({[{UB,User_Name}]})
    case Check of
	true->
	    eredis:q(State,["SET",UUID,User_Name]),
	    eredis:q(State,["HSET",User_Name,<<"p">>,Data]),	    
	    cowboy_req:reply(200,[],P,Req);
	false-> cowboy_req:reply(404, Req)
    end.
 


terminate(_Reason, _Req, _State) ->
    ok.
