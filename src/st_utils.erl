%% Author: dimitry
%% Created: 11.06.2011
%% Description: TODO: Add description to st_utils
-module(st_utils).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([get_timestamp/0]).

%%
%% API Functions
%%

%%--------------------------------------------------------------------
%% Return UNIX timestamp in ms
%%--------------------------------------------------------------------
get_timestamp() ->
	{Mega,Sec,Micro} = erlang:now(),
    (Mega*1000000 + Sec)*1000 + round(Micro/1000).