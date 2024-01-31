# shakudo-platform helm chart
Full helm chart with subcharts for core and optional components

## Installation
```
helm install shakudo-hyperlpane . --values values_CLIENTNAME.yaml
```

## Common parameters for initializing the cluster
| Name | Description | Value | Default |
|------|-------------|---------------|---------------|
|initialize.defaultPodSpecsJson | Initialize podspecs in the cluster with values from this dict | "" | "[{\"name\": \"Basic\" , \"icon\": \"\U0001F684\", \"description\":\"The latest basic stable Hyperplane image\", \"imageType\": \"basic\"},{\"name\": \"Deep Learning\", \"icon\": \"\U0001F916\", \"description\":\"Stable Hyperplane with PyTorch, MXNet and Transfomers baked in\", \"imageType\":\"deep\" }, {\"name\": \"GPU\", \"icon\": \"\U0001F3CE️\", \"description\":\"Stable Hyperplane with GPU support, RAPIDS and PyTorch\", \"imageType\":\"gpu\"},  {\"name\": \"Triton Model Serving\", \"icon\": \"\U0001F680\",\"description\": \"Create clients for model serving and inference\", \"imageType\":\"triton\"},{\"imageHashEnvVar\": \"JHUB_IMAGE_RAY\" , \"imageUrlEnvVar\": \"JHUB_IMAGE_RAY\", \"name\": \"Ray\", \"icon\": \"\",\"description\": \"Ray\", \"imageType\":\"ray\"},  {\"imageHashEnvVar\": \"JHUB_IMAGE_RAY_SPARK\" , \"imageUrlEnvVar\":\"JHUB_IMAGE_RAY_SPARK\" , \"name\": \"Spark on Ray\", \"icon\": \"\",\"description\":\"Spark running on Ray distributed framework\", \"imageType\": \"rayspark\"},{\"imageHashEnvVar\": \"JHUB_IMAGE_EXPERIMENTAL\" , \"imageUrlEnvVar\":\"JHUB_IMAGE_EXPERIMENTAL\" , \"name\": \"Dashboards\", \"icon\": \"\",\"description\": \"Experimental image for dashboard and frontend apps\",\"imageType\": \"experimental\"}]" |
|initialize.showPlatformApps.* | Parameters which dictate which default dashboard applications to show | Values are different for each application with `showGraphQLApp`, `showGrafanaLogsApp`, and `showGraphQLDocsApp` set to true by default |`showGraphQLApp: true  showGrafanaLogsApp: true showTritonDashboardApp: false showDistributedWorkloadsDashboardApp: false showImageBuildApp: false showGraphQLDocsApp: true` |
|airflow.gc_enabled | Boolean flag for enabling garbage collector for airflow pods that are complete or in error |true| true |
|monitor.finished_job_emails_enabled | Boolean flag for enabling email notifications for finished jobs | true | true |
|certManager.useServiceAccountSecretRef | Boolean flag for using service account secrets for the certmanager cluster issuer | true | true |
|dashboard.quickAccessApps | JSON string to dictate which apps to show in the Quick Access page in the dashboard | '["GraphQL", "MLflow", "Grafana"]' | '["Airflow", "Cube.js", "DBT Dashboard", "GraphQL", "MLflow", "Model Card Toolkit Viewer", "Model Monitoring Dashboard", "Grafana", "Superset", "Prefect Orion UI"]' |
|grafana.dashboardUrl | The main Grafana Dashboard URL | '' | '' |
|gitServer.noKnownHost | Disable the knownhosts checking for git server| false | false |


