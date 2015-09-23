% -*- mode: erlang;erlang-indent-level: 4;indent-tabs-mode: nil -*-
% ex: ft=erlang ts=4 sw=4 et

-module(cap_tests).

-include_lib("eunit/include/eunit.hrl").

cap_test_() ->
    {"Basic CAP operations",
     {setup,
      fun setup/0,
      fun cleanup/1,
      fun(State) ->
              [{"Create CAP XML", create_cap_xml_transform_to_json(State)}]
      end}
    }.

setup() ->
    Xsd = cap:model(),
    [{cap_xsd, Xsd}].

cleanup(_State) ->
    [].

create_cap_xml_transform_to_json(State) ->
    Xsd = proplists:get_value(cap_xsd, State),

    Params = [{valueName, "Dust1"},
              {value, "10"}],
    Info = [{category, "Other"},
            {event, "Sensor Test"},
            {urgency, "Immediate"},
            {severity, "Unknown"},
            {certainty, "Observed"},
            {parameter, Params}],

    CapXml = cap:create(Xsd, [
                              {identifier, "Test"},
                              {sender, "Node1"},
                              {sent, "undefined"},
                              {info, Info}]),

    ?debugVal(CapXml),

    CapJson = cap:convert_to_json(Xsd, CapXml),
                                
    ?debugVal(CapJson),

    [?_assertEqual(ok, CapXml)].
