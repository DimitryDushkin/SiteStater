%%% -------------------------------------------------------------------
%%% Author  : dimitry
%%% Description :
%%%
%%% Created : 14.06.2011
%%% -------------------------------------------------------------------
-module(st_db).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% External exports
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {db_pid, couch_server_pid}).

-define(DESIGN_DOC, "app").

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
    gen_server:start_link({local, st_db}, ?MODULE, ["localhost", 5984, "site_stater"], []).
	
%% ====================================================================
%% Server internal functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([Server, Port, DB]) ->
	couchbeam:start(),
	CouchServer = couchbeam:server_connection(Server, Port, "", []),
    {ok, CouchDB} = couchbeam:open_or_create_db(CouchServer, DB, []),
    {ok, #state{db_pid=CouchDB, couch_server_pid=CouchServer}}.


%% ====================================================================
%% DB manipulation functions
%% ====================================================================


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
handle_call (test, _From, #state{couch_server_pid = Couch_server_pid} = State) ->
	{ok, Version} = couchbeam:server_info(Couch_server_pid),
	{reply, Version, State};

handle_call ({open_doc, DocId}, _From, #state{db_pid = Db_pid} = State) ->
	Result = couchbeam:open_doc(Db_pid, DocId),
	{reply, Result, State};

handle_call ({save_doc, Doc}, _From, #state{db_pid = Db_pid} = State) ->
	Result = couchbeam:save_doc(Db_pid, Doc),
	{reply, Result, State};

handle_call ({save_docs, Docs}, _From, #state{db_pid = Db_pid} = State) ->
	Result = couchbeam:save_docs(Db_pid, Docs),
	{reply, Result, State};

handle_call ({delete_doc, Doc}, _From, #state{db_pid = Db_pid} = State) ->
	Result = couchbeam:delete_doc(Db_pid, Doc),
	{reply, Result, State};


%% @TODO write test
handle_call (get_sites_list, _From, #state{db_pid = Db_pid} = State) ->
	{ok, ViewResult} = couchbeam_view:fetch(Db_pid, {?DESIGN_DOC, "get-sites-list"}),
	case ViewResult of
		[] -> Sites = [];
		Rows ->
			Sites = lists:map(fun ({Row}) ->
								 {_, Site} = lists:keyfind(<<"id">>, 1, Row),
								 binary_to_list(Site)
					  		  end, Rows)
	end,
	{reply, Sites, State};


handle_call ({add_site, Site, User}, _From, #state{db_pid = Db_pid} = State) ->
	Doc = {[
			{<<"_id">>, list_to_binary(Site)},
			{<<"type">>, <<"site">>}
		   ]},
	%% check if site already in check list
	%% add, if it is not
	%% all sites have url in "_id" property
	Result = case couchbeam:doc_exists(Db_pid, list_to_binary(Site)) of
		true -> site_exists;
		false -> couchbeam:save_doc(Db_pid, Doc)
	end,
	
	{reply, Result, State};

%% @doc Add site to user's list
%handle_call ({add_site_to_user_list, Site, User}, _From, #state{db_pid = Db_pid} = State) ->


%% @doc Delete site and all its stat
handle_call ({delete_site, Site, User}, _From, #state{db_pid = Db_pid} = State) ->
	% get site's stat docs
	{ok, ViewResults} = couchbeam_view:fetch(Db_pid,
									  {?DESIGN_DOC, "get-stat-by-site-url"},
								 	  [{key, list_to_binary(Site)}]),
	Stats = lists:map(fun({Doc})->
						{_, {Value}} = lists:keyfind(<<"value">>, 1, Doc),
						{_, Id} = lists:keyfind(<<"_id">>, 1, Value),
						{_, Rev} = lists:keyfind(<<"_rev">>, 1, Value),
						{[{<<"_id">>, Id},
                          {<<"_rev">>, Rev}
						 ]}
                 end, ViewResults),
	% delete stats
	couchbeam:delete_docs(Db_pid, Stats),
	% delete site's doc
	{ok, Doc} = couchbeam:open_doc(Db_pid, list_to_binary(Site)),
	Result = couchbeam:delete_doc(Db_pid, Doc),
	{reply, Result, State};


handle_call(stop, _From, State) -> 
	{stop, normal, ok, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast({update_site_status, Site, [Status, Timestamp]}, #state{db_pid = Db_pid} = State) ->
	{ok, Doc} = couchbeam:open_doc(Db_pid, list_to_binary(Site)),
	Status1 = if 
				  is_number(Status) -> Status;
				  is_list(Status) -> list_to_binary(Status)
			  end,
	Doc1 = couchbeam_doc:set_value(<<"status">>, Status1, Doc),
	Doc2 = couchbeam_doc:set_value(<<"timestamp">>, Timestamp, Doc1),
	{ok, _} = couchbeam:save_doc(Db_pid, Doc2),
	{noreply, State};

handle_cast(_Msg, State) ->
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
