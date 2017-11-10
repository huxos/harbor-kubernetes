### kubernetes-harbor

>部署harbor到kubernetes的模板, 根据官方提供的compose模板转换而来。

adminserver、jobservice、ui、nginx、registry部署到同一个deployment中。
registry建议采用ceph的RGW做后端，可以灵活的扩容。
mysql单独部署，根据StorageClass配置持久存储。

#### 部署步骤

1. 生成证书

    ```
    export GOPATH=${GOPATH:-$HOME/go}
    go get -u github.com/cloudflare/cfssl/cmd/...
    export PATH=$GOPATH/bin:$PATH
    cd certs
    ##编辑harbor.json, 替换里面需要签名的域名「registry.example.com」
    ./generate_cert.sh
    ```

2. 创建ns、导入证书

    ```
    kubectl create ns registry
    kubectl -n registry create secret tls harbor --key=certs/harbor-key.pem --cert=certs/harbor.pem
    ```

3. 部署mysql组件

    ```
    ## mysql使用的存储
    kubectl create -f pvc/mysql-data.yaml
    ## 导入mysql的环境变量
    kubectl create -f cm/db-env.yaml
    ## 部署mysql
    kubectl create -f mysql.deploy.yaml
    # svc
    kubectl create -f svc/mysql.yaml
    ```

4. 部署redis

    ```
    kubectl create -f redis.deploy.yaml
    kubectl create -f svc/redis.yaml
    ```

5. 部署harbor

    ```
    #编辑 cm/adminserver-env.conf 替换掉里面的「EXT_ENDPOINT: <https://registry.example.com>」
    kubectl create -f cm/adminserver.yaml -f cm/adminserver-env.yaml

    #jobservice
    kubectl create -f cm/jobservice.yaml -f cm/jobservice-env.yaml

    #编辑 cm/registry.yaml「swift的配置」和「realm: <https://registry.example.com/service/token>」
    kubectl create -f cm/registry.yaml

    #ui
    kubectl create -f cm/ui-env.yaml -f cm/ui.yaml

    #nginx
    kubectl create -f cm/nginx.yaml

    #部署harbor
    kubectl create -f harbor.deploy.yaml
	
    #部署ingresses
    kubectl create -f ing/harbor.ing.yaml 
    ```
6. 配置docker

   将第一步生成的ca文件复制到/etc/docker/<registry.example.com>/ca.crt，重启下docker。

默认密码: P@ssw0rd，更改`adminserver-env.yaml `自行设置。