## Full parameters for shakudo-cluster-monitor
| Name  | Description | Values | Default |
|---------------------------------------------------|----------------------------------------------------------------|----------------------------------------------------------------------------------------------------------|--------|
| `monitor.namespace` | Namespace for the monitor. | `"hyperplane-monitor"`  | `"hyperplane-monitor"` | 
| `monitor.adminMonitorImage`  | Image used for all monitors. | `"<image url>"` |  `"<image url>"`  |
| `monitor.requests.cpu` | CPU request for the monitors. can be override. | `100m`  |  `100m`  |
| `monitor.requests.memory` | Memory request for the monitors. can be override. | `200Mi` |  `200Mi`  |
| `monitor.limits.cpu`   | CPU limit for the monitors. can be override.| `150m`  | `150m`  |
| `monitor.limits.memory`   | Memory limit for the monitor. can be override. | `300Mi` | `300Mi`  |
| General Monitor parameters ||||
| `monitor.monitors.<monitor type>.monitorName`  | Name of the monitor.  Don't change this| `some-component-monitor`   |  N/A  |
| `monitor.monitors.<monitor type>.monitorScriptFile`  | Script file for the monitor. Don't change this| `Monitor.py` |  N/A  |
| `monitor.monitors.<monitor type>.requests.cpu` | CPU request for the monitor. but will override the above settings. | `100m`  |  N/A  |
| `monitor.monitors.<monitor type>.requests.memory` | Memory request for the monitor. but will override the above settings. | `200Mi` |  N/A  |
| `monitor.monitors.<monitor type>.limits.cpu`   | CPU limit for the monitor. but will override the above settings. | `150m`  |  N/A  |
| `monitor.monitors.<monitor type>.limits.memory`   | Memory limit for the monitor. but will override the above settings. | `300Mi` |  N/A  |
| Deployment Monitor `monitor.monitors.deploymentMonitor`||||
| `*.enabled`   | Deployment monitor enabled status.  | `true`  | `true` |
| `*.monitorEnvs.FILTERS`| Environment variable FILTERS for deployment monitor.  | [Go to Filter formats](#filter-formats). |  ["*"] | 
| Pod Monitor Monitor `monitor.monitors.podMonitor`||||
| `*.enabled`  | Pod monitor enabled status.   | `false` |`false` |
| `*.monitorEnvs.FILTERS` | Environment variable FILTERS for pod monitor.   | [Go to Filter formats](#filter-formats) | None|
| Statefulset Monitor `monitor.monitors.statefulSetMonitor`||||
| `*.enabled`  | StatefulSet monitor enabled status. | `true`  | `true` |
| `*.monitorEnvs.FILTERS`| Environment variable FILTERS for statefulset monitor. | [Go to Filter formats](#filter-formats) | ["*"] |
| Database Monitor `monitor.monitors.databaseMonitor` ||||
| `*.enabled`  | Database monitor enabled status. | `true`  | `true` |
| Job fails Monitor `monitor.monitors.jobFailMonitor`||||
| `*.enabled`   | Job fail monitor enabled status. | `true`  | `true` |
| `*.monitorEnvs.JOB_FAIL_THRESHOLD_IS_RATE` | Environment variable for job fail threshold rate. | `1` | `1` | 
| `*.monitorEnvs.JOB_FAIL_THRESHOLD` | Environment variable for job fail threshold.   | `0.1`  |  `0.1`  | 
| `*.monitorEnvs.JOB_FAIL_IGNORED_EXCEPTIONS` | Environment variable for ignored job fail exceptions. | `''`  |  `''`  | 

#### Filter formats:
If provided, must in json string format.

No Filter: If given `null, '[]', ''` or if it's omitted, None of entities across all namespaces will be monitored.

Wildcard Filter: If given `["*"]` all entities across all namespaces will be monitored.

Filter by App Selector: Input like `["hyperplane-default,app=frontend", "hyperplane-default,app=backend", "hyperplane-default,app=database"]` will monitor all entities with the selectors `"app=frontend", "app=backend", "app=database"` under namespace `hyperplane-default`.

Filter by Name: An input like `["hyperplane-default,frontend", "hyperplane-default,backend", "hyperplane-default,database"]` will monitor all entities that have names including `"frontend", "backend", "database"` under namespace `hyperplane-default`.

Mixed Filter Type: For a format like `["hyperplane-default,frontend", "hyperplane-default,app=backend", "hyperplane-default,database"]`, the monitoring will cover resources with names containing `"frontend", "database"` and those that match the selector `"app=backend"` under namespace `hyperplane-default`.

#### Admin monitor config file.
TODO: convert it into a helmchart.
Currently file located under `apps/cluster_monitoring_revamp/AdminAlertPoster/admin-monitor.yaml`
```
    default:
      # Global cluster monitor default.
      default:
        info:
          threshold: 1
          listener:
            - pagerduty: "8a489.. pd event api key .." 
        warning:
          threshold: 3
          listener:
            - pagerduty: "8a489.. pd event api key .." 

      PodMonitor:
        info:
          threshold: 1
        warning:
          threshold: 3
      StatefulSetMonitor:
        info:
          threshold: 1
        warning:
          threshold: 3
      DeploymentMonitor:
        info:
          threshold: 1
        warning:
          threshold: 3

    clusters:
      andy-dev.canopyhub.io:
        default:
          info:
            listener:
              - pagerduty: "8a489.. pd event api key .." 
          warning:
            listener:
              - pagerduty: "8a489.. pd event api key .."
```
The "default" acts as the primary global setting. Cluster-specific configurations under "clusters" can override this primary setting, and within each configuration, subkey values can further override their immediate parent settings.

For example in `andy-dev.canopyhub.io` cluster, `default` is default to all type of monitors under that cluster, and the `info` level `threshold` of `DeploymentMonitor` should refering the default value `default.DeploymentMonitor.info.threshold`. 