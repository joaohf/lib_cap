% -*- mode: erlang;erlang-indent-level: 4;indent-tabs-mode: nil -*-
% ex: ft=erlang ts=4 sw=4 et

-module(cap).

-compile({parse_transform, ejson_trans}).

%% API exports
-export([
         model/0,
         create/2,
         convert_to_json/2
        ]).

-include("CAP-v1.2.hrl").

-json({alert,
       skip,
       {string, "identifier"},
       {string, "sender"},
       {string, "sent"},
       {string, "status"},
       {string, "msgType"},
       {string, "source"},
       {string, "scope"},
       {string, "restriction"},
       {string, "addresses"},
       {string, "code"},
       {string, "note"},
       {string, "references"},
       {string, "incidents"},
       {list, "alert/info"},
       skip}).

-json({'alert/info',
       skip,
       {string, "language"},
       {string, "category"},
       {string, "event"},
       {string, "responseType"},
       {string, "urgency"},
       {string, "severity"},
       {string, "certainty"},
       {string, "audience"},
       {record, 'alert/info/eventCode'}, 
       {string, "effective"},
       {string, "onset"},
       {string, "expires"}, 
       {string, "senderName"},
       {string, "headline"},
       {string, "description"},
       {string, "instruction"},
       {string, "web"},
       {string, "contact"},
       {list, 'alert/info/parameter'},
       {record, 'alert/info/resource'},
       {record, 'alert/info/area'}
      }).

-json({'alert/info/eventCode',
       {string, "valueName"},
       {string, "value"}
      }).

-json({'alert/info/parameter',
       skip,
       {string, "valueName"},
       {string, "value"}
      }).

-json({'alert/info/resource',
       {string, "resosurceDesc"},
       {string, "mimeType"},
       {number, "size"},
       {string, "uri"},
       {string, "derefUri"},
       {string, "digest"}
      }).

-json({'alert/info/area',
       {string, "areaDesc"},
       {string, "polygon"},
       {string, "circle"},
       {record, 'alert/info/area/geocode'},
       {string, "altitude"},
       {string, "ceiling"}
      }).

-json({'alert/info/area/geocode',
       {string, "valueName"},
       {string, "value"}
      }).

%%====================================================================
%% API functions
%%====================================================================

%% @doc Get Common Alert Protocol XSD
model() ->
    {ok, Model} = erlsom:compile_xsd_file(xsd()),
    Model.

%% @doc Creates a CAP message using XML
create(Model, CapProps) ->
    Identifier = identifier(proplists:get_value(identifier, CapProps)),
    Sender = proplists:get_value(sender, CapProps),
    Sent = sent(proplists:get_value(sent, CapProps)),

    Status = proplists:get_value(status, CapProps, "Actual"),
    MsgType = proplists:get_value(msgType, CapProps, "Alert"),
    Scope = proplists:get_value(scope, CapProps, "Public"),
    Code = proplists:get_value(code, CapProps, " "),

    ResponseInfo = info(proplists:get_value(info, CapProps)),
    Response = #alert{
                  identifier = Identifier,
                  sender = Sender,
                  sent = Sent,
                  status = Status,
                  msgType = MsgType,
                  scope = Scope,
                  info = ResponseInfo
                },

    encode(Model, Response).

convert_to_json(Model, CapXml) ->
    {ok, Result, _} = erlsom:scan(CapXml, Model),

    io:format("Result: ~p~n", [Result]),

    {ok, Json} = to_json(Result),
    Json.
    

%%====================================================================
%% Internal functions
%%====================================================================

encode(Model, Response) ->
    {ok, Xml} =erlsom:write(Response, Model),
    list_to_binary(erlsom_ucs:to_utf8(Xml)).

xsd() ->
    filename:join([code_dir(), "CAP-v1.2.xsd"]).

code_dir() ->
    code:priv_dir(lib_cap).


identifier(undefined) ->
    {Node, SystemTime} = {node(),erlang:system_time(micro_seconds)},
    L = io_lib:format("~w-~w", [Node, SystemTime]),
    lists:flatten(L);
identifier(Else) ->
    Else.
        
sent(undefined) ->
    % TODO: get timezone. For instance, just set a default
    sent({calendar:local_time(), {'+', 03, 00}});
sent({{{Year,Month,Day}, {Hour,Minute,Sec}}, {X, Zh, Zm}}) ->
    F = io_lib:format("~4..0B-~2..0B-~2..0BT~2..0B:~2..0B:~2..0B~s~2..0B:~2..0B",
                      [Year,Month,Day,Hour,Minute,Sec,X,Zh,Zm]),
    lists:flatten(F);
sent(_) ->
    sent(undefined).

parameter(Parameter) ->
    ValueName = proplists:get_value(valueName, Parameter),
    Value = proplists:get_value(value, Parameter),
    R = #'alert/info/parameter'{
           valueName = ValueName,
           value = Value
          },
    [R].
    
info(Info) ->
    Category = proplists:get_value(category, Info),
    Event = proplists:get_value(event, Info),    
    Urgency = proplists:get_value(urgency, Info),
    Severity = proplists:get_value(severity, Info),
    Certainty = proplists:get_value(certainty, Info),
    Parameter = parameter(proplists:get_value(parameter, Info)),

    R = #'alert/info'{
           category = [Category],
           event = Event,
           urgency = Urgency,
           severity = Severity,
           certainty = Certainty,
           parameter = Parameter
          },
    
    [R].
