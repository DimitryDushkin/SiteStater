%% Author: dimitry
%% Created: 23.04.2011
%% Description: TODO: Add description to st_site_checker
%% @TODO: Move all doc build logic to st_db
-module(st_site_checker).

%%
%% Include files
%%
-include_lib("xmerl/include/xmerl.hrl").

%%
%% Exported Functions
%%
-export([start/2, stop/1, check_sites/1, receive_reply/3]).

%% --------------------------------------------------------------------
%%% External functions
%% --------------------------------------------------------------------

%%--------------------------------------------------------------------
%% @doc Begins sites' checking
%% Returns: {ok, TimerRef} | {error, Reason}
%%--------------------------------------------------------------------
start(DBPid, CheckInterval) ->
	timer:apply_interval(CheckInterval, ?MODULE, check_sites, [DBPid]).

%%--------------------------------------------------------------------
%% @doc Stop sites' checking
%% Returns: {ok, cancel} | {error, Reason}
%%--------------------------------------------------------------------
stop(TimerRef) ->
	timer:cancel(TimerRef).

%%--------------------------------------------------------------------
%% @doc Send async request to sites
%% @TODO: get sites list on list's update and from DB (?)
%%--------------------------------------------------------------------
check_sites(DBPid) ->
	Sites = gen_server:call(DBPid, get_sites_list),
	lists:foreach(fun (Url) -> 
						httpc:request(get, {Url, []}, [],
							[{sync, false}, 
							 {receiver, spawn(?MODULE, receive_reply,
						 	  		[Url, st_utils:get_timestamp(), DBPid])}
							]
						)
				  end, Sites),
	error_logger:info_msg("Requests sent."),
	ok.
	


%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

%%--------------------------------------------------------------------
%% @doc Receives replies from get_sites/0 in async way.
%% Function is exported to supress "unused function" compile waring.
%% @TODO rewrite to isolate in st_db Doc creation process
%%--------------------------------------------------------------------
receive_reply(Url, RequestSendTime, DBPid) ->
	receive 
		{http, {_RequestId, Result}} ->
			RequestReceiveTime = st_utils:get_timestamp(),
			case Result of
 				{{_HttpVer, Code, _Msg}, _Headers, _Body} ->
					Doc = {[
							{<<"url">>, list_to_binary(Url)},
							{<<"status">>, Code},
							{<<"timestamp">>, RequestReceiveTime},
							{<<"ping">>, (RequestReceiveTime - RequestSendTime)}
						  ]},
					error_logger:info_msg("Site ~s is online. Code: ~s, Ping: ~s",
										  [Url, Code, (RequestReceiveTime - RequestSendTime)]),
					{ok, _} = gen_server:call(DBPid, {save_doc, Doc}),
					gen_server:cast(DBPid, {update_site_status, Url, [Code, RequestReceiveTime]});
 				{error, Reason} ->
					Status = atom_to_binary(Reason, utf8),
					Doc = {[
							{<<"url">>, list_to_binary(Url)},
							{<<"status">>, Status}, 				%% can be here not only terms?
							{<<"timestamp">>, RequestReceiveTime}
						  ]},
					{ok, _} = gen_server:call(DBPid, {save_doc, Doc}),
					gen_server:cast(DBPid, {update_site_status, Url, [Status, RequestReceiveTime]})
 			end
		after 20000 -> 												%% 20 sec request send timeout
			Doc = {[
					{<<"url">>, list_to_binary(Url)},
					{<<"status">>, <<"timeout">>},
					{<<"timestamp">>, RequestSendTime}
				  ]},
			{ok, _} = gen_server:call(DBPid, {save_doc, Doc}),
			error_logger:info_msg("Site ~s is offline.", [Url])			
	end.	