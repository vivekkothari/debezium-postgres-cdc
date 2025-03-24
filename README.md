# Debezium Postgres working example

## Steps to test this

1. Check out this repo.
2. Run `docker compose up -d`
3. The run this CURL
   https://debezium.io/documentation/reference/stable/connectors/postgresql.html#postgresql-required-configuration-properties
Above link shows all config properties.
```
curl -X POST http://localhost:8083/connectors -H "Content-Type: application/json" -d '{
  "name": "debezium-postgres-connector",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "database.hostname": "postgresql",
    "database.port": "5432",
    "database.user": "postgres",
    "database.password": "password",
    "database.dbname": "test",
    "plugin.name": "pgoutput",
    "slot.name": "debezium_slot",
    "publication.autocreate.mode": "all_tables",
    "publication.name": "dbz_publication",
    "database.history.kafka.bootstrap.servers": "kafka1:9092",
    "database.history.kafka.topic": "schema-changes.test",
    "topic.prefix": "test",
    "replica.identity.autoset.values": "*:DEFAULT",
    "tombstones.on.delete": "true",
    "skipped.operations": "none",
    "key.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter"
  }
}'
```

Few things to note:

1. Debezium needs a user with `replication_role`
2. It also needs ownership of the table which you want to watch.
   Thus, I am using `postgres` user which us a super user in the bitnami images.

## Verify things
![CleanShot 2025-03-23 at 20 43 38@2x](https://github.com/user-attachments/assets/4eb600d6-8eca-414d-9040-99c9c2befa87)

![CleanShot 2025-03-23 at 20 44 06@2x](https://github.com/user-attachments/assets/5ee330b3-5550-4f77-bf02-c6f53f8c2f34)


1. An `employee` should be automatically created when to bring up docker.
2. Run following cURL to check the status, it should be in running state.

```
curl -X GET http://localhost:8083/connectors/debezium-postgres-connector/status | jq   
  
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   183  100   183    0     0  16456      0 --:--:-- --:--:-- --:--:-- 16636
{
  "name": "debezium-postgres-connector",
  "connector": {
    "state": "RUNNING",
    "worker_id": "172.19.0.5:8083"
  },
  "tasks": [
    {
      "id": 0,
      "state": "RUNNING",
      "worker_id": "172.19.0.5:8083"
    }
  ],
  "type": "source"
}
```

3. Do a insert like `insert into employee (id, name, email) values (1, 'vivek', 'foo@bar.com');`
4. Goto `http://localhost:8080/ui/clusters/debz_connector_cluster/all-topics/` there should be a topic with name
   `test.public.employee`
5. The message should be sent to the topic.
6. Start `com.github.vivekkothari.cdc.DebeziumConsumer` to start consumer.
7. Now start making some inserts/update/deletes to employee table.
8. You should see logs like,

```
025-03-23 20:17:56 [main] INFO  o.a.k.c.c.internals.ConsumerUtils - Setting offset for partition test.public.employee-0 to the committed offset FetchPosition{offset=1, offsetEpoch=Optional[0], currentLeader=LeaderAndEpoch{leader=Optional[localhost:9092 (id: 2 rack: null isFenced: false)], epoch=0}}
{"schema":{"type":"struct","fields":[{"type":"struct","fields":[{"type":"int32","optional":false,"field":"id"},{"type":"string","optional":true,"field":"name"},{"type":"string","optional":true,"field":"email"}],"optional":true,"name":"test.public.employee.Value","field":"before"},{"type":"struct","fields":[{"type":"int32","optional":false,"field":"id"},{"type":"string","optional":true,"field":"name"},{"type":"string","optional":true,"field":"email"}],"optional":true,"name":"test.public.employee.Value","field":"after"},{"type":"struct","fields":[{"type":"string","optional":false,"field":"version"},{"type":"string","optional":false,"field":"connector"},{"type":"string","optional":false,"field":"name"},{"type":"int64","optional":false,"field":"ts_ms"},{"type":"string","optional":true,"name":"io.debezium.data.Enum","version":1,"parameters":{"allowed":"true,last,false,incremental"},"default":"false","field":"snapshot"},{"type":"string","optional":false,"field":"db"},{"type":"string","optional":true,"field":"sequence"},{"type":"int64","optional":true,"field":"ts_us"},{"type":"int64","optional":true,"field":"ts_ns"},{"type":"string","optional":false,"field":"schema"},{"type":"string","optional":false,"field":"table"},{"type":"int64","optional":true,"field":"txId"},{"type":"int64","optional":true,"field":"lsn"},{"type":"int64","optional":true,"field":"xmin"}],"optional":false,"name":"io.debezium.connector.postgresql.Source","field":"source"},{"type":"struct","fields":[{"type":"string","optional":false,"field":"id"},{"type":"int64","optional":false,"field":"total_order"},{"type":"int64","optional":false,"field":"data_collection_order"}],"optional":true,"name":"event.block","version":1,"field":"transaction"},{"type":"string","optional":false,"field":"op"},{"type":"int64","optional":true,"field":"ts_ms"},{"type":"int64","optional":true,"field":"ts_us"},{"type":"int64","optional":true,"field":"ts_ns"}],"optional":false,"name":"test.public.employee.Envelope","version":2},"payload":{"before":null,"after":{"id":2,"name":"kothari","email":"foo1@bar.com"},"source":{"version":"3.0.0.Final","connector":"postgresql","name":"test","ts_ms":1742741274875,"snapshot":"false","db":"test","sequence":"[\"26737640\",\"26738904\"]","ts_us":1742741274875866,"ts_ns":1742741274875866000,"schema":"public","table":"employee","txId":752,"lsn":26738904,"xmin":null},"transaction":null,"op":"c","ts_ms":1742741275319,"ts_us":1742741275319425,"ts_ns":1742741275319425296}}
```
