# fluent-plugin-avroturf_confluent
## Overview
Schema Registry manages and stores data schemas that are shared between different services. It is commonly used in Apache Kafka to ensure that data exchanged among different producers and consumers adheres to a predefined schema or data structure. `fluent-plugin-avroturf_confluent` is formatter plugin developed for `fluent-plugin-kafka/out_rdkafka2` to serialize messages in key-value pairs format into Avro format before shipping messages to Kafka brokers. The plugin utilizes [AvroTurf](https://github.com/dasch/avro_turf) library to register and retrieve schemas from the Schema Registry provided by Confluent Cloud, and then serialize key-value pairs into avro format.

## Installation

### RubyGems
For vanila Fluentd :
```
$ gem install fluent-plugin-avroturf_confluent
```
For td-agent v4 or later (scheduled EoL on Dec 2023) :
```
$ /opt/td-agent/bin/fluent-gem install fluent-plugin-avroturf_confluent
```
For fluent-package v5 or later :
```
$ /opt/fluent/bin/fluent-gem install fluent-plugin-avroturf_confluent
```

## Configuration
### Available Options of `avroturf_serializer` formatter
The following options are mandatory to access Schema Registry
- `schema_registry_url` : URL of Schema Resigtry
- `schema_registry_api_key` : API key to access Schema Resigtry
- `schema_registry_api_secret` : API Secret to access Schema Resigtry

The options below are required to configure based on schema fetching patterns.
- `schema_subject` : Subject name of schema (default: nil)
- `schema_version` : Version of schema (default: nil)
- `schema_id` : ID of schema (default: nil)
- `schemas_path` : Path of directory which stores avsc files (default: ./schemas/)
- `schema_name` : Name of schema  (default: nil)
- `validate` : validate a message before serializing it.  (default: false)
- `format_as_json_when_encode_failed` : Format as JSON when encode process failed. (defalut: false)

### Configuration Patterns
There are 3 configuration patterns to fetch schema.
- Pattern#1 : Fetch schema with subject name and its version
  - It is required to configure both `schema_subject` and `schema_version`.
  - Formatter plugin fetches that schema from the Schema Registry and cache it. When `schema_version` is `latest`, formatter fetches schema from Schema Registry every time before encoding. 
  - `validate` option is optional. 
```
<format>
  @type avroturf_serializer
  schema_registry_url "#{ENV['SCHEMA_REGISTRY_URL']}"
  schema_registry_api_key "#{ENV['SCHEMA_REGISTRY_API_KEY']}"
  schema_registry_api_secret "#{ENV['SCHEMA_REGISTRY_API_SECRET']}"

  ### Pattern#1 : Fetch schema with subject name and version
  schema_subject <your subject name>
  schema_version <version of your subject>
  validate false
</format>
```
- Pattern#2 : Fetch schema with ID
  - `schema_id` option is required.
  - `validate` option is optional.
```
<format>
  @type avroturf_serializer
  schema_registry_url "#{ENV['SCHEMA_REGISTRY_URL']}"
  schema_registry_api_key "#{ENV['SCHEMA_REGISTRY_API_KEY']}"
  schema_registry_api_secret "#{ENV['SCHEMA_REGISTRY_API_SECRET']}"

  ### Pattern#2 : Fetch schema with ID
  #schema_id <your Schema ID>
</format>
```
- Pattern#3 : Fetch schema from avsc
  - `schemas_path` and `schema_name` are needed to fetch schema from local avsc files.
  - Given the following configuration, formatter plugin fetches schema from `/etc/fluent/schemas/test_address1.avsc`.
  - When `namespace` is defined in a schema, avsc files shoud be stored under `<schemas_path>/<namespace>/<schema_name>.avsc`
  - New schema is registered when there is no compatible schemas in Schema Registry.
```
### Configuration schema without namespace definition
<format>
  @type avroturf_serializer
  schema_registry_url "#{ENV['SCHEMA_REGISTRY_URL']}"
  schema_registry_api_key "#{ENV['SCHEMA_REGISTRY_API_KEY']}"
  schema_registry_api_secret "#{ENV['SCHEMA_REGISTRY_API_SECRET']}"

  ### Pattern#3 : Get schema from avsc
  schemas_path  /etc/fluent/schemas
  schema_name test_address1
</format>

### /etc/fluent/schemas/test_address1.avsc
{
  "name": "test_address1",
  "type": "record",
  "fields": [
    {
      "name": "state",
      "type": "string"
    },
    {
      "name": "city",
      "type": "string"
    }
  ]
}
```
```
### Configuration when schema with namespace definition
<format>
  @type avroturf_serializer
  schema_registry_url "#{ENV['SCHEMA_REGISTRY_URL']}"
  schema_registry_api_key "#{ENV['SCHEMA_REGISTRY_API_KEY']}"
  schema_registry_api_secret "#{ENV['SCHEMA_REGISTRY_API_SECRET']}"

  ### Get schema from avsc
  schemas_path /etc/fluent/schemas/
  namespace demo
  schema_name test_address2
</format>

### /etc/fluent/schemas/demo/test_address2.avsc
{
  "name": "test_address2",
  "namespace": "demo",
  "type": "record",
  "fields": [
    {
      "name": "city",
      "type": "string"
    },
    {
      "name": "state",
      "type": "string"
    },
    {
      "name": "country",
      "type": "string"
    }
  ]
}
```

## Working sample with rdkafka2 output plugin

As noted in the introduction, `fluent-plugin-avroturf-confluent` plugin is developed primary for `out_rdkafka2`. It may work with other output plugins but not tested yet.
Here is the sample configuration which serializes dummy messages into avro format with `avroturf_serializer` formatter plugin, and sends them to Kafka cluster in Confluent Cloud.

```
<source>
  @type dummy
  ### test_address2; 100009
  dummy {"state":"ca","city":"santa clara","country":"us"}
  tag dummy
</source>

<match dummy>
  @type rdkafka2

  ## Broker settings
  brokers "#{ENV['CONFLUENT_BOOTSTRAP_SERVERS']}"

  ## Kafka producer settings
  required_acks 1
  ack_timeout 20
  compression_codec snappy
  share_producer true

  ## SASL settings
  rdkafka_options {"security.protocol":"SASL_SSL","sasl.mechanisms":"PLAIN"}
  username "#{ENV['CONFLUENT_SASL_USERNAME']}"
  password "#{ENV['CONFLUENT_SASL_PASSWORD']}"

  ## topic settings
  default_topic topic-test-01

  <format>
    @type avroturf_serializer
    schema_registry_url "#{ENV['SCHEMA_REGISTRY_URL']}"
    schema_registry_api_key "#{ENV['SCHEMA_REGISTRY_API_KEY']}"
    schema_registry_api_secret "#{ENV['SCHEMA_REGISTRY_API_SECRET']}"
    schema_id 100009
  </format>

  <buffer>
    @type file
    path /data/fluentd/buffer/
    flush_interval 5s
    flush_thread_count 32
    queued_chunks_limit_size 32
    chunk_limit_size 1m
    total_limit_size 10000m
  </buffer>

</match>
```
Here is the sample Kafka Consumer application written in Ruby. 
```
### rdkafka_consumer_sasl_plaintext.rb
require 'rdkafka'
require 'avro_turf/messaging'
require 'avro_turf/confluent_schema_registry'

bootstrap_servers=ENV["CONFLUENT_BOOTSTRAP_SERVERS"]
security_protocol="SASL_SSL"
sasl_mechanisms="PLAIN"
sasl_username=ENV["CONFLUENT_SASL_USERNAME"]
sasl_password=ENV["CONFLUENT_SASL_PASSWORD"]

sr_url=ENV["SCHEMA_REGISTRY_URL"]
sr_api_key=ENV["SCHEMA_REGISTRY_API_KEY"]
sr_api_secret=ENV["SCHEMA_REGISTRY_API_SECRET"]

topic = "topic-test-01"

config = {
        :"bootstrap.servers" => bootstrap_servers,
        :"security.protocol" => security_protocol,
        :"sasl.mechanisms" => sasl_mechanisms,
        :"sasl.username" => sasl_username,
        :"sasl.password" => sasl_password,
        :"group.id" => "mygroup"
}

registry = AvroTurf::ConfluentSchemaRegistry.new(sr_url, user:sr_api_key, password:sr_api_secret)
avro = AvroTurf::Messaging.new(registry:registry)

rdkafka = Rdkafka::Config.new(config)
consumer = rdkafka.consumer
consumer.subscribe(topic)
consumer.each do |message|
	puts avro.decode(message.payload)
end
```
If you are using `fluent-package`, you can try out easily with the following command:
```
root@fluent-guest01 schema (test)$ /opt/fluent/bin/ruby rdkafka_consumer_sasl_plaintext.rb
I, [2023-10-24T23:04:28.019645 #363246]  INFO -- : Fetching schema with id 100009
{"city"=>"santa clara", "state"=>"ca", "country"=>"us"}
{"city"=>"santa clara", "state"=>"ca", "country"=>"us"}
{"city"=>"santa clara", "state"=>"ca", "country"=>"us"}
{"city"=>"santa clara", "state"=>"ca", "country"=>"us"}
```


## Copyright

* Copyright(c) 2023- Tomonori Kubota (TK)
* License
  * Apache License, Version 2.0
