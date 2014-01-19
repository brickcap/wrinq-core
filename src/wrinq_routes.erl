-module(wrinq_routes).

-export([routes_configuration/1]).

routes_configuration(C)->
    [
     {'_', [
	    {"/websocket/:id", wrinq_socket_handler, [C]},
	    {"/createuser",wrinq_create_user,[C]},
	    {"/checkuser",wrinq_check_user,[C]},
	    {"/login",wrinq_login_user,[C]}
	   ]}
    ].
