# Content

- [Why running stateful application in Kubernetes is challenging?](#why-running-stateful-application-in-kubernetes-is-challenging)
- [What are Kubernetes Operators?](#what-are-kubernetes-operators)
- [Stateless Services vs Stateful Services](#stateless-services-vs-stateful-services)
- [Custom Resources](#custom-resources)
- [Visual Overview](#visual-overview)
- [Control Loop](#control-loop)
- [References](#references)

# Why running stateful application in Kubernetes is challenging?

- Running **stateful applications** like databases (e.g., PostgreSQL, MySQL), monitoring systems (e.g., Prometheus) or caching layers (e.g., Redis) is tricky.
  - They require **persistent storage, configuration management, backups and failover handling**.
  - Native Kubernetes resources (like Deployments and StatefulSets) don't provide all the intelligence needed to manage these apps.

# What are Kubernetes Operators?

- An Operator is typically deployed as a Pod (or set of Pods) managed by a Deployment, within a specific namespace.
  - It communicates with the **Kubernetes API Server** to watch and reconcile resources.
  - It may be:
    - **Cluster-scoped**: Watches resources across the entire cluster.
    - **Namespace-scoped**: Watches resources only in a specific namespace.
- Designed to manage **stateful and complex** applications like databases, caches and monitoring systems.
- An Operator consists of:
  - 1 or more Custom Resources (CRs)
  - A **control loop process** running inside a Pod in a Kubernetes cluster.
- What does an Operator do?
  - Extends the Kubernetes API using application-specific Custom Resources.
  - Manages the **lifecycle** of Kubernetes-native applications.
  - Automates operational tasks such as:
    - Deploying
    - Updating
    - Removing applications
- Why use an Operator?
  - Encodes **application-specific logic** that would otherwise be done manually by operations teams.
  - Essential for managing stateful services (e.g., databases, caches, monitoring systems), which often require:
    - Post-deployment configuration
    - Backup
    - Recovery
  - Not typically needed for stateless services, which Kubernetes can handle with built-in components.

# Stateless Services vs Stateful Services

- Stateless Services
  - Designed to be ephemeral and easily replaceable.
  - Pods are identical and do not maintain state between restarts.
  - Scaling is simple: just update the number of replicas in a Deployment.
  - Pods are unaware of each other, no coordination required.
  - Managed easily using built-in Kubernetes components (e.g., Deployments, Services).
  - No need for custom logic or Operators in most cases.
- Stateful Services
  - Not ephemeral, each Pod may have **unique identity or configuration**.
  - Common examples: Databases, message queues, caches.
  - Require **additional configuration** (e.g., persistent storage, cluster membership).
  - Scaling requires more than just adding pods, must add/remove members properly.
  - Operational tasks include:
    - Node identity & initialization
    - Replication setup
    - Backup and recovery
    - Failover handling
  - These tasks cannot ba managed easily with standard Kubernetes tools.

# Custom Resources

- What are Custom Resources?
  - Custom Resources (CRs) extend the Kubernetes API by adding **new resource types**.
  - They create **new API endpoints** within Kubernetes (e.g., `/apis/mydomain.com/v1/myresources`)
- Custom Resources Definition (CRD)
  - A CRD defines the schema, metadata, and validation rules for a new custom resource.
  - It registers the custom resource with the Kubernetes API server.
  - Acts as the blueprint for the custom resource's structure and behavior.
- Role in Operators
  - Operators typically **apply at least 1 custom resource** during deployment.
  - Custom resources serve as the user interface for interacting with the Operator.
  - The Operator **watches these resources and executes logic** based on their desired state.

# Visual Overview

```
Developer/User         Kubernetes API Server             Operator Pod
     |                        |                              |
     | apply CRD              |                              |
     |----------------------->|                              |
     |                        |  exposes new API endpoint    |
     | apply Custom Resource  |                              |
     |----------------------->|                              |
     |                        |  notifies operator via watch |
     |                        |----------------------------> |
     |                        |                              | runs reconciliation logic
     |                        |                              | manages StatefulSets, PVCs,Services, etc.
```

# Control Loop

Operators run a control loop which is an infinite loop that cycles through 3 steps - Observe, Diff, and Act.

1. **Observe**:
   - The operator queries the Kubernetes API server to receive resources that it's configured to watch.
2. **Diff**:
   - Resources received in the observation step are checked to see if they have changed and if current and desired states match.
   - Most Kubernetes objects have a `.spec` field representing the desired state and a `.status` field representing the current state.
3. **Act**:
   - The act step (AKA reconciliation function) attempts to align the current state of resources to the desired state by applying application logic.
   - Application logic is added to the reconciliation function and tells the operator what to do when a change is detected.

# References

- [What is a Kubernetes Operator](https://konghq.com/blog/learning-center/what-is-a-kubernetes-operator)
- [Introduction to Kubernetes Operators](https://sdbrett.com/post/2021-01-27-kubernetes-operators/)
- [Operator Patter](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/)
-
