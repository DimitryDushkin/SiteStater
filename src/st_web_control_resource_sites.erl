%% Author: dimitry
%% Created: 29.06.2011
%% Description: TODO: Add description to st_web_control_resource_server
-module(st_web_control_resource_sites).
-compile(export_all).

-include_lib("webmachine/include/webmachine.hrl").

init([]) -> {ok, undefined}.

allowed_methods(ReqData, Context) ->
	% @TODO add allowed domain from config!
	ReqData1 = wrq:set_resp_header("Access-Control-Allow-Origin", "*", ReqData),
    {['GET', 'POST'], ReqData1, Context}.

content_types_provided(ReqData, Context) ->
    {[{"application/json", to_json}], ReqData, Context}.

to_json(ReqData, Context) ->
	Response = case wrq:get_qs_value("action", ReqData) of
		"add_site" -> 
			Site = wrq:get_qs_value("site", ReqData),
			User = wrq:get_qs_value("user", ReqData),
			case gen_server:call(site_stater, {add_site, Site, User}) of
				site_exists -> "site_exists";
				_ -> "ok"
			end;
		"remove_site" -> 
			Site = wrq:get_qs_value("site", ReqData),
			User = wrq:get_qs_value("user", ReqData),
			gen_server:call(site_stater, {delete_site, Site, User}),
			"ok";
		undefined -> "no_request"
	end,
	{Response, ReqData, Context}.

%%
%% Local Functions
%%