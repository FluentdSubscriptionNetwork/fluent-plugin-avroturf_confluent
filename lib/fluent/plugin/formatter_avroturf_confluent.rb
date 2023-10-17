#
# Copyright 2023- kubotat
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "fluent/plugin/formatter"
require 'avro_turf/messaging'
require 'avro_turf/confluent_schema_registry'

module Fluent
  module Plugin
    class AvroturfConfluentFormatter < Fluent::Plugin::Formatter
      Fluent::Plugin.register_formatter("avroturf_confluent", self)

        desc "URL of Confluent Schema Registry"
        config_param :schema_registry_url, :string, default:nil
        desc "API key of Confluent Schema Registry"
        config_param :schema_registry_api_key, :string, default:nil
        desc "API secret of Confluent Schema Registry"
        config_param :schema_registry_api_secret, :string, default:nil

        desc "The name of subject stored in Schema Registry"
        config_param :schema_subject, :string, default:""
        desc "The version of subject stored in Schema Registry"
        config_param :schema_version, :string, default:"latest"
	desc "Validate the message during encoding process(default: false)"
        config_param :validate, :bool, default:"false"

      def configure(conf)
        super
	if @schema_registry_url == nil || @schema_registry_api_key == nil || @chema_registry_api_secret ==nil
	  raise Fluent::ConfigError, "schema_registry_url, schema_registry_api_key and chema_registry_api_secret are mandatory"
	end
      end

      def format(tag, time, record)
        puts @schema_registry_url
	puts @schema_registry_api_key
	puts @schema_registry_api_secret
        record
      end
    end
  end
end
