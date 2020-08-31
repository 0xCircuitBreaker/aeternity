-module(aehc_connector).

-export([connector/0]).

-export([send_tx/1, get_block/1]).
-export([tx/2, block/4]).
-export([publish_block/1, subscribe/0]).

-type connector() :: atom().

-callback send_tx(binary()) -> binary().

-callback get_block(Num::integer()) -> block().

%%%===================================================================
%%%  Parent chain simplified proto
%%%===================================================================

-record(tx, { sender :: binary(), payload :: binary() }).

-type tx() :: #tx{}.

-record(block, { number = 0 :: integer(), hash :: binary(), prev_hash :: binary(), txs :: [tx()] }).

-type block() :: #block{}.

-spec tx(Sender::binary(), Payload::binary()) -> tx().
tx(Sender, Payload) when
      is_binary(Sender), is_binary(Payload) ->
    #tx{ sender = Sender, payload = Payload }.

-spec block(Num::integer(), Hash::binary(), PrevHash::binary(), Txs::[tx()]) -> block().
block(Num, Hash, PrevHash, Txs) when
      is_integer(Num), is_binary(Hash), is_binary(PrevHash), is_list(Txs) ->
    #block{ number = Num, hash = Hash, prev_hash = PrevHash, txs = Txs }.

%%%===================================================================
%%%  Parent chain interface
%%%===================================================================

-spec send_tx(Payload::binary()) ->
                    ok | {error, {term(), term()}}.
send_tx(Payload) ->
    Con = connector(), %% TODO To ask via config;
    try
        ok = Con:send_tx(Payload)
    catch E:R ->
            {error, {E, R}}
    end.

-spec get_block(Num::integer()) ->
                       {ok, block()} | {error, {term(), term()}}.
get_block(Num) ->
    Con = connector(), %% TODO To ask via config;
    try
        Res = Con:get_block(Num), true = is_record(Res, block),
        {ok, Res}
    catch E:R ->
            {error, {E, R}}
    end.

%%%===================================================================
%%%  Parent chain events
%%%===================================================================

-spec subscribe() -> true.
subscribe() ->
    aec_events:subscribe(parent_chain).

-spec publish_block(block()) -> ok.
publish_block(Block) ->
    aec_events:publish(parent_chain, {block_created, Block}).

%%%===================================================================
%%%  Proto accessors
%%%===================================================================

%% TODO: BlockHash, etc..


connector() ->
    Con = aehc_app:get_connector_id(),
    Module = binary_to_existing_atom(Con, utf8), true = (false /= code:is_loaded(Module)),
    Module.