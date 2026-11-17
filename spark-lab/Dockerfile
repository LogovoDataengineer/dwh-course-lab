FROM apache/spark:3.5.6-scala2.12-java17-python3-ubuntu
USER root
RUN python3 -m pip install --no-cache-dir jupyterlab==4.4.9 ipykernel==6.30.1 nbclient==0.10.2 \
    && if ! getent passwd 1000 >/dev/null; then useradd -m -u 1000 -U lab; fi \
    && mkdir -p /home/lab /opt/spark-events /opt/spark/work /opt/work/results \
    && chown -R 1000:1000 /home/lab /opt/spark-events /opt/spark/work /opt/work
COPY spark-defaults.conf /opt/spark/conf/spark-defaults.conf
COPY jupyter_server_config.py /etc/jupyter/jupyter_server_config.py
ENV HOME=/home/lab USER=lab SPARK_HOME=/opt/spark \
    PYSPARK_PYTHON=python3 PYSPARK_DRIVER_PYTHON=python3 \
    PYTHONPATH=/opt/spark/python:/opt/spark/python/lib/py4j-0.10.9.7-src.zip \
    PATH=/opt/spark/bin:$PATH
USER 1000:1000
WORKDIR /opt/work
