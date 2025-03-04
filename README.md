## 一、前言
`Docker Compose`是 `docker` 提供的一个命令行工具，用来定义和运行由多个容器组成的应用。使用 `compose`，我们可以通过 `YAML`或者`YML` 文件声明式的定义应用程序的各个服务，并由单个命令完成应用的创建和启动。
`ElasticSearch`版本为7.17.27。分词器也为7.17.27，分词器可以去官网下载，本文用的ik中文分词。
## 二、Mac docker 和docker-compose安装
### 2.1 Docker官网安装 Docker Desktop

Mac安装很简单，只需要到[Docker Desktop 官网](https://www.docker.com/products/docker-desktop/)去下载对应 OS版本的就行，下载安装完会自动帮你加载 docker 和 docker-compose，不过当你需要使用时需要把这个 desktop 打开。否则 docker 就无法使用。
<img width="1680" alt="image-20250304092837863" src="https://github.com/user-attachments/assets/79a210ab-811e-4210-849d-974d40620ff4" />

### 2.2 查看版本

```bash
docker version
docker-compose version
```
<img width="630" alt="image-20250304093105654" src="https://github.com/user-attachments/assets/8c0bc3d5-108a-445d-9021-27aef56468c4" />

之后需要更改 docker 的国内源，由于 hub.docker 官网国内限制挺大的，一般我们如果直接用pull 镜像下来会非常慢。所以尽量采用国内源。推荐去[这个网站](https://www.coderjia.cn/archives/dba3f94c-a021-468a-8ac6-e840f85867ea)去找最新的 docker 国内源地址。之后在 Desktop 里设置里找到 Docker Engine 然后将国内源替换进去。
<img width="1579" alt="image-20250304093500884" src="https://github.com/user-attachments/assets/ef71adbd-7069-4785-9897-0db099095856" />

### **2.3 修改 docker desktop 中允许连接本地网络**

由于 Mac 原生不支持本地连接，所以Mac需要在 docker-hub 里打开设置，找到 Resources，其中有一个 NetWork,勾选里面的Enable host networking

<img width="1564" alt="image-20250304114055580" src="https://github.com/user-attachments/assets/8748a3e3-8270-4978-a5a6-6178de9c6c5c" />



## 三、集群架构

### 3.1 结构图及解释
<img width="953" alt="image-20250304122813671" src="https://github.com/user-attachments/assets/760a18e5-5be4-4db4-a0d8-17e2eb930045" />


- `Master`节点作为`Master`节点与协调节点，为防止脑裂问题，降低负载，不存数据

- `Node1~Node3`为数据节点，不参与`Master`竞选

- `TribeNode`节点不存数据，不参与`Master`竞选

### 3.2 集群划分
| 节点目录         | 节点名称 | 协调端口号 | 说明                         | 查询端口号 | 节点IP |
| ---------------- | -------- | ---------- | ---------------------------- | ---------- | ---------- |
| docker-es-master | master   | 9300      | master节点，非数据节点       | 9200      | 本机 ip |
| docker-es-data01 | data01   | 9301     | 数据节点1，非master节点      | 9201      | 本机 ip |
| docker-es-data02 | data02   | 9302     | 数据节点2，非master节点      | 9202      | 本机 ip |
| docker-es-data03 | data03   | 9303      | 数据节点3，非master节点      | 9203      | 本机 ip |
| docker-es-tribe  | tribe    | 9304      | 协调节点，非master非数据节点 | 9204     | 本机 ip |

## 四、集群配置
### 4.1 目录结构
下载地址：https://github.com/RobetLxx/ES_DockerCompose_Mac_Cluster
```bash
.
├── docker-es-cluster-down.sh
├── docker-es-cluster-stop.sh
├── docker-es-cluster-up.sh
├── docker-es-data01
│   ├── data01
│   ├── data01-logs
│   ├── docker-compose.yml
│   ├── .env
│   └── es-config
│       └── elasticsearch.yml
├── docker-es-data02
│   ├── data02
│   ├── data02-logs
│   ├── docker-compose.yml
│   ├── .env
│   └── es-config
│       └── elasticsearch.yml
├── docker-es-data03
│   ├── data03
│   ├── data03-logs
│   ├── docker-compose.yml
│   ├── .env
│   └── es-config
│       └── elasticsearch.yml
├── docker-es-master
│   ├── docker-compose.yml
│   ├── .env
│   ├── es-config
│   │   └── elasticsearch.yml
│   ├── master-data
│   └── master-logs
├── docker-es-tribe
│   ├── docker-compose.yml
│   ├── .env
│   ├── es-config
│   │   └── elasticsearch.yml
│   ├── tribe-data
│   └── tribe-logs
├── kibana
│   └── docker-compose.yml
└── plugins
    └── elasticsearch-analysis-ik-7.17.27
```
### 4.2 集群配置说明
#### 4.2.1 master节点docker-compose.yml配置说明
`docker-compose.yml` 是`docker-compose`的配置文件
```bash
services:
    es-master:
        image: elasticsearch:7.17.27
        container_name: es-master
        environment: # setting container env
            - ES_JAVA_OPTS=${ES_JVM_OPTS}   # set es bootstrap jvm args
        ulimits:
          memlock:
            soft: -1
            hard: -1
          nofile:
            soft: 65536
            hard: 65536
        restart: always
        volumes:
            - ./es-config/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml
            # es data路径
            - ${MASTER_DATA_DIR}:/usr/share/elasticsearch/data:rw
            # es log路径
            - ${MASTER_LOGS_DIR}:/usr/share/elasticsearch/logs:rw
            # 集成分词插件
            - ${MASTER_PLUGINS_DIR}:/usr/share/elasticsearch/plugins/elasticsearch-analysis-ik-7.17.27
        #由于 Mac 原生不支持本地连接，所以Mac需要在 docker-hub 里打开设置，找到 Resources，其中有一个 NetWork,勾选里面的Enable host networking
        network_mode: "host"
```
> 修改`pull`的镜像，替换其中的变量与配置文件，挂载数据与日志目录，最后用的`host`主机模式，让节点服务占用到实体机端口

>启动`ElasticSearch` 时如果提示无法访问日志或数据目录的问题可以通过,在`docker-compose.yml`的`environment`节点下添加`- TAKE_FILE_OWNERSHIP=true`

#### 4.2.2 master节点elaticsearch.yml配置说明
`elaticsearch.yml` 是`ElasticSearch`的配置文件，搭建集群最关键的文件之一

```bash
# ======================== Elasticsearch Configuration =========================
cluster.name: es-cluster
node.name: master 
node.attr.rack: r1 
# node.master: true
# node.data: false
node.roles: [master]
path.data: /usr/share/elasticsearch/data
path.logs: /usr/share/elasticsearch/logs
bootstrap.memory_lock: true 
network.host: 0.0.0.0
http.port: 9200
transport.tcp.port: 9300
discovery.seed_hosts: ["192.168.2.101:9301","192.168.2.101:9302","192.168.2.101:9303","192.168.2.101:9304"] 
cluster.initial_master_nodes: ["master"] 
#gateway.recover_after_data_nodes: 2
http.cors.enabled: true
http.cors.allow-origin: "*"
http.cors.allow-methods: OPTIONS, HEAD, GET, POST, PUT, DELETE
http.cors.allow-headers: "X-Requested-With, Content-Type, Content-Length, X-User, Authorization"
ingest.geoip.downloader.enabled: false
#最好还是开开，只不过开开后需要设置一下账户密码比较麻烦，我本地用就不开了
xpack.ml.enabled: false
```
> - `transport.tcp.port` 设置`Elaticsearch`多节点协调的端口号
>- `discovery.seed_hosts` 设置当前节点启动后要发现的协调节点位置，当然自己不需要发现自己，推荐使用`ip:port`形式，集群形成快
>- `cluster.initial_master_nodes` 集群中可以成为`master`节点的节点名，这里指定唯一的一个，防止脑裂

#### 4.2.4 master节点.env配置说明
`.env` 这个文件为`docker-compose.yml`提供默认参数，方便修改

```bash
# the default environment for es-master
# set es node jvm args
ES_JVM_OPTS=-Xms2048m -Xmx2048m
# set master node data folder
MASTER_DATA_DIR=./master-data
# set master node logs folder
MASTER_LOGS_DIR=./master-logs
# 插件目录
MASTER_PLUGINS_DIR=../plugins/elasticsearch-analysis-ik-7.17.27
```


## 五、使用说明
### 5.1 多服务器环境使用说明
1. 若想将此脚本使用到生产上，需要修改每个节点下的`.env文件`，`将挂载数据`、`日志目录`修改为启动`Elaticsearch`的集群的用户可读写的位置，可以通过`sudo chmod 777 -R 目录` 或 `sudo chown -R 当前用户名:用户组 目录` 来修改被挂载的目录权限。

2. 修改`.env`下的`JVM`参数，扩大堆内存，启动与最大值最好相等，以减少`gc`次数，提高效率。

3. 修改所有节点下的`docker-compose.yml` 中的`network.host`地址 为当前所放置的主机的`ip`，`discovery.seed_hosts`需要填写具体各待发现节点的实体机`ip`，以确保可以组成集群。

4. 确保各端口在其宿主机上没有被占用，如有占用需确认是否有用，无用`kill`，有用则更新`docker-compose.yml`的`http.port`或`transport.tcp.port`，注意与此同时要更新其它节点的`discovery.seed_hosts`对应的`port`。

5. `docker-compose up -d`后台启动命令。

6. `docker-compose down`关闭同时移除容器与多余虚拟网卡。

7. `docker stop contains_name`根据容器名称关闭容器，不移除容器。

### 5.2 单服务环境使用说明
1. `sudo sh docker-es-cluster-up.sh`创建并启动集群
2. `sudo sh docker-es-cluster-stop.sh`停止集群
3. `sudo sh docker-es-cluster-down.sh`停止并移除集群
>- 如果你想让这些脚本有执行权限，不妨试试sudo chmod +x *.sh
>- 这些脚本中没有使用sudo，如需要使用sudo才能启动docker,请添加当前用户到docker组

4. **建议把所有节点的 数据文件夹和日志文件删除再启动** data和 log 文件夹。

## 六、启动服务的常见问题
### 6.1 `max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]`
问题翻译过来就是：`Elasticsearch`用户拥有的内存权限太小，至少需要`262144`；

解决办法：

执行命令：

```bash
sudo sysctl -w vm.max_map_count=262144
```

查看结果：

```bash
sudo  sysctl -a|grep vm.max_map_count
```

显示：

```bash
vm.max_map_count = 262144
```

上述方法修改之后，如果重启虚拟机将失效，所以：

在   `/etc/sysctl.conf`文件最后添加一行，`vm.max_map_count=262144`，即可永久修改

### 6.2 `memory locking requested for elasticsearch process but memory is not locked`
解决方法一，关闭`bootstrap.memory_lock`，会影响性能

```bash
vim elasticsearch.yml          // 设置成false就正常运行了。
bootstrap.memory_lock: false
```
解决方法二，开启`bootstrap.memory_lock`
1. 修改文件`elasticsearch.yml`，上面那个报错就是开启后产生的，如果开启还要修改其它系统配置文件 

```bash
vim elasticsearch.yml
bootstrap.memory_lock: true
```

2. 修改文件`/etc/security/limits.conf`，最后添加以下内容。      

```bash
* soft nofile 65536

* hard nofile 65536

* soft nproc 32000

* hard nproc 32000

* hard memlock unlimited

* soft memlock unlimited
```

3. 修改文件 `/etc/systemd/system.conf` ，分别修改以下内容。

```bash
DefaultLimitNOFILE=65536

DefaultLimitNPROC=32000

DefaultLimitMEMLOCK=infinity
```

改好后**重启系统**。再启动`Elasticsearch`就没报错了 。

## 七、效果验证

```bash
docker ps 
```

<img width="1023" alt="image-20250304120049835" src="https://github.com/user-attachments/assets/071720c1-fea1-4b6a-9230-38a3ef4ed05b" />


命令行输入`curl http://localhost:9200/_cat/health`或者浏览器打开http://localhost:9200/_cat/health?v 查看集群状态，出现如下信息则集群搭建成功
<img width="1821" alt="image-20250304115928407" src="https://github.com/user-attachments/assets/6a10ec36-b72a-4e71-abca-b74f49d69152" />

