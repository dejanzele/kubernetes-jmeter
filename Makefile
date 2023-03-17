TAG ?= 5.5
SLAVES ?= 2
TEST_NAME ?= jmeter-test

.PHONY: build
build: build-master build-slave

.PHONY: build-master
build-master:
	docker build -t dpejcev/jmeter-master:${TAG} -f docker/jmeter-master/Dockerfile .

.PHONY: build-slave
build-slave:
	docker build -t dpejcev/jmeter-slave:${TAG} -f docker/jmeter-slave/Dockerfile .

.PHONY: load
load: build load-master load-slave

.PHONY: load-master
load-master:
	kind load docker-image dpejcev/jmeter-master:${TAG} --name demo-b

.PHONY: load-slave
load-slave:
	kind load docker-image dpejcev/jmeter-slave:${TAG} --name demo-b

.PHONY: delete-config
delete-config:
	kubectl delete configmap one-test --namespace testkube

.PHONY: create-config
create-config:
	kubectl create configmap one-test \
		--from-file=./examples/jmeter-properties-external.jmx \
		--from-file=./examples/Credentials.csv \
		--namespace testkube

.PHONY: recreate-config
recreate-config: delete-config create-config

.PHONY: install
install:
	helm upgrade --install ${TEST_NAME} ./charts/jmeter 						   \
		--set config.master.testsConfigMap=one-test,config.master.oneShotTest=true \
		--set config.slaves.replicaCount=${SLAVES}								   \
		--namespace testkube

.PHONY: uninstall
uninstall:
	helm uninstall jmeter-test

.PHONY: dry-run
dry-run:
	helm upgrade --install ${TEST_NAME} ./charts/jmeter 						   \
		--set config.master.testsConfigMap=one-test,config.master.oneShotTest=true \
		--set config.slaves.replicaCount=${SLAVES}								   \
		--namespace testkube 													   \
		--dry-run

.PHONY: deploy
deploy:
	kubectl apply -f ./test/manifest.yaml --namespace testkube

.PHONY: undeploy
undeploy:
	kubectl delete -f ./test/manifest.yaml --namespace testkube