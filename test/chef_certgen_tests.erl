%%%-------------------------------------------------------------------
%%% @author Christopher Brown <cb@opscode.com>
%%% @copyright (C) 2010-2012, Opscode, Inc.
%%% @doc
%%%
%%% @end
%%% Created : 25 Nov 2010 by Christopher Brown <cb@opscode.com>
%%%
%%% Licensed under the Apache License, Version 2.0 (the "License");
%%% you may not use this file except in compliance with the License.
%%% You may obtain a copy of the License at
%%% 
%%%     http://www.apache.org/licenses/LICENSE-2.0
%%% 
%%% Unless required by applicable law or agreed to in writing, software
%%% distributed under the License is distributed on an "AS IS" BASIS,
%%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%%% See the License for the specific language governing permissions and
%%% limitations under the License.
%%%
%%%-------------------------------------------------------------------

-module(chef_certgen_tests).

-include_lib("eunit/include/eunit.hrl").
-include_lib("chef_certgen/include/chef_certgen.hrl").

generate_keypair_test() ->
    ?assertMatch(#rsa_key_pair{public_key = <<_Pub/binary>>,
                               private_key = <<_Priv/binary>>},
                 chef_certgen:rsa_generate_keypair(2048)).

create_x509_certificate_test() ->
    CaDir = filename:join(["..", "test"]),
    CaCertName = filename:join(CaDir, "server_cert.pem"),
    CaKeypairName  = filename:join(CaDir, "server_key.pem"),
    {ok, CaCertPem} = file:read_file(CaCertName),
    {ok, CaKeypairPem} = file:read_file(CaKeypairName),
    CaKeyPair = #rsa_key_pair{public_key = <<"">>,
                              private_key = CaKeypairPem},

    Subject = #x509_subject{'CN' = "Bob",
                            'O' = "Opscode, Inc.",
                            'OU' = "Certificate Service",
                            'C' = "US",
                            'ST' = "Washington",
                            'L' = "Seattle"},
    GeneratedKeyPair = chef_certgen:rsa_generate_keypair(2048),
    X509In = #x509_input{signing_key = CaKeyPair,
                         issuer_cert = CaCertPem,
                         newcert_public_key = GeneratedKeyPair#rsa_key_pair.public_key,
                         subject = Subject,
                         serial = 1,
                         expiry = 10*365},
    TestCertResult = chef_certgen:x509_make_cert(X509In),
    ?assertMatch({x509_cert, <<_/binary>>}, TestCertResult).
