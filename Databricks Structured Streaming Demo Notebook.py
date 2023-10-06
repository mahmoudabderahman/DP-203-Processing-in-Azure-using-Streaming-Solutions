# Databricks notebook source
# MAGIC %python
# MAGIC
# MAGIC import json
# MAGIC
# MAGIC connectionString = "<connection-string-including-entity-path>"
# MAGIC
# MAGIC startingEventPosition = {
# MAGIC   "offset": "-1",
# MAGIC   "seqNo": -1,            # not in use
# MAGIC   "enqueuedTime": None,   # not in use
# MAGIC   "isInclusive": True
# MAGIC }
# MAGIC
# MAGIC eventHubsConf = {
# MAGIC   "eventhubs.connectionString" : sc._jvm.org.apache.spark.eventhubs.EventHubsUtils.encrypt(connectionString),
# MAGIC   "eventhubs.startingPosition" : json.dumps(startingEventPosition),
# MAGIC   "setMaxEventsPerTrigger": 100
# MAGIC }

# COMMAND ----------

# MAGIC %python
# MAGIC
# MAGIC from pyspark.sql.functions import col
# MAGIC
# MAGIC spark.conf.set("spark.sql.shuffle.partitions", sc.defaultParallelism)
# MAGIC
# MAGIC eventStreamDF = (spark.readStream
# MAGIC   .format("eventhubs")
# MAGIC   .options(**eventHubsConf)
# MAGIC   .load()
# MAGIC )
# MAGIC
# MAGIC eventStreamDF.printSchema()

# COMMAND ----------

from pyspark.sql.types import StructField, StructType, StringType, LongType, DoubleType, TimestampType

schema = StructType([
  StructField("Player", StringType(), False),
  StructField("Game", LongType(), False),
  StructField("Score", StringType(), False),
  StructField("Timestamp", TimestampType(), False)
])

bodyDF = eventStreamDF.select(col("body").cast("STRING"))

# COMMAND ----------

from pyspark.sql.functions import col, from_json, from_unixtime

parsedEventsDF = bodyDF.select(
  from_json(col("body"), schema).alias("json"))

flatEventDF = (parsedEventsDF
  .select(col("json.Player").alias("Player"),
          col("json.Game").alias("Game"),
          col("json.Score").alias("Score"),
          col("json.Timestamp")).alias("Timestamp"))

# COMMAND ----------

filteredEventsDF = flatEventDF.where("Score>75")

# COMMAND ----------

filteredEventsDF.writeStream \
    .format("delta") \
    .option("checkpointLocation", "delta-checkpoints/game-good-scores") \
    .start("/delta-tables/game-good-scores")

# COMMAND ----------

# MAGIC %sql
# MAGIC CREATE TABLE GoodGameResults
# MAGIC USING DELTA
# MAGIC LOCATION '/delta-tables/game-good-scores';

# COMMAND ----------

# MAGIC %sql
# MAGIC
# MAGIC SELECT *
# MAGIC FROM GoodGameResults;

# COMMAND ----------


