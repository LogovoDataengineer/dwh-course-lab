# Spark 3.5 для уроков 22–24: S3 (MinIO), Iceberg с каталогом в PostgreSQL, Delta Lake, драйвер PostgreSQL.
FROM apache/spark:3.5.6-scala2.12-java17-python3-ubuntu
USER root
ARG MAVEN=https://repo1.maven.org/maven2
ADD --chmod=644 ${MAVEN}/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar /opt/spark/jars/
ADD --chmod=644 ${MAVEN}/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar /opt/spark/jars/
ADD --chmod=644 ${MAVEN}/org/apache/iceberg/iceberg-spark-runtime-3.5_2.12/1.9.2/iceberg-spark-runtime-3.5_2.12-1.9.2.jar /opt/spark/jars/
ADD --chmod=644 ${MAVEN}/org/apache/iceberg/iceberg-aws-bundle/1.9.2/iceberg-aws-bundle-1.9.2.jar /opt/spark/jars/
ADD --chmod=644 ${MAVEN}/io/delta/delta-spark_2.12/3.3.2/delta-spark_2.12-3.3.2.jar /opt/spark/jars/
ADD --chmod=644 ${MAVEN}/io/delta/delta-storage/3.3.2/delta-storage-3.3.2.jar /opt/spark/jars/
ADD --chmod=644 ${MAVEN}/org/postgresql/postgresql/42.7.4/postgresql-42.7.4.jar /opt/spark/jars/
ADD --chmod=644 ${MAVEN}/org/apache/spark/spark-avro_2.12/3.5.6/spark-avro_2.12-3.5.6.jar /opt/spark/jars/
# Сертификат прокси нужен только за корпоративным прокси (compose.proxy.yaml); в Codespaces его нет.
RUN --mount=type=secret,id=proxy_ca,required=false \
    pip install --no-cache-dir $(test -s /run/secrets/proxy_ca && echo --cert /run/secrets/proxy_ca) \
      delta-spark==3.3.2 pyarrow==19.0.1 pandas==2.2.3
COPY spark-defaults.conf /opt/spark/conf/spark-defaults.conf
ENV PATH=/opt/spark/bin:$PATH PYSPARK_PYTHON=python3
USER spark
