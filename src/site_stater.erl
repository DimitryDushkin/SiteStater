%%% -------------------------------------------------------------------
%%% Author  : Dmitry Dushkin <legato.di@gmail.com>
%%% Description :
%%%
%%% Created : 14.06.2011
%%% -------------------------------------------------------------------
-module(site_stater).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% External exports
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {timer_ref}).

-define(DEFAULT_CHECK_INTERVAL, 60000 * 3).  % 3 mins
-define(DB_MODULE, st_db).

%% ====================================================================
%% External functions
%% ====================================================================


%%--------------------------------------------------------------------
%% @doc Starts the server.
%%
%% @spec start_link() -> {ok, Pid}
%% where
%%  Pid = pid()
%% @end
%%--------------------------------------------------------------------
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% ====================================================================
%% Server functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([]) ->
	TimerRef = st_site_checker:start(?DB_MODULE, ?DEFAULT_CHECK_INTERVAL),
    {ok, #state{timer_ref = TimerRef}}.

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% @doc Stop server
%% --------------------------------------------------------------------
handle_call(stop, _From, #state{timer_ref = TimerRef} = State) -> 
	st_site_checker:stop(TimerRef),
	{stop, normal, ok, State};

%% --------------------------------------------------------------------
%% @doc Add site to check
%% --------------------------------------------------------------------
handle_call({add_site, Site, User}, _From, State) ->
	Result = gen_server:call(?DB_MODULE, {add_site, Site, User}),
	{reply, Result, State};

%% --------------------------------------------------------------------
%% @doc Delete site from check list
%% --------------------------------------------------------------------
handle_call({delete_site, Site, User}, _From, State) ->
	{ok, Result} = gen_server:call(?DB_MODULE, {delete_site, Site, User}),
	{reply, Result, State};

%% --------------------------------------------------------------------
%% @doc Get server's state
%% --------------------------------------------------------------------
handle_call(get_server_state, _From, State) ->
	{reply, ok, State}.


%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast(_,State) ->
	{noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
	ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

