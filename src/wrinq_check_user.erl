-module(wrinq_check_user).

-export([check_user/2,check_user_by_id/2]).
-export([init/3]).
-export([handle/2]).
-export([terminate/3]).



init(_Transport, Req, [C]) ->
	{ok, Req, C}.

handle(Req, State) ->
    {Method, Req2} = cowboy_req:method(Req),
    {Name, Req3} = cowboy_req:qs_val(<<"name">>, Req2),
    {ok, Req4} = handle_get(Method, Name, Req3,State),
    {ok, Req4, State}.

handle_get(<<"GET">>, undefined, Req,_) ->
	cowboy_req:reply(400, [], <<"Missing Get parameter.">>, Req);

handle_get(<<"GET">>, Name, Req,State) ->
    Exists = check_user(Name,State),
    cowboy_req:reply(200, [
			   {<<"content-type">>, <<"application/json">>}
			  ],jiffy:encode({[{<<"available">>,Exists}]}) , Req);

handle_get(_, _, Req,_) ->	
	cowboy_req:reply(405, Req).

check_user(Name,Client)-> 
    {ok,Val} = eredis:q(Client,["EXISTS",Name]),
    case Val of
	<<"0">>->
	    true;
	_ ->
	    false
    end.

check_user_by_id(Id,Client)->
    {ok,Val}= eredis:q(Client,["GET",Id]),
    case Val of 
	undefined ->
	   no;
	_->
	    {Id,Val}
    end.

terminate(_Reason, _Req, _State) ->
    ok.
