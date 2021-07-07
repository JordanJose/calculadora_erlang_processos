-module(calculadora).
-import(string, [strip/3, split/3]).
-import(net_adm, [ping/1]).
-export([start/0]).
-export([multiplicacao/3]).
-export([adicao/3]).
-export([divisao/3]).
-export([subtracao/3]).

read_input() -> strip(io:get_line("Informe a expressão: "), right, $\n).

% https://stackoverflow.com/questions/17438727/in-erlang-how-to-return-a-string-when-you-use-recursion/17439656
parse(Str) ->
    {ok, Tokens, _} = erl_scan:string(Str ++ "."),
    {ok, [E]} = erl_parse:parse_exprs(Tokens),
    E.

rpn({op, _, What, LS, RS}) ->
    io_lib:format("~s ~s ~s", [rpn(LS), rpn(RS), atom_to_list(What)]);
rpn({integer, _, N}) ->
    io_lib:format("~b", [N]).

p(Str) ->
    Tree = parse(Str),
    lists:flatten(rpn(Tree)).

evaluate_aux(Elem) ->
    if
        Elem == "+" ->
            Stack = get("stack"),
            A = lists:last(Stack),
            ListaA = lists:droplast(Stack),
            B = lists:last(ListaA),
            ListaB = lists:droplast(ListaA),
            Pid = spawn(calculadora, adicao, [self(), A, B]),
            receive 
                {Pid, Result} ->
                    Result
            end,
            put("stack", ListaB ++ [Result]);
            
        Elem == "-" ->
            Stack = get("stack"),
            A = lists:last(Stack),
            ListaA = lists:droplast(Stack),
            B = lists:last(ListaA),
            ListaB = lists:droplast(ListaA),
            Pid = spawn(calculadora, subtracao, [self(), A, B]),
            receive 
                {Pid, Result} ->
                    Result
            end,
            put("stack", ListaB ++ [Result]);

        Elem == "*" ->
            Stack = get("stack"),
            A = lists:last(Stack),
            ListaA = lists:droplast(Stack),
            B = lists:last(ListaA),
            ListaB = lists:droplast(ListaA),
            Pid = spawn(calculadora, multiplicacao, [self(), A, B]),
            receive 
                {Pid, Result} ->
                    Result
            end,
            put("stack", ListaB ++ [Result]);

        Elem == "/" ->
            Stack = get("stack"),
            A = lists:last(Stack),
            ListaA = lists:droplast(Stack),
            B = lists:last(ListaA),
            ListaB = lists:droplast(ListaA),
            Pid = spawn(calculadora, divisao, [self(), A, B]),
            receive 
                {Pid, Result} ->
                    Result
            end,
            put("stack", ListaB ++ [Result]);

        true ->
            {Num, _} = string:to_integer(Elem),
            put("stack", get("stack") ++ [Num])
    end.

evaluate([]) -> ok;
evaluate([H|T]) ->
    evaluate_aux(H),
    evaluate(T).

loop() ->
    put("stack", []),
    ENTRADA = p(read_input()),
    Entrada_f = split(ENTRADA, " ", all),
    evaluate(Entrada_f),
    io:write(get("stack")),
    io:fwrite("\n"),
    loop().

start() ->
    io:fwrite("\n"),
    loop().

multiplicacao(From, A, B) -> 
    Result = A * B,
    From ! {self(), Result}.

divisao(From, A, B) -> 
    Result = A / B,
    From ! {self(), Result}.

subtracao(From, A, B) -> 
    Result = A - B,
    From ! {self(), Result}.

adicao(From, A, B) -> 
    Result = A + B,
    From ! {self(), Result}.