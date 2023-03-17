[![License](https://img.shields.io/badge/license-MIT%20License-brightgreen.svg)](https://opensource.org/licenses/MIT) [![Build Status](https://travis-ci.org/kaarolch/kubernetes-jmeter.svg?branch=master)](https://travis-ci.org/kaarolch/kubernetes-jmeter)
# kubernetes-jmeter

Jmeter test workload inside Kubernetes. [Jmeter](charts/jmeter) chart bootstraps an Jmeter stack on a Kubernetes cluster using the Helm package manager.

Currently the [jmeter](charts/jmeter) Helm chart deploys:
*   JMeter master
*   JMeter slaves

## Run Sample Test

First we need to create a ConfigMap with JMeter JMX test file.

You can use `kubectl` command:
```shell
kubectl create configmap one-test --from-file=./examples/simple_test.jmx --namespace testkube
```
or use the `make` command:
```shell
make create-config
```

Now we need to provide the name of the ConfigMap to the `config.master.testsConfigMap` value in the `helm install` command:
```shell
helm install ./charts/jmeter --set config.master.testsConfigMap=one-test --namespace testkube
```

Logs could be displayed via `kubectl logs`:
```shell
kubectl logs $(kubectl get pod -l "app=jmeter-master" -o jsonpath='{.items[0].metadata.name}')
```

Example logs from master:
```
Sep 20, 2018 8:40:46 PM java.util.prefs.FileSystemPreferences$1 run
INFO: Created user preferences directory.
Creating summariser <summary>
Created the tree successfully using /test/simple_test.jmx
Configuring remote engine: 172.17.0.10
Configuring remote engine: 172.17.0.9
Starting remote engines
Starting the test @ Thu Sep 20 20:40:47 GMT 2018 (1537476047110)
Remote engines have been started
Waiting for possible Shutdown/StopTestNow/Heapdump message on port 4445
summary +   1003 in 00:00:13 =   76.8/s Avg:   148 Min:   123 Max:   396 Err:     0 (0.00%) Active: 16 Started: 16 Finished: 0
summary +    597 in 00:00:05 =  110.8/s Avg:   150 Min:   123 Max:   395 Err:     0 (0.00%) Active: 0 Started: 16 Finished: 16
summary =   1600 in 00:00:18 =   86.7/s Avg:   149 Min:   123 Max:   396 Err:     0 (0.00%)
Tidying up remote @ Thu Sep 20 20:41:06 GMT 2018 (1537476066203)
... end of run
```

Test could be restarted via pod restart:
```shell
kubectl delete pods $(kubectl get pod -l "app=jmeter-master" -o jsonpath='{.items[0].metadata.name}')
```

## Remove stack

You can remove the stack using the Helm command:
```shell
helm delete YOUR_RELEASE_NAME --purge
```
or uninstall using the `make` command:
```shell
make uninstall
```

The command removes all the Kubernetes components associated with the chart and deletes the release.
