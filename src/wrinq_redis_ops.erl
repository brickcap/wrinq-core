-module(wrinq_redis_ops).
    
-export([add_message/3]).
-export([ret_message/2]).
-export([del_messages/2]).

add_message(For,Message,Client)->
     eredis:q(Client,
		     ["HSET",For,
		      uuid:to_string(uuid:uuid1()),
		      jiffy:encode(Message)]).

ret_message(Of,Client)->
    {ok,Items} = eredis:q(Client,["HKEYS",Of]),
    Del_items = lists:delete(<<"p">>,Items),
    E = lists:append([Of],Del_items),
    eredis:q(Client,["HMGET"|E]).

del_messages(Of,Client)->
    {ok,Items} = eredis:q(Client,["HKEYS",Of]),
    Del_items = lists:delete(<<"p">>,Items),
    E = lists:append([Of],Del_items),
    eredis:q(Client,["HDEL"|E]).
