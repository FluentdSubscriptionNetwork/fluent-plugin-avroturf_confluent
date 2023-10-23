# Introduction : fluent-plugin-avroturf-confluent
Schema Registry manages and stores schemas of data that are exchanged between different services. It is commonly used in Apache Kafka to ensure that data being exchanged between different producers and comsumers adheres to a predefined schema or data structure. `fluent-plugin-avroturf-confluent` is formatter plugin developed for `fluent-plugin-kafka/out_rdkafka2` to serialize messages in key-value pairs format into Avro format before shipping messages to Kafka brokers. The plugin uses [AvroTurf](https://github.com/dasch/avro_turf) library to register/fetch schemas from the Schema Registry provided by Confluent Cloud and serialize key-value pairs into avro format.

## Installation

### RubyGems
For vanila Fluentd :
```
$ gem install fluent-plugin-avroturf-confluent
```
For td-agent v4 or later (scheduled EoL on Dec 2023) :
```
$ /opt/td-agent/bin/fluent-gem install fluent-plugin-avroturf-confluent
```
For fluent-package v5 or later :
```
$ /opt/fluent/bin/fluent-gem install fluent-plugin-avroturf-confluent
```

## Configuration
### Available Options of `avroturf_serializer` formatter
The following options are mandatory to access Schema Registry
- schema_registry_url : URL of Schema Resigtry
- schema_registry_api_key : API key to access Schema Resigtry
- schema_registry_api_secret : API Secret to access Schema Resigtry

The options below are required to configure based on schema fetching patterns.
- schema_subject : Subject name of schema (default: nil)
- schema_version : Version of schema (default: nil)
- schema_id : ID of schema (default: nil)
- schemas_path : Path of directory which stores avsc files (default: nil)
- schema_name : Name of schema  (default: nil)
- validate : 

### Configuration Patterns
There are 3 configuration patterns to fetch schema.
- Pattern#1 : Get schema with subject name and its version
  - In this pattern, it is required to configure both `schema_subject` and `schema_version`.
  - `schema_subject` can be checked through Confluent Cloud web console or HTTP API.
  - 
- Pattern#2 : Get schema with ID
  -  
- Pattern#3 : Get schema from avsc




If you are using Confluent Cloud, you can check the subject name of schema at web console.


**Pattern#1 : Get schema with ID**

In this case, it is required to configure both `schema_subject` and `schema_version`

In this case, it is required to configure both `schema_subject` and `schema_version`

```
<format>
  @type avroturf_serializer
  schema_registry_url "#{ENV['SCHEMA_REGISTRY_URL']}"
  schema_registry_api_key "#{ENV['SCHEMA_REGISTRY_API_KEY']}"
  schema_registry_api_secret "#{ENV['SCHEMA_REGISTRY_API_SECRET']}"

  ### Pattern#1 : Get schema with subject name and version
  schema_subject test_address1
  schema_version 1
  validate true

  ### Pattern#2 : Get schema with ID
  #schema_id 100005

  ### Pattern#3 : Get schema from avsc
  #schemas_path /root/git/fluent-confluent-cloud/schema
  #schema_name test_address1
</format>
```

As noted in the introduction, `fluent-plugin-avroturf-confluent` plugin is developed primary for `out_rdkafka2`. It may work with other output plugins but not tested yet.
Here is the sample configuration which serializes dummy messages into avro format with `avroturf_serializer` formatter plugin, and sends them to Kafka cluster in Confluent Cloud.

```
<source>
  @type dummy
  ### test_address1; 100005
  dummy {"state":"ca","city":"santa clara"}
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

    ### Pattern#1 : Get schema with subject name and version
    schema_subject test_address1
    schema_version 1
    validate true

    ### Pattern#2 : Get schema with ID
    #schema_id 100005

    ### Pattern#3 : Get schema from avsc
    #schemas_path /root/git/fluent-confluent-cloud/schema
    #schema_name test_address1
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

You can copy and paste generated documents here.

## Copyright

* Copyright(c) 2023- Tomonori Kubota (TK)
* License
  * Apache License, Version 2.0
