-module(site_stater_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
	application:start(inets),
	application:start(crypto),
    application:start(mochiweb),
    application:set_env(webmachine, webmachine_logger_module, 
                        webmachine_logger),
    application:start(webmachine),
	application:start(couchbeam),
	site_stater_sup:start_link().

stop(_State) ->
    ok.
