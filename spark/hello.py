# ~/shopease-mega-platform/spark/hello.py
from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("hello").getOrCreate()

df = spark.range(0, 1_000_000).withColumnRenamed("id", "n")
count = df.count()
print(f"SPARK_SMOKE_TEST: rows={count} partitions={df.rdd.getNumPartitions()}")

spark.stop()