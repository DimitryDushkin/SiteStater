%% Author: dimitry
%% Created: 14.06.2011
%% Description: TODO: Add description to db_test
-module(st_db_tests).
-include_lib("eunit/include/eunit.hrl").
-export([]).



main_test_() ->
	{foreach,
     fun setup/0,
     fun cleanup/1,
     % Note that this must be a List of TestSet or Instantiator
     % (I have instantiators == functions generating tests)
     [
      % First Iteration
      fun db_server_up/1,
	  fun db_write_delete/1,
	  fun db_add_site/1,
	  fun db_delete_site_and_stats/1,
	  fun db_update_site_status/1
     ]}.

setup() -> 
	{ok,Pid} = st_db:start_link(), Pid.
cleanup(Pid) -> 
	gen_server:call(Pid, stop).

db_server_up(Pid) ->	
	?_assertMatch({[{<<"couchdb">>,<<"Welcome">>},{<<"version">>, _}]},
 				  gen_server:call(Pid, test)).

db_write_delete(Pid) ->
	Doc = {[
			{<<"url">>, "http://example.com"},
			{<<"status">>, <<"test">>},
			{<<"timestamp">>, 0}
		 ]},
	{ok, NewDoc} = gen_server:call(Pid, {save_doc, Doc}),
	?_assertMatch({ok, _Result},
				 gen_server:call(Pid, {delete_doc, NewDoc})).

db_add_site(Pid) ->
	Site = "http://ag12345467.ru",
	{ok, NewDoc} = gen_server:call(Pid, {add_site, Site}),
	?_assertMatch({ok, _Result},
				 gen_server:call(Pid, {delete_doc, NewDoc})).

db_delete_site_and_stats(Pid) ->
	Site = "http://ag1234567.ru",
	gen_server:call(Pid, {add_site, Site}),
	Stats = [
			 {[
				{<<"url">>, list_to_binary(Site)},
				{<<"status">>, <<"test">>},
				{<<"timestamp">>, 1234564353212}
		 	 ]},
			 {[
				{<<"url">>, list_to_binary(Site)},
				{<<"status">>, <<"test">>},
				{<<"timestamp">>, 123451345325412}
		 	 ]},
			 {[
				{<<"url">>, list_to_binary(Site)},
				{<<"status">>, <<"test">>},
				{<<"timestamp">>, 123456234232}
		 	 ]}
			],
	{ok, _} = gen_server:call(Pid, {save_docs, Stats}),
	?_assertMatch({ok, _},
				 gen_server:call(Pid, {delete_site, Site})).

db_update_site_status(Pid) ->
	Site = "http://ag1234567.ru",
	gen_server:call(Pid, {add_site, Site}),
	gen_server:cast(Pid, {update_site_status, Site, [404, 123253212]}),
	{ok, Doc} = gen_server:call(Pid, {open_doc, list_to_binary(Site)}),
	?_assertEqual(404, proplists:get_value(<<"status">>, Doc)),
	?_assertEqual(123253212, proplists:get_value(<<"timestamp">>, Doc)),
	?_assertMatch({ok, _},
				  gen_server:call(Pid, {delete_site, Site})),
	
	gen_server:call(Pid, {add_site, Site}),
	gen_server:cast(Pid, {update_site_status, Site, ["mxdomain", 123243123]}),
	{ok, Doc2} = gen_server:call(Pid, {open_doc, list_to_binary(Site)}),
	?_assertEqual(<<"mxdomain">>, proplists:get_value(<<"status">>, Doc2)),
	?_assertMatch({ok, _},
				  gen_server:call(Pid, {delete_site, Site})).