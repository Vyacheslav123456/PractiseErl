-module(frequency).
-author("V'yacheslav").
-export([start/0, stop/0, allocate/0, deallocate/1]).
-export([init/0]).



start() -> 
    register(frequency, spawn(frequency, init, [])).

init() ->
    Frequencies = {get_frequencies(), []},
    loop(Frequencies).

get_frequencies() -> [10,11,12,13,14,15].

stop()           -> call(stop).

allocate()       -> call(allocate).

deallocate(Freq) -> call({deallocate, Freq}).

call(Message) -> 
    frequency ! {request, self(), Message},
    receive
        {reply, Reply} -> Reply
    end.

loop(Frequencies) -> 
    receive 
        {request, Pid, allocate} ->
            {NewFrequencies, Reply} = allocate(Frequencies, Pid), 
            reply(Pid, Reply),
            loop(NewFrequencies);
        {request, Pid, {deallocate, Freq}} -> 
            {Reply, NewFrequencies} = deallocate(Frequencies, {Freq, Pid}), 
            reply(Pid, Reply), 
            loop(NewFrequencies);
        {request, Pid, stop} -> 
            case element(1, Frequencies) of
                [] ->
                    reply(Pid, ok);
                _ ->
                    reply(Pid, cannot_stop_until_no_frequencies),
                    loop(Frequencies)
            end
    end.

reply(Pid, Reply) -> 
    Pid ! {reply, Reply}.

allocate({[], Allocated}, _Pid) -> 
    {{[], Allocated}, {error, no_frequency}};
allocate({[Freq|Free], Allocated}, Pid) -> 
    {{Free, [{Freq, Pid}|Allocated]}, {ok, Freq}}.

deallocate({Free, Allocated}, Item) -> 
    case lists:member(Item, Allocated) of
        true -> 
            NewAllocated = lists:keydelete(Freq=element(1, Item), 1, Allocated),
            {ok, {[Freq|Free], NewAllocated}};
        false ->
            {not_found_your_frequency, {Free, Allocated}}
    end.



