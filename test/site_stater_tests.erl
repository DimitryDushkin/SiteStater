%% Author: dimitry
%% Created: 17.06.2011
%% Description: TODO: Add description to st_site_checker_tests
-module(site_stater_tests).
-include_lib("eunit/include/eunit.hrl").

%%
%% API Functions
%%

checker_test_() ->
	{foreach,
	 fun setup/0,
	 fun cleanup/1,
	 [fun sites_checks_permently/1]}.

setup() -> 
	application:start(couchbeam),
	application:start(inets),
	inets:start(),
	st_db:start_link(),
	{ok, Pid} = site_stater:start_link(),
	Pid.

cleanup (Pid) ->
	gen_server:call(Pid, stop).


% Просто проверяем, что выдается в консоли при запущенном сервере
% в течение 15 секунд
sites_checks_permently(_) ->
 	{timeout, 15, fun() -> 
					timer:sleep(10000)	  
				   end}.