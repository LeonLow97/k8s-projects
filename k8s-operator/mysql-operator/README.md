# Content

- [Project Setup](#project-setup)
- [Kubernetes Controllers](#kubernetes-controllers)
- [MySQL Operator for Kubernetes](#mysql-operator-for-kubernetes)
- [MySQL Operator Kubernetes Architecture](#mysql-operator-kubernetes-architecture)
- [MySQL InnoDB Cluster](#mysql-innodb-cluster)
- [Understanding Kubernetes CRDs and Custom Resources in MySQL Operator](#understanding-kubernetes-crds-and-custom-resources-in-mysql-operator)
- [MySQL InnoDB Cluster Service Explanation](#mysql-innodb-cluster-service-explanation)
  - [Overview of Ports](#overview-of-ports)
  - [Which ports should you use?](#which-ports-should-you-use)
  - [How to connect to MySQL InnoDB Cluster deployed inside Kubernetes?](#how-to-connect-to-mysql-innodb-cluster-deployed-inside-kubernetes)
- [References](#references)

# Project Setup

```sh
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
```

# Kubernetes Controllers

- k8s uses **Controllers** to manage the lifecycle of containerized workloads by running them as Pods in the Kubernetes system.
- Controllers provide capabilities for a broad range of services, but complex services require additional components and this includes **operators**.
- Operator
  - An [Operator](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/) is software running inside the Kubernetes cluster.
  - The operator interacts with the **Kubernetes API** to observe resources and services to assist Kubernetes with life-cycle management.

# MySQL Operator for Kubernetes

- MySQL Operator focuses on managing 1 or more [MySQL InnoDB Clusters](https://dev.mysql.com/doc/refman/9.2/en/mysql-innodb-cluster-introduction.html) which consists of a group of:
  - MySQL Servers
  - MySQL Routers
- MySQL Operator itself runs in a Kubernetes cluster and is controlled by a Kubernetes `Deployment` to ensure that the MySQL Operator remains available and running.
- MySQL Operator is deployed in `mysql-operator` Kubernetes namespace by default. It **watches all InnoDB Clusters** and related resources in the Kubernetes cluster.
  - To perform these tasks, the operator
    - subscribes to the Kubernetes API server to update events
    - connects to the managed MySQL Server instance as needed
- On top of the Kubernetes controllers, the operator configures the MySQL servers, replication using MySQL Group Replication, and MySQL Router.
- MySQL Operator for Kubernetes requires 3 container images to function:
  - MySQL Operator for Kubernetes
  - MySQL Router
  - MySQL Server

# MySQL Operator Kubernetes Architecture

<p align="center">
  <img src="./diagrams/mysql-operator-kubernetes-architecture.png" alt="MySQL Operator Architecture" />
</p>

# MySQL InnoDB Cluster

<img src="./diagrams/innodb-cluster.png" alt="InnoDB Cluster" />

An InnoDB Cluster consists of at least 3 MySQL Server instances, and it provides high availability and scaling features.
InnoDB Cluster uses the following MySQL technologies:

- **MySQL Shell**: advanced client and code editor for MySQL.
- **MySQL Server and [Group Replication](https://dev.mysql.com/doc/refman/9.2/en/group-replication.html)**: enables a set of MySQL instances to provide high availability.
- **MySQL Router**: lightweight middleware that provides routing between your application and InnoDB Cluster.

## InnoDB Cluster in Kubernetes

Once an InnoDB Cluster (`InnoDBCluster`) resource is deployed to the Kubernetes API Server,
**MySQL Operator for Kubernetes creates resources** including:

- [Kubernetes StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/) for MySQL Server instances.
  - Manages Pods and assigns the corresponding storage Volume.
  - Each Pod managed by the StatefulSet runs **multiple containers**.
    - One container (named `mysql`) runs the MySQL Server itself,
    - The other container (named `sidecar`) is a Kubernetes sidecar running extra management logic to help the operator control that node.
- [Kubernetes Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) for MySQL Routers.
  - MySQL Routers are **stateless** services routing the application to the current Primary or a Replica, depending on the app's choice.
  - The operator can scale the number of routers up or down as required by the Cluster's workload.

# Understanding Kubernetes CRDs and Custom Resources in MySQL Operator

## Custom Resource

```yaml
apiVersion: mysql.oracle.com/v2
kind: InnoDBCluster
```

- This is a **Custom Resource (CR)** defined and managed by the **MySQL Operator**.
- The CR is watched by the operator via `kube-api-server`.

## What defines the CR's structure?

That's the **Custom Resource Definition (CRD)**:

- The CRD tells the Kubernetes API Server what fields are allowed (like `spec.instances`, `spec.router`, `spec.version`, etc.)
- It acts as a **schema contract** for validating any `InnoDBCluster` objects.
- Once the CRD is installed, you can do `kubectl get innodbcluster`

## What does the MySQL Operator do?

The Operator is a **controller** that:

- Watches the Kubernetes API Server for changes to `InnoDBCluster` objects.
- Reconciles the actual state (Pods, PVCs, Services, etc.) to matched the declared spec.
- Performs orchestration like:
  - Creating StatefulSets
  - Configuring Group Replication
  - Bootstrapping MySQL instances
  - Managing MySQL Router
  - Auto-healing (e.g., failover)

```yaml
# So you write intent in the CR like this, and the operator handles how to make that happen.
spec:
  instances: 3
  router:
    instances: 1
```

# MySQL InnoDB Cluster Service Explanation

- For connecting to the InnoDB Cluster, a `Service` is created inside the Kubernetes Cluster.

```sh
kubectl describe service myinnodbcluster
## Output:
# Name:                     myinnodbcluster
# Namespace:                default
# Labels:                   mysql.oracle.com/cluster=myinnodbcluster
#                           tier=mysql
# Annotations:              <none>
# Selector:                 component=mysqlrouter,mysql.oracle.com/cluster=myinnodbcluster,tier=mysql
# Type:                     ClusterIP
# IP Family Policy:         SingleStack
# IP Families:              IPv4
# IP:                       10.97.136.210
# IPs:                      10.97.136.210
# Port:                     mysql  3306/TCP
# TargetPort:               6446/TCP
# Endpoints:                10.1.4.185:6446
# Port:                     mysqlx  33060/TCP
# TargetPort:               6448/TCP
# Endpoints:                10.1.4.185:6448
# Port:                     mysql-alternate  6446/TCP
# TargetPort:               6446/TCP
# Endpoints:                10.1.4.185:6446
# Port:                     mysqlx-alternate  6448/TCP
# TargetPort:               6448/TCP
# Endpoints:                10.1.4.185:6448
# Port:                     mysql-ro  6447/TCP
# TargetPort:               6447/TCP
# Endpoints:                10.1.4.185:6447
# Port:                     mysqlx-ro  6449/TCP
# TargetPort:               6449/TCP
# Endpoints:                10.1.4.185:6449
# Port:                     mysql-rw-split  6450/TCP
# TargetPort:               6450/TCP
# Endpoints:                10.1.4.185:6450
# Port:                     router-rest  8443/TCP
# TargetPort:               8443/TCP
# Endpoints:                10.1.4.185:8443
# Session Affinity:         None
# Internal Traffic Policy:  Cluster
# Events:                   <none>
```

- Internals
  - `TargetPort` is the actual port exposed inside the Pod (usually the Router container).
  - `Port` is what clients inside the cluster connect to (the Service's exposed port).
  - Multiple ports (like `mysql` and `mysql-alternate`) point to the same target for flexibility.

## Overview of Ports

| Port Name          | Port  | Target Port | Purpose                                                                                                                                                                                                                                           |
| ------------------ | ----- | ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `mysql`            | 3306  | 6446        | MySQL Protocol (SQL) - read-write access                                                                                                                                                                                                          |
| `mysqlx`           | 33060 | 6448        | X Protocol - used by MySQL Shell & JSON clients                                                                                                                                                                                                   |
| `mysql-alternate`  | 6446  | 6446        | Duplicate of above, alternative access to RW SQL                                                                                                                                                                                                  |
| `mysqlx-alternate` | 6448  | 6448        | Duplicate of above, alternate access to RW X Protocol                                                                                                                                                                                             |
| `mysql-ro`         | 6447  | 6447        | MySQL Protocol (SQL) - read-only access                                                                                                                                                                                                           |
| `mysqlx-ro`        | 6449  | 6449        | X Protocol - read-only access                                                                                                                                                                                                                     |
| `mysql-rw-split`   | 6450  | 6450        | MySQL analyzes SQL queries. Write queries are routed to primary instance, while read queries are routed to secondary instances. Optimizes database traffic as application doesn't need to manually distinguish between read and write operations. |
| `router-rest`      | 8443  | 8443        | REST API (status of router / diagnostics)                                                                                                                                                                                                         |

- MySQL Router handles traffic and redirects it based on
  - Protocol: MySQL (SQL) vs X Protocol
  - Mode: Read/Write vs Read-Only
- This allows your apps to connect intelligently, depending on whether they need:
  - Writes --> use RW ports
  - Reads only --> use RO ports (e.g., analytics, reporting)

## Which ports should you use?

| Use Case                 | Port to Use | Notes                                               |
| ------------------------ | ----------- | --------------------------------------------------- |
| General apps (SQL RW)    | 3306        | Most common: read-write SQL access via MySQL Router |
| Analytics/read-only apps | 6447        | Direct read-only SQL (avoids primary node)          |
| MySQL Shell (`mysqlsh`)  | 33060       | Default X Protocol for MySQL Shell                  |
| REST diagnostics         | 8443        | For health check or monitoring tools                |

## How to connect to MySQL InnoDB Cluster deployed inside Kubernetes?

- To connect to MySQL InnoDB Cluster, use its associated **Kubernetes Service and internal DNS names**.
- When you deploy a MySQL InnoDB Cluster using the MySQL Operator, it creates:
  1. **MySQL Router** Service (e.g., `myinnodbcluster`)
  2. **Headless Service** exposing the actual MySQL Pods (e.g., `myinnodbcluster-instances`)
  - These services allow you and backend apps to connect to the InnoDB Cluster.

```sh
k8s-projects git:(main) ✗ kubectl get services
## Output:
# NAME                        TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                                                                    AGE
# kubernetes                  ClusterIP   10.96.0.1       <none>        443/TCP                                                                    9h
# myinnodbcluster             ClusterIP   10.97.136.210   <none>        3306/TCP,33060/TCP,6446/TCP,6448/TCP,6447/TCP,6449/TCP,6450/TCP,8443/TCP   9h
# myinnodbcluster-instances   ClusterIP   None            <none>        3306/TCP,33060/TCP,33061/TCP                                               9h
```

---

1. Router Service (`myinnodbcluster`)

- A `ClusterIP` service that talks to the MySQL Router Pod, which handles routing of read/write traffic to the correct node (PRIMARY vs SECONDARY)
- Can use this service to connect from backend apps or MySQL Clients.

2. Headless Service (`myinnodbcluster-instances`)

- A **headless service** (`ClusterIP = None`) that exposes the underlying `StatefulSet` Pods directly, like `mycluster-0`, `mycluster-1`, `mycluster-2`
- This is used:
  - Internally by the Operator
  - For direct Pod-to-Pod communication
  - For things like cloning or manual troubleshooting

---

### DNS-Based Hostname Forms (Kubernetes Internal DNS)

Kubernetes assigns internal DNS names to all Services and Pods. You can connect using various forms:

| Hostname                                    | Equivalent To                                                   |
| ------------------------------------------- | --------------------------------------------------------------- |
| `myinnodbcluster.default.svc.cluster.local` | Full qualified name inside k8s                                  |
| `myinnodbcluster.default.svc`               | Shorter version                                                 |
| `myinnodbcluster.default`                   | Even shorter (namespace must be correct)                        |
| `myinnodbcluster`                           | Only works when you are in the same namespace (e.g., `default`) |

So in Golang, MySQL CLI, or any client running inside the cluster, this is valid:

```sh
mysql -h myinnodbcluster 3306 uroot -p
```

> It's really routing to the **Router Pod**, which then decides if the traffic goes to the **primary** (for writes) or **a replica** (for reads).

---

# References

- [MySQL Operator for Kubernetes](https://dev.mysql.com/doc/mysql-operator/en/)
