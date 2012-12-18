%% Author: ddushkin
%% Created: 03.09.2011
%% Description: TODO: Add description to st_web_control_resource_users
-module(st_web_control_resource_users).
-compile(export_all).

-include_lib("webmachine/include/webmachine.hrl").

init([]) -> {ok, undefined}.

allowed_methods(ReqData, Context) ->
	% @TODO add allowed domain from config!
	ReqData1 = wrq:set_resp_header("Access-Control-Allow-Origin", "*", ReqData),
	%ReqData2 = wrq:set_resp_header("Set-cookie", "id=olla; expires=Fri, 30 Dec 2012 23:59:59 GMT; path=/", ReqData1),
    {['GET', 'POST'], ReqData1, Context}.

content_types_provided(ReqData, Context) ->
    {[{"application/json", to_json}], ReqData, Context}.

to_json(ReqData, Context) ->
	Response = case wrq:get_qs_value("action", ReqData) of
		"add_site" -> 
			Site = wrq:get_qs_value("site", ReqData),
			case gen_server:call(site_stater, {add_site, Site}) of
				site_exists -> "site_exists";
				_ -> "ok"
			end;
		"remove_site" -> 
			Site = wrq:get_qs_value("site", ReqData),
			gen_server:call(site_stater, {delete_site, Site}),
			"ok";
		undefined -> "no_request"
	end,
	{Response, ReqData, Context}.