%% Author: dimitry
%% Created: 29.06.2011
%% Description: TODO: Add description to st_web_control_tests
-module(st_web_control_tests).
-include_lib("eunit/include/eunit.hrl").
-export([]).



main_test_() ->
	{foreach,
     fun setup/0,
     fun cleanup/1,
     [
      fun check_server_status/1,
	  fun add_delete_sites/1,
	  fun check_cookies/1
     ]}.

setup() -> 
	application:start(site_stater),
	ok.

cleanup (_) ->
	application:stop(site_stater).


check_server_status(_) ->
 	inets:start(),
	{ok, {{Version, Code, ReasonPhrase}, Headers, Body}} =
      httpc:request("http://localhost:8000/server/"),
	?_assertEqual(200, Code).

add_delete_sites(_) ->
	inets:start(),
	{ok, {{_, Code, _}, _, Body}} =
      httpc:request("http://localhost:8000/sites/?action=add_site&site=http://ag.ru"),
	error_logger:info_msg("BODY:~s", [Body]),
	?_assertEqual(200, Code),
	{ok, {{_, Code1, _}, _, Body1}} =
      httpc:request("http://localhost:8000/sites/?action=remove_site&site=http://ag.ru"),
	error_logger:info_msg("BODY1:~s", [Body1]),
	?_assertEqual(200, Code1).

check_cookies(_) ->
	inets:start(),
	{ok, {{Version, Code, ReasonPhrase}, Headers, Body}} =
      httpc:request("http://localhost:8000/users/").