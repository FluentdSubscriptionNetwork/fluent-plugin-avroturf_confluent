#
# Copyright 2023- Tomonori Kubota (TK)
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
require 'fluent/oj_options'
require 'avro_turf/messaging'
require 'avro_turf/confluent_schema_registry'

module Fluent
  module Plugin
    class AvroturfSerializer < Fluent::Plugin::Formatter
      Fluent::Plugin.register_formatter("avroturf_serializer", self)

        config_param :schema_registry_url, :string, :default => nil, :desc => "URL of Confluent Schema Registry"
	config_param :schema_registry_api_key, :string, :default => nil, :secret => true, :desc => "API key of Confluent Schema Registry"
        config_param :schema_registry_api_secret, :string, :default => nil, :secret => true, :desc => "API secret of Confluent Schema Registry"

        config_param :namespace, :string, :default => nil, :desc =>  "The namespace of schema"
        config_param :schema_subject, :string, :default => nil, :desc => "The name of subject stored in Schema Registry"
        config_param :schema_version, :string, :default => nil, :desc => "The version of subject stored in Schema Registry"

	config_param :schemas_path, :string, :default => "./schemas/", :desc => "The directory path where Avro schema files(.avsc) are stored"
	config_param :schema_name, :string, :default => nil, :desc => "The name of schemas stored in Avro schema files"

        config_param :schema_id, :integer, :default => nil, :desc => "The ID of schemas stored in Schema Registry"
        config_param :validate, :bool, :default => false, :desc => "Validate the message during encoding process(default: false)"

        config_param :format_as_json_when_encode_failed, :bool, :default => false, :desc => "Format events as JSON when encoding failed(default: false)"

      def configure(conf)
        super
	if @schema_registry_url == nil || @schema_registry_api_key == nil || @schema_registry_api_secret ==nil
	  raise Fluent::ConfigError, "schema_registry_url, schema_registry_api_key and schema_registry_api_secret are mandatory"
	end
	@avro = AvroTurf::Messaging.new(
          registry_url: @schema_registry_url,
	  user: @schema_registry_api_key,
	  password: @schema_registry_api_secret,
	  schemas_path: @schemas_path,
	)
        if @format_as_json_when_encode_failed
          @dump_proc = Oj.method(:dump)
        end
        
        if @schema_subject 
	  raise Fluent::ConfigError, "schema_version is required when fetching schema with schema_subject" if @schema_version == nil
        end
      end

      def format(tag, time, record)
        begin
          encoded_data = @avro.encode(
            record, 
	    subject: @schema_subject, 
	    version: @schema_version, 
	    schema_name: @schema_name, 
	    schema_id: @schema_id, 
	    validate: @validate,
            namespace: @namespace
	  )
        rescue => e
          if @format_as_json_when_encode_failed
            log.debug "Encode failed. Format events as JSON instead.", :error => e.to_s, :error_class => e.class.to_s, :tag => tag
            "#{@dump_proc.call(record)}#{@newline}"
          end
        end
      end
    end
  end
end
