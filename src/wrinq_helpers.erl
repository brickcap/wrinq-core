-module(wrinq_helpers).

-export([channel_event_notifier/1]).
-export([subscriber_channel_name/1]).
-export([add_subscribers/2]).
-export([sanatize_name/1]).
-export([sanatize_name_to_string/1]).

subscriber_channel_name(Name)->
    <<Name/binary,<<"_subscribers">>/binary>>.

channel_event_notifier(Name)->
    Event_Pid = global:whereis_name(wrinq_channel_events),   
    gen_event:notify(Event_Pid,Name).

add_subscribers(Subscriber_Channel,Subscribers)->
    lists:foreach(
      fun(N)->
	      Member_pids = pg2:get_members(N),
	      case Member_pids of
		  [Pid|_]->
		      pg2:join(Subscriber_Channel,Pid),
		      Pid! subscribed;
		  {error,_} -> lager:info("Unavailable")
	      end
      end,Subscribers).

sanatize_name(Name)->
     Quote = <<"\"">>,
  <<Quote/binary,Name/binary,Quote/binary>>.

sanatize_name_to_string(Name)->
    Sname = sanatize_name(Name),
    erlang:binary_to_list(Sname).
