
-module(epgsql_pool_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).
-export([start_pool/3]).

%% Supervisor callbacks
-export([init/1]).

%% Helper macro for declaring children of supervisor
-define(CHILD(I, Type), {I, {I, start_link, []}, permanent, 5000, Type, [I]}).

%% ===================================================================
%% API functions
%% ===================================================================

start_link() ->
    {ok,Pid} = supervisor:start_link({local, ?MODULE}, ?MODULE, []),
    {ok, Pools} = application:get_env(pools),
    case catch lists:foreach(fun start_pool/1, Pools) of
        {'EXIT', Why} -> {error, Why};
        _Other        -> {ok, Pid}
    end.

start_pool(Name, Size, Opts) ->
    supervisor:start_child(?MODULE, [Name, Size, Opts]).

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

init([]) ->
    {ok, { {one_for_one, 5, 10}, [?CHILD(pgsql_pool,supervisor)]} }.

%% ===================================================================
%% Internal functions
%% ===================================================================

start_pool(Name) ->
    case application:get_env(Name) of
        {ok, {Size, Opts}} -> start_pool(Name, Size, Opts);
        {ok, Value}        -> exit({invalid_pool_spec, Value});
        undefined          -> exit({missing_pool_spec, Name})
    end.