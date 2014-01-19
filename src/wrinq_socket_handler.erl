-module(wrinq_socket_handler).
-behaviour(cowboy_websocket_handler).

-export([init/3]).
-export([websocket_init/3]).
-export([websocket_handle/3]).
-export([websocket_info/3]).
-export([websocket_terminate/3]).

init({tcp, http}, _Req,_Opts) ->
    {upgrade, protocol, cowboy_websocket}.

websocket_init(_TransportName, Req, [C]) ->
    {Id,_} = cowboy_req:binding(id,Req),   
    Tuple =  wrinq_check_user:check_user_by_id(Id,C),
    {Id,Name} = Tuple,
    pg2:create(Name),		   
    pg2:join(Name,self()),
    {ok, Req, Name}.


websocket_handle({text, Msg}, Req, State) ->


    try  jiffy:decode(Msg) of 	 

	 {[{<<"to">>,Multi_Channels},{<<"msg">>,Multi_Message}]} when is_list(Multi_Channels)->
	    True_Channels = lists:delete(State,Multi_Channels),
	    lager:info("The true channels are",[True_Channels]),
	    wrinq_helpers:channel_event_notifier({send_message,True_Channels,Multi_Message}),
	    {ok,Req,State};

	 {[{<<"to">>,Single},{<<"m">>,Single_Msg}]} ->
	    wrinq_helpers:channel_event_notifier({send_message,Single,State,Single_Msg}),
	    {ok,Req,State};    

	 {[{<<"subscribe">>,Subscribe_Channels},{<<"to">>,To}]}-> 

	    True_Channels = lists:delete(State,Subscribe_Channels),
	    wrinq_helpers:channel_event_notifier({subscribe,To,True_Channels}),
	    {ok,Req,State};

	 {[{<<"publish">>,Publish_Msg},{<<"to">>,Pub_Channel}]}->

	    wrinq_helpers: channel_event_notifier({publish,Publish_Msg,Pub_Channel}),
	    {ok,Req,State};

	 {[{<<"ret">>,_}]}->
	    wrinq_helpers: channel_event_notifier({ret,State}),
	    {ok,Req,State};

	 {[{<<"delmsg">>,_}]}->
	    wrinq_helpers:channel_event_notifier({del,State}),
	    {ok,Req,State};
	 _->

	    {reply, {text, jiffy:encode({[{error,<<"invalid packet">>}]})}, Req, State}

    catch
	_:_-> {reply, {text, jiffy:encode({[{error,<<"invalid json">>}]})}, Req, State}

    end;

websocket_handle(_Data, Req, State) ->  
    {ok, Req, State}. 


websocket_info({send,Socket_Send_Msg},Req,State) ->
    {reply,{text,jiffy:encode(Socket_Send_Msg)},Req,State};


websocket_info(subscribed,Req,State)->

    {reply,{text,jiffy:encode({[{status,200}]})},Req,State};


websocket_info(_Info, Req, State) ->

    {ok, Req, State}.

websocket_terminate(_Reason, _Req, _State) ->
    case _State of
	undefined_state->ok;
	_->
	    pg2:delete(_State),
	    pg2:delete(wrinq_helpers:subscriber_channel_name(_State)),
	    ok
    end.

