#!/bin/bash

# Install CRD used by MySQL Operator
kubectl apply -f https://raw.githubusercontent.com/mysql/mysql-operator/trunk/deploy/deploy-crds.yaml

# Deploy MySQL Operator, includes RBAC definitions in output
kubectl apply -f https://raw.githubusercontent.com/mysql/mysql-operator/trunk/deploy/deploy-operator.yaml

# Verify operator is running
kubectl get deployment mysql-operator --namespace mysql-operator
## Expected Output:
# NAME             READY   UP-TO-DATE   AVAILABLE   AGE
# mysql-operator   1/1     1            1           37s

# Configure and install a new MySQL InnoDB CLuster
kubectl apply -f ./manifests
## Expected Output:
# innodbcluster.mysql.oracle.com/myinnodbcluster created
# secret/myinnodbcluster created

# (Optional) Observe the process by watching the `innodbcluster` type for the default namespace
kubectl get innodbcluster --watch
## Expected Output:
# NAME              STATUS    ONLINE   INSTANCES   ROUTERS   TYPE      AGE
# myinnodbcluster   PENDING   0        3           1         PRIMARY   62s
# myinnodbcluster   ONLINE   1        3           1         UNKNOWN   74s
# myinnodbcluster   ONLINE   2        3           1         UNKNOWN   76s
# myinnodbcluster   ONLINE   2        3           1         UNKNOWN   82s
# myinnodbcluster   ONLINE   3        3           1         UNKNOWN   87s

# Connect with MySQL Shell to check the host name
# This command connects to `myinnodbcluster` headless Service (created by MySQL Operator),
# exposing all pods of the StatefulSet (e.g., `myinnodbcluster-0`, `-1`, `-2`).
kubectl run --rm -it myshell --image=container-registry.oracle.com/mysql/community-operator -- mysqlsh root@myinnodbcluster --sql
## Expected Output:
#  MySQL  myinnodbcluster:3306 ssl  SQL > select @@hostname;
# +-------------------+
# | @@hostname        |
# +-------------------+
# | myinnodbcluster-0 |
# +-------------------+
# 1 row in set (0.0021 sec)
## This shows a successful connection that was routed to the myinnodbcluster-0 pod in the
## MySQL InnoDB Cluster. It connects to `-0` pod because only one pod is elected as the primary (writer),
## usually the first one, myinnodbcluster-0, others (-1, -2) are replicas (read-only by default).

# Command to view read replicas database (`-1`, `-2`)
# kubectl exec -it myinnodbcluster-1 -c mysql -- mysql -uroot -p mydatabasename

# Command to check max_connections
# kubectl exec -it myinnodbcluster-0 -c mysql -- mysql -uroot -psecretpassword -e "SHOW VARIABLES LIKE 'max_connections';"