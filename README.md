# Helm Resource for Concourse

Deploy to [Kubernetes Helm](https://github.com/kubernetes/helm) from [Concourse](https://concourse.ci/).

Forked from gbvanrenswoude/concourse-helm-eks-resource who forked from linkyard/concourse-helm-resource.  
Added .aws folder copy to standard Docker build, so it's possible to get rid of sts, I strongly recommend to not publish your container on public registries. Bellow there is a code snip for how to proper configure your resource_type to download your private image:

```
resource_types:
  - name: helm
    type: docker-image
    source:
      repository: yourprivate repo (myuser/myrepo)
      tag: concourse-helm-eks-resource-1.0.1
      username: ((private-cr-user))
      password: ((private-cr-password))
```
on resource it's should looks like:
```
- name: helm-release
  type: helm
  source:
    aws_region: "us-east-1"
    aws_eks_cluster_name: your-eks-cluster-name
    use_awscli_eks_auth: "true"
```
on Jobs you can use like:
```
jobs:
- name: apply-rollout
  build_logs_to_retain: 2
  plan:
  - get: bitbucket-repo-prod
  - put: helm-release
    params:
      chart: yourprivateorpublicchartrepo/charts/example
      values: yourprivateorpublicchartrepo/charts/example/values.yaml
      release: example-k8s-helm-chart
      namespace: test
      override_values:
      - key: replicas
        value: 1
```

Bellow you can see the original README.md

Modified to support autogeneration of kubeconfig for AWS EKS and AWS STS AssumeRole.  

Quick fixed.

## Installing

Add the resource type to your pipeline:

```yaml
resource_types:
- name: helm
  type: docker-image
  source:
    repository: linkyard/concourse-helm-resource
```

## Source Configuration

* `cluster_url`: *Required.* URL to Kubernetes Master API service
* `cluster_ca`: *Optional.* Base64 encoded PEM. Required if `cluster_url` is https.
* `token`: *Optional.* Bearer token for Kubernetes.  This, 'token_path' or `admin_key`/`admin_cert` are required if `cluster_url` is https.
* `admin_key`: *Optional.* Base64 encoded PEM. Required if `cluster_url` is https and no `token` or 'token_path' is provided.
* `admin_cert`: *Optional.* Base64 encoded PEM. Required if `cluster_url` is https and no `token` or 'token_path' is provided.
* `release`: *Optional.* Name of the release (not a file, a string). (Default: autogenerated by helm)
* `namespace`: *Optional.* Kubernetes namespace the chart will be installed into. (Default: default)
* `helm_init_server`: *Optional.* Installs helm into the cluster if not already installed. (Default: false)
* `helm_history_max`: *Optional.* Limits the maximum number of revisions. (Default: 0 = no limit)
* `tiller_namespace`: *Optional.* Kubernetes namespace where tiller is running (or will be installed to). (Default: kube-system)
* `tiller_service_account`: *Optional* Name of the service account that tiller will use (only applies if helm_init_server is true).
* `repos`: *Optional.* Array of Helm repositories to initialize, each repository is defined as an object with properties `name`, `url` (required) username and password (optional).
* `helm_host`: *Optional* Address of Tiller. Skips helm discovery process. (only applies if `helm_init_server` is false).
* `tls_enabled`: *Optional* Uses TLS for all interactions with Tiller. (Default: false)
* `helm_ca`: *Optional* Private CA that is used to issue certificates for Tiller clients and servers (only applies if tls_enabled is true).
* `helm_cert`: *Optional* Certificate for Client (only applies if tls_enabled is true).
* `helm_key`: *Optional* Key created for Client when doing a secure Tiller install (only applies if tls_enabled is true).
* `tiller_cert`: *Optional* Certificate for Tiller (only applies if tls_enabled and helm_init_server are true).
* `tiller_key`: *Optional* Key created for Tiller when doing a secure Tiller install (only applies if tls_enabled and helm_init_server are true).
* `proxy_url`: *Optional* Sets http and https proxy_url.
* `no_proxy_config`: *Optional* Sets no proxy
#### Source Configuration - AWS EKS options
* `use_aws_iam_authenticator`: *Optional.* If true, the aws_iam_authenticator, required for connecting with EKS, is used.
* `assume_aws_role`: *Optional.* When using aws_iam_authenticator. If true, a role will be assumed before using the aws_iam_authenticator to connect to EKS.
* `aws_region`: *Optional.* When using the optional aws_iam_authenticator and optional assume_aws_role, setting the aws_region is required. This defaults to eu-west-1
* `aws_eks_cluster_name`: *Optional.* the AWS EKS cluster name, required when use_aws_iam_authenticator or use_awscli_eks_auth is true.
##### AWS CLI shortcut
* `use_awscli_eks_auth`: *Optional* Defaults to false. If "true", uses the awscli generate the kube config. You can even leave out cluster_url and cluster_ca then. Required is only the aws_eks_cluster_name

## Behavior

### `check`: Check for new releases

Any new revisions to the release are returned, no matter their current state. The release must be specified in the
source for `check` to work.

### `in`: Not Supported

### `out`: Deploy the helm chart

Deploys a Helm chart onto the Kubernetes cluster. Tiller must be already installed
on the cluster.

#### Parameters

* `chart`: *Required.* Either the file containing the helm chart to deploy (ends with .tgz) or the name of the chart (e.g. `stable/mysql`).
* `namespace`: *Optional.* Either a file containing the name of the namespace or the name of the namespace. (Default: taken from source configuration).
* `release`: *Optional.* Either a file containing the name of the release or the name of the release. (Default: taken from source configuration).
* `values`: *Optional.* File containing the values.yaml for the deployment. Supports setting multiple value files using an array.
* `override_values`: *Optional.* Array of values that can override those defined in values.yaml. Each entry in
  the array is a map containing a key and a value or path. Value is set directly while path reads the contents of
  the file in that path. A `hide: true` parameter ensures that the value is not logged and instead replaced with `***HIDDEN***`.
  A `type: string` parameter makes sure Helm always treats the value as a string (uses the `--set-string` option to Helm; useful if the value varies
  and may look like a number, eg. if it's a Git commit hash).
* `token_path`: *Optional.* Path to file containing the bearer token for Kubernetes.  This, 'token' or `admin_key`/`admin_cert` are required if `cluster_url` is https.
* `version`: *Optional* Chart version to deploy, can be a file or a value. Only applies if `chart` is not a file.
* `delete`: *Optional.* Deletes the release instead of installing it. Requires the `name`. (Default: false)
* `test`: *Optional.* Test the release instead of installing it. Requires the `release`. (Default: false)
* `purge`: *Optional.* Purge the release on delete. (Default: false)
* `replace`: *Optional.* Replace deleted release with same name. (Default: false)
* `force`: *Optional.* Force resource update through delete/recreate if needed. (Default: false)
* `devel`: *Optional.* Allow development versions of chart to be installed. This is useful when wanting to install pre-release
  charts (i.e. 1.0.2-rc1) without having to specify a version. (Default: false)
* `debug`: *Optional.* Dry run the helm install with the debug flag which logs interpolated chart templates. (Default: false)
* `wait_until_ready`: *Optional.* Set to the number of seconds it should wait until all the resources in
    the chart are ready. (Default: `0` which means don't wait).
* `recreate_pods`: *Optional.* This flag will cause all pods to be recreated when upgrading. (Default: false)
* `show_diff`: *Optional.* Show the diff that is applied if upgrading an existing successful release. Will not be used when `devel` is set. (Default: false)
* `exit_after_diff`: *Optional.* Show the diff but don't actually install/upgrade. (Default: false)
* `reuse_values`: *Optional.* When upgrading, reuse the last release's values. (Default: false)

## Example

### Out

Define the resource:

```yaml
resources:
- name: myapp-helm
  type: helm
  source:
    cluster_url: https://kube-master.domain.example
    cluster_ca: _base64 encoded CA pem_
    admin_key: _base64 encoded key pem_
    admin_cert: _base64 encoded certificate pem_
    repos:
      - name: some_repo
        url: https://somerepo.github.io/charts
```

Add to job:

```yaml
jobs:
  # ...
  plan:
  - put: myapp-helm
    params:
      chart: source-repo/chart-0.0.1.tgz
      values: source-repo/values.yaml
      override_values:
      - key: replicas
        value: 2
      - key: version
        path: version/number # Read value from version/number
      - key: secret
        value: ((my-top-secret-value)) # Pulled from a credentials backend like Vault
        hide: true # Hides value in output
      - key: image.tag
        path: version/image_tag # Read value from version/number
        type: string            # Make sure it's interpreted as a string by Helm (not a number)
```


Example EKS config:
```yaml
resource_types:
- name: helm
  type: docker-image
  source:
    repository: yourrepo/concourse-helm-eks-resource

standard-artifactory-helm-source: &STANDARD-ARTIFACTORY-HELM-SOURCE
    use_awscli_eks_auth: "true"
    repos:
      - name: {{ artifactory.repository }}
        url: {{ artifactory.url }}/{{ artifactory.repository }}
        username: {{ artifactory.user }}
        password: "{{ artifactory_password }}"

- name: fluentd-chart
  type: helm
  source:
    <<: *STANDARD-ARTIFACTORY-HELM-SOURCE
    aws_eks_cluster_name: someekscluster
    assume_aws_role: arn:aws:iam::{{someaccount}}:role/somerole
    namespace: kube-system
    release: fluentd

jobs:
- name: helm-rollout-on-{{somecluster}}
  plan:
  - get: values
    trigger: true
  - put: fluentd-chart-on-{{account}}
    params:
      chart: {{ artifactory.repository }}/fluentd-cloudwatch
      values: values/kubernetes/charts/fluentd/values.yaml
      recreate_pods: true
```
