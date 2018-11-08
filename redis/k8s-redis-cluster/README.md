此yaml为Redis Cluster模式,用于简单部署持久化Redis Cluster,Redis版本为4.0.8

1. 创建namespace

    ````
        kubectl create namespace public-service
    ````
    
    其他namespace需要替换当前文件
    
    sed -i "s#public-service#YOUR_NAMESPACE#g" *

2. 首先创建pv所用目录

    ````
        NFS服务器：
        /k8s/redis-cluster/1 *(rw,sync,no_subtree_check,no_root_squash)
        /k8s/redis-cluster/2 *(rw,sync,no_subtree_check,no_root_squash)
        /k8s/redis-cluster/3 *(rw,sync,no_subtree_check,no_root_squash)
        /k8s/redis-cluster/4 *(rw,sync,no_subtree_check,no_root_squash)
        /k8s/redis-cluster/5 *(rw,sync,no_subtree_check,no_root_squash)
        /k8s/redis-cluster/6 *(rw,sync,no_subtree_check,no_root_squash)
    ````
    
3. 创建集群

    ````
        [root@k8s-master01 redis-cluster]# ls
        failover.py  redis-cluster-configmap.yaml  redis-cluster-rbac.yaml     redis-cluster-ss.yaml
        README.md    redis-cluster-pv.yaml         redis-cluster-service.yaml
        [root@k8s-master01 redis-cluster]# kubectl apply -f .
    ````
    
4. 创建slot

    ````
	# 等待所有pod启动完毕后，直接执行以下命令。

        v=""
        
        for i in `kubectl get po -n public-service -o wide | awk  '{print $6}' | grep -v IP`; do v="$v $i:6379";done

        kubectl exec -ti redis-cluster-ss-5 -n public-service -- redis-trib.rb create --replicas 1 $v
    ````

5. 查看状态

    ````
        [root@k8s-master01 ~]# kubectl exec -ti redis-cluster-ss-0 -n public-service -- redis-cli cluster nodesf9527e2ced3c472caabe3f815d87531e82e75049 172.168.5.174:6379@16379 master - 0 1541693210490 2 connected 5461-10922
        a47ef989862a2ddbf83c70d8191ff17c8b37a6fc 172.168.2.68:6379@16379 master - 0 1541693213497 3 connected 10923-16383
        b4c3d1ffe5ed70d2d40467d228004f4e0fb5fa25 172.168.5.175:6379@16379 slave f9527e2ced3c472caabe3f815d87531e82e75049 0 1541693216510 6 connected
        2aa4d2e5de3aca325bff95325102da72334a5164 172.168.1.76:6379@16379 master - 0 1541693214503 7 connected 0-5460
        74c6e2356e41c6842e05b043c48ce20b7f1ad3ae 172.168.0.95:6379@16379 slave a47ef989862a2ddbf83c70d8191ff17c8b37a6fc 0 1541693215504 4 connected
        2d5389ff7ff6b6dcc5cff83654a6e15c9c4a7750 172.168.6.170:6379@16379 myself,slave 2aa4d2e5de3aca325bff95325102da72334a5164 0 1541692127160 1 connected
        [root@k8s-master01 ~]# kubectl exec -ti redis-cluster-ss-0 -n public-service -- redis-cli cluster info
        cluster_state:ok
        cluster_slots_assigned:16384
        cluster_slots_ok:16384
        cluster_slots_pfail:0
        cluster_slots_fail:0
        cluster_known_nodes:6
        cluster_size:3
        cluster_current_epoch:7
        cluster_my_epoch:7
        cluster_stats_messages_ping_sent:1158
        cluster_stats_messages_pong_sent:1203
        cluster_stats_messages_sent:2361
        cluster_stats_messages_ping_received:1203
        cluster_stats_messages_pong_received:1142
        cluster_stats_messages_received:2345
    ````
    
6. 其他说明

    ````
        创建Redis Cluster集群不一定非要用sts，用dc也一样。
        终止某一个pod虽然IP会变，但是不会影响集群完整性，会自我恢复。
        测试过终止所有Redis Cluster POD，此时集群无法正常恢复，使用failover.py(由于时间匆忙，随便写的)会恢复集群，
        并且不会丢失已保存的数据。
    ````

