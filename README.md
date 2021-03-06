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

Splunk currently publishes/supports a fluentd firelens option. 

https://github.com/splunk/splunk-connect-for-kubernetes/tree/develop/firelens

https://docs.aws.amazon.com/AmazonECS/latest/developerguide/firelens-taskdef.html 

# Let's Deploy!!

## Requirements

  - AWS CLI, ECS Fargate & Elastic Container Registry access
  - The latest `splunk/fluentd-hec` docker image
  - A fluentd configuration file
  - A Splunk Cloud and/or Splunk O11y Cloud Instance and token 
  - An ECS Task Definiton

## awscli

Ensure you have the latest awscli installed for your local machine.

- https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-mac.html
- https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html#cli-configure-quickstart-creds

## AWS IAM User

You will need an IAM user who has admin access to push your custom fluentd-hec image to ECR and to deploy ECS Fargate resources.  

https://docs.aws.amazon.com/AmazonECR/latest/userguide/security-iam-awsmanpol.html#security-iam-awsmanpol-AmazonEC2ContainerRegistryFullAccess

https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html

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

## Create your custom `splunk/fluentd-hec` Firelens image!

Pull the `splunk/splunk-fluentd-hec:latest` image 

Note the 100 Milli pull club!! :) ???? 

`docker pull splunk/fluentd-hec`

## Pull demo configs to your local machine

`git clone https://github.com/matthewmodestino/splunk-fargate-firelens-demo.git`

## Review the Dockerfile

`vi Dockerfile`

The Dockerfile is very simple. 

It adds our custom fluentd config into the `splunk/fluentd-hec` container filesystem. We will reference this location in our Task Definition when configuring AWS Firelens log_router. 

## Review and Update your splunk/fluentd-hec config file

`vi splunk-firelens-demo.conf`

Update this file as you wish. At minimum add your `hec_host` and  `hec_token` either with Splunk O11y token or Splunk Cloud HEC Token

For Splunk Observability Cloud Log Observer:

https://docs.splunk.com/Observability/logs/logs.html

```
<match **>
  @type splunk_hec
  protocol https
  hec_host "ingest.$YOUR_REALM_HERE.signalfx.com"           
  hec_port 443
  hec_token $YOUR_TOKEN_HERE
  host_key ecs_task_arn 
  source_key ecs_cluster
  sourcetype_key ecs_task_definition
  <fields>
    container_id
    container_name
    ecs_task_arn
    ecs_cluster
    source
  </fields>
```

For Splunk Enterprise Cloud:

https://docs.splunk.com/Documentation/SplunkCloud/8.2.2106/Data/UsetheHTTPEventCollector#Send_data_to_HTTP_Event_Collector_on_Splunk_Cloud

```
<match **>
  @type splunk_hec
  protocol https
  hec_host "https-inputs-$SPLUNK_CLOUD_HOST"           
  hec_port 443
  hec_token $YOUR_TOKEN_HERE
  host_key ecs_task_arn 
  source_key ecs_cluster
  sourcetype_key ecs_task_definition
  <fields>
    container_id
    container_name
    ecs_task_arn
    ecs_cluster
    source
  </fields>
```

## Why not Both?!

See "Fluentd Copy Plugin" example in Splunk O11y docs!

https://docs.splunk.com/Observability/logs/logs.html

## Build your Docker Image and Push to your Registry

From inside the repo you have pulled locally, run the following commands, updated accordingly for your AWS environment. 

```
docker build -t splunk-firelens-demo .
docker tag splunk-firelens-demo:latest public.ecr.aws/XXXXXX/splunk-firelens-demo:latest
docker push public.ecr.aws/XXXXXX/splunk-firelens-demo:latest
```

Now that `log_router` container is ready an has been seeded with it's config, we can prepare and deploy a task definition that tells firelens how to deploy our image:  

## Review the Demo Task Definition

The demo Fargate Task Definition deploys a nginx container that can be exposed using an ALB with an HTTP:80 port listener. 

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

## Deploy Task Definition

Deploy the included task definition on Fargate, using the AWS UI. 


## Review the data in Splunk!

Whether sending to Splunk Enterise Cloud or Splunk Observability Cloud, review the data is being received and that the fields we mapped in the fluentd config make sense for you!



# Tips,Tricks & Troubleshoot

This fluentd example was based on the great work here:

https://github.com/aws-samples/amazon-ecs-firelens-examples

You may find it handy to have a JSON linter close by when working with task definitions! - https://jsonlint.com/ 

Will explore adding more custom keys to the records as needed.

