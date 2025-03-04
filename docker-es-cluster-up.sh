#/bin/bash
# 由于我本机内存只有 32G，分配给 5 个ES 实例每个 2G 的话就是 10G 没了，所以只开2个.
cd docker-es-master && docker-compose up -d && \
cd ../docker-es-data01 && docker-compose up -d && \
cd ../docker-es-data02 && docker-compose up -d && \
# cd ../docker-es-data03 && docker-compose up -d && \
# cd ../docker-es-tribe && docker-compose up -d && \
cd ../kibana && docker-compose up -d && \
cd ..
