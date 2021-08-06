# splunk-fargate-firelens-demo

Collect logs from AWS ECS Fargate workloads using `splunk/fluentd-hec` Firelens log router and send to Splunk Enterprise Cloud and Splunk Observability Cloud!

## What is `splunk/fluentd-hec`?

It is the "logging container" Splunk ships as part of the Splunk Connect for Kubernetes solution. 

It contains useful open source fluentd plugins and configurations that can be leveraged in ECS and beyond!

https://github.com/splunk/fluent-plugin-splunk-hec

https://hub.docker.com/r/splunk/fluentd-hec/tags?page=1&ordering=last_updated

https://github.com/splunk/splunk-connect-for-kubernetes/tree/develop/firelens

## What is AWS Firelens?

With fluentd and fluent-bit becoming a common open source agent, AWS and partners like Splunk, provide Firelens options to help you configure fluentd/fluent-bit inputs, filters and output configurations.

Splunk currently publishes/supports a fluentd firelens option. https://github.com/splunk/splunk-connect-for-kubernetes/tree/develop/firelens

https://docs.aws.amazon.com/AmazonECS/latest/developerguide/firelens-taskdef.html 

# Let's Deploy!!

## Requirements

  - AWS CLI, ECS Fargate & Elastic Container Registry access
  - The latest splunk/fluentd-hec docker image
  - A fluentd configuration file
  - A Splunk Cloud and/or Splunk O11y Cloud Instance and token 
  - An ECS Task Definiton

## awscli

Ensure you have the latest awscli installed for your local machine.

- https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-mac.html
- https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html#cli-configure-quickstart-creds

## AWS IAM User

You will need an IAM user who has admin access to push your custom fluentd-hec image to ECR and to deploy ECS Fargate resources.  

## Set your credentials

You can export your `ACCESS_KEY_ID` and the `SECRET_ACCESS_KEY` that you collect from the IAM user console, and set your awscli parameters:

```
aws configure set aws_access_key_id XXXXXXXXXXXXXXXXXXXXXXXX
aws configure set aws_secret_access_key XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

https://docs.aws.amazon.com/cli/latest/reference/configure/set.html#examples

## Docker

Make sure you have docker available locally.

https://docs.docker.com/get-docker/
 
## ECR Repo Prep

Prep your ECR Repo so we can host our custom `splunk/fluentd-hec` image.

https://docs.aws.amazon.com/AmazonECR/latest/userguide/getting-started-cli.html

Once your ECR repo is created you will need to login. See ECR UI for login instructions.

Example:

`aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin XXXXXXXX.ecr.aws/XXXXXXXXX`

## Create your custom splunk/fluentd-hec image

Pull the `splunk/splunk-fluentd-hec:latest` image 

100 Milli pull club!! :) 🎉 

`docker pull splunk/fluentd-hec`

## Pull the demo configs to your local machine

`git clone https://github.com/matthewmodestino/splunk-fargate-firelens-demo.git`

## Review the Dockerfile

`vi Dockerfile`

The Dockefile is very simple and just copies our custom fluentd config into the `splunk/fluentd-hec` container filesystem.

## Review and Update your splunk/fluentd-hec config file

`vi splunk-firelens-demo.conf`

Update your token either with Splunk O11y token or Splunk Cloud HEC Token

## Build your Docker Image and Push to your Registry

```
docker build -t splunk-firelens-demo .
docker tag splunk-firelens-demo:latest public.ecr.aws/XXXXXX/splunk-firelens-demo:latest
docker push public.ecr.aws/XXXXXX/splunk-firelens-demo:latest
```
Now that `log_router` container is ready an has been seeded with it's config, we can prepare and deploy a task definition that tells firelens how to deploy our image:  

## Review the Demo Task Definition

The demo task definition included deploys an nginx container that can be exposed using an ALB with an HTTP:80 port listener. 

The key is to make sure our firelens config points to the file we seeded in out `splunk/fluentd-hec` container. 

```
"firelensConfiguration": {
    "type": "fluentd",
    "options": {
        "config-file-type": "file",
        "config-file-value": "/splunk-firelens-demo.conf"
    }
}
```

# Deploy Task Definition

Deploy the included task definition. Once running you should see logs in Splunk Cloud or Splunk O11y Cloud Log Observer

# Tips,Tricks & Troubleshoot

This fluentd example was based on the great work here:

https://github.com/aws-samples/amazon-ecs-firelens-examples/blob/d63a87a9c5d18e8857551f362cba1472ec7feb15/examples/fluent-bit/config-file-type-file/task-definition.json#L34-L47

You may find it handy to have a JSON linter close by https://jsonlint.com/ when working with task definitions!
