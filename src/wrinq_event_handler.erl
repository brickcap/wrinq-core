-module(wrinq_event_handler).

-export([init/1]).
-export([handle_event/2]).
-export([handle_call/2,terminate/2,handle_info/2,code_change/3]).

-behaviour(gen_event).

init([Client])->
    {ok,Client}.

handle_event({send_message,Multi_Channels,Multi_Msg},State) when is_list(Multi_Channels) ->  

    lists:foreach( 
      fun(N)->
	      Member = pg2:get_members(N),
	      lager:info("Sending message to",[{N, Member}]),
	      case Member of
		  [Pid|_]-> 

		      Pid!{send,Multi_Msg};
		  {error,_}-> lager:info("Unavailable~p",N)
	      end
      end,
      Multi_Channels),
    {ok,State};

handle_event({send_message,Send_to,Sent_From,Msg},State)->

    {{Year,Month,Day},{Hour,Min,Sec}} = erlang:localtime(),

    Packet = {[{<<"m">>,Msg},
	       {<<"year">>,Year},{<<"month">>,Month},{<<"day">>,Day},
	       {<<"hour">>,Hour},{<<"min">>,Min},{<<"sec">>,Sec},
	       {<<"f">>,Sent_From}]},

    Member = pg2:get_members(Send_to),
    erlang:display([Member]),
    case Member of
	{error,_}->
	    wrinq_redis_ops:add_message(Send_to,Packet,State);

	[Pid|_] ->	   
	    erlang:display(["sending message"]),
	    Pid!{send,Packet}
    end,
    {ok,State};

handle_event({subscribe,Multi_Subscribe_To,Subscribers},State) when is_list(Subscribers) ->

    Subscriber_Channel = wrinq_helpers:subscriber_channel_name(Multi_Subscribe_To), 
    Member = pg2:get_members(Subscriber_Channel), 
    case Member of 
	{error,_}->
	    pg2:create(Subscriber_Channel),
	    wrinq_helpers:add_subscribers(Subscriber_Channel,Subscribers);
	_->
	    wrinq_helpers:add_subscribers(Subscriber_Channel,Subscribers) 
    end,
    [G|_]= pg2:get_members(Multi_Subscribe_To),
    G!{send,{[{<<"subcribed">>,<<"ok">>}]}},
    {ok,State};

handle_event({ret,Of},State)->
    Member = pg2:get_members(Of),
    case Member of
	{error,_}->
    	    ok;
    	[Pid|_]->
	    A = wrinq_redis_ops:ret_message(Of,State),
	    case A of
		{ok,M}->
		    Messages = {[{<<"msgs">>,M}]},
		    Pid ! {send,Messages};		
		{error,_}-> ok
	    end
    end,
    {ok,State};

handle_event({del,Of},State)->
    wrinq_redis_ops:del_messages(Of,State),
    {ok,State};


handle_event({publish,Publish_Msg,Publishing_Channel},State)->

    Member = pg2:get_members(wrinq_helpers:subscriber_channel_name(Publishing_Channel)),
    case Member of 
	[M|O]->
	    [Pid!{send,Publish_Msg}||Pid<-[M|O]];
	{error,_}-> lager:info("unavailable")
    end,
    {ok,State}.


handle_call(_, State) ->
    {ok, ok, State}.

handle_info(_, State) ->
    {ok, State}.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

terminate(_Reason, _State) ->
    ok.
