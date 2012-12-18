-module(st_web_control_resource_server).
-compile(export_all).

-include_lib("webmachine/include/webmachine.hrl").

init([]) -> {ok, undefined}.

allowed_methods(ReqData, Context) ->
    {['GET', 'POST'], ReqData, Context}.

content_types_provided(ReqData, Context) ->
	% @TODO add allowed domain from config!
	ReqData1 = wrq:set_resp_header("Access-Control-Allow-Origin", "*", ReqData),
    {[{"application/json", to_json}], ReqData1, Context}.

to_json(ReqData, Context) ->
	Response = case wrq:get_qs_value("action", ReqData) of
		undefined -> 
			case gen_server:call(site_stater, get_server_state) of
				ok -> mochijson2:encode({struct, [{<<"server_status">>, <<"up">>}]});
				_ -> mochijson2:encode({struct, [{<<"server_status">>, <<"down">>}]})
			end
	end,
	{Response, ReqData, Context}.