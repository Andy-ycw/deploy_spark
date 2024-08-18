#!/bin/bash

exec 2>>/home/error.log

cd /usr/local

# Install JDK
aws s3 cp s3://${pkg_bucket}/${jdk_name}.tar /usr/local/${jdk_name}.tar
sudo tar -xvf ${jdk_name}.tar
sudo rm ${jdk_name}.tar
echo "export JAVA_HOME=/usr/local/${jdk_name}" >> /home/.bashrc
echo "export PATH=/usr/local/${jdk_name}/bin:$${PATH}" >> /home/.bashrc
source /home/.bashrc

# Install hadoop
cd /usr/local
aws s3 cp s3://${pkg_bucket}/hadoop-3.3.4.tar /usr/local/hadoop-3.3.4.tar
sudo tar -xvf hadoop-3.3.4.tar
sudo rm hadoop-3.3.4.tar
echo "export JAVA_HOME=$${JAVA_HOME}" >> /usr/local/hadoop-3.3.4/etc/hadoop/hadoop-env.sh
echo "export HADOOP_HOME=/usr/local/hadoop-3.3.4" >> /home/.bashrc
echo "export PATH=/usr/local/hadoop-3.3.4/bin:$${PATH}" >> /home/.bashrc
source /home/.bashrc

# Copy the S3 connector jars to the common lib in hadoop from tools lib
cd $${HADOOP_HOME}/share/hadoop/tools/lib
sudo cp hadoop-aws-3.3.4.jar $${HADOOP_HOME}/share/hadoop/common/lib/hadoop-aws-3.3.4.jar
sudo cp aws-java-sdk-bundle-1.12.262.jar $${HADOOP_HOME}/share/hadoop/common/lib/aws-java-sdk-bundle-1.12.262.jar

# Install Spark
cd /usr/local
aws s3 cp s3://${pkg_bucket}/spark-3.5.1-bin-hadoop3.tar /usr/local/spark-3.5.1-bin-hadoop3.tar
sudo tar -xvf spark-3.5.1-bin-hadoop3.tar
sudo rm spark-3.5.1-bin-hadoop3.tar
echo "export SPARK_HOME=/usr/local/spark-3.5.1-bin-hadoop3" >> /home/.bashrc
echo "export PATH=/usr/local/spark-3.5.1-bin-hadoop3/bin:$${PATH}" >> /home/.bashrc 
source /home/.bashrc

# Grab S3 connector jars provided by hadoop
cd $${HADOOP_HOME}/share/hadoop/tools/lib
sudo cp hadoop-aws-3.3.4.jar $${SPARK_HOME}/jars/hadoop-aws-3.3.4.jar
sudo cp aws-java-sdk-bundle-1.12.262.jar $${SPARK_HOME}/jars/aws-java-sdk-bundle-1.12.262.jar

# Load Spark config
config_file="$${SPARK_HOME}/conf/spark-defaults.conf"
public_ip=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
private_ip=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)

# Write the config file.
echo "spark.master spark://$${private_ip}:7077" >> $${config_file} 
echo "spark.eventLog.enabled false" >> $${config_file} 
# echo "spark.eventLog.dir s3a://YOUR_BUCKET_NAME/" >> $${config_file} 
echo "spark.driver.memory ${spark_driver_memory}" >> $${config_file} 
echo "spark.driver.core ${spark_driver_core}" >> $${config_file} 
echo "spark.executor.memory ${spark_executor_memory}" >> $${config_file}
echo "spark.executor.core ${spark_executor_core}" >> $${config_file}
echo "spark.driver.extraJavaOptions -Dio.netty.tryReflectionSetAccessible=true" >> $${config_file}
echo "spark.executor.extraJavaOptions -Dio.netty.tryReflectionSetAccessible=true" >> $${config_file}
echo "spark.hadoop.fs.s3a.impl org.apache.hadoop.fs.s3a.S3AFileSystem" >> $${config_file}
echo "spark.jars $${SPARK_HOME}/jars/${hadoop_aws}.jar,$${SPARK_HOME}/jars/${aws_java_sdk}.jar" >> $${config_file}
echo "spark.driver.host $${private_ip}" >> $${config_file}
echo "spark.driver.bindAddress $${private_ip}" >> $${config_file}
echo "spark.executor.bindAddress $${private_ip}" >> $${config_file}

# Write Spark env file
env_file="$${SPARK_HOME}/conf/spark-env.sh"
if [ "${node}" = "bastion" ]; then
    echo "SPARK_LOCAL_IP=$${private_ip}" >> $${env_file} 
elif [ "${node}" = "master" ]; then
    echo "SPARK_MASTER_HOST=$${private_ip}" >> $${env_file} 
elif [ "${node}" = "slave" ]; then
    echo "SPARK_LOCAL_IP=$${private_ip}" >> $${env_file} 
fi

if [ "${node}" = "master" ]; then
    $${SPARK_HOME}/sbin/start-master.sh
elif [ "${node}" = "slave" ]; then
    $${SPARK_HOME}/sbin/start-worker.sh spark://${master_ip}:7077
fi
