FROM spark:3.5.0-scala2.12-java11-ubuntu as builder

USER root
# Add Dependencies for PySpark
RUN apt-get update && apt-get install -y curl vim wget software-properties-common ssh net-tools ca-certificates python3 python3-pip python3-numpy python3-matplotlib python3-scipy python3-pandas python3-simpy

RUN update-alternatives --install "/usr/bin/python" "python" "$(which python3)" 1

# Fix the value of PYTHONHASHSEED
# Note: this is needed when you use Python 3.3 or greater

# HADOOP_VERSION=3.2 \
ENV SPARK_VERSION=3.5.0 \
HADOOP_VERSION=3 \
SPARK_HOME=/opt/spark \
PYTHONHASHSEED=1

RUN wget --no-verbose -O apache-spark.tgz "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" \
&& mkdir -p /opt/spark \
&& tar -xf apache-spark.tgz -C /opt/spark --strip-components=1 \
&& rm apache-spark.tgz


FROM builder as apache-spark

WORKDIR /opt/spark

ENV SPARK_MASTER_PORT=7077 \
SPARK_MASTER_WEBUI_PORT=8080 \
SPARK_LOG_DIR=/opt/spark/logs \
SPARK_MASTER_LOG=/opt/spark/logs/spark-master.out \
SPARK_WORKER_LOG=/opt/spark/logs/spark-worker.out \
SPARK_WORKER_WEBUI_PORT=8080 \
SPARK_WORKER_PORT=7000 \
SPARK_MASTER="spark://spark-master:7077" \
SPARK_WORKLOAD="master"

EXPOSE 8080 7077 7000

RUN mkdir -p $SPARK_LOG_DIR && \
touch $SPARK_MASTER_LOG && \
touch $SPARK_WORKER_LOG && \
ln -sf /dev/stdout $SPARK_MASTER_LOG && \
ln -sf /dev/stdout $SPARK_WORKER_LOG


RUN mv /etc/localtime /etc/localtime-old
RUN ln -s /usr/share/zoneinfo/Europe/Moscow /etc/localtime

RUN apt install -y libpq5

RUN pip3 install psycopg
RUN pip3 install psycopg_pool
RUN pip3 install requests
RUN pip3 install python-dotenv
RUN pip3 install Elasticsearch
RUN pip3 install pyspark-extension==2.11.0.3.5


# The directory where the JAR will be saved
WORKDIR /opt/spark/jars

# Download the JAR file using wget
RUN wget -O spark-xml_2.12-0.17.0.jar https://repo1.maven.org/maven2/com/databricks/spark-xml_2.12/0.17.0/spark-xml_2.12-0.17.0.jar
RUN wget -O spark-extension_2.12-2.11.0-3.5.jar https://repo1.maven.org/maven2/uk/co/gresearch/spark/spark-extension_2.12/2.11.0-3.5/spark-extension_2.12-2.11.0-3.5.jar

WORKDIR /opt/spark

# RUN cp -rf /usr/local/lib/python3.7/dist-packages/psycopg /opt/spark/python/lib/psycopg
# RUN cp -rf /usr/local/lib/python3.7/dist-packages/psycopg_pool /opt/spark/python/lib/psycopg_pool
# RUN cp -rf /usr/local/lib/python3.7/dist-packages/* /opt/spark/python/lib/

RUN cp -rf /usr/local/lib/python3.8/dist-packages/psycopg /opt/spark/python/lib/psycopg
RUN cp -rf /usr/local/lib/python3.8/dist-packages/psycopg_pool /opt/spark/python/lib/psycopg_pool
RUN cp -rf /usr/local/lib/python3.8/dist-packages/* /opt/spark/python/lib/


RUN groupadd -g 1003 laradock
RUN useradd laradock -u 1003 -g 1003 -m -s /bin/bash

# USER laradock

COPY start-spark.sh /

CMD ["/bin/bash", "/start-spark.sh"]