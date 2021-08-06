# Start with the Generally Available splunk/fluentd-hec docker image.
# Source available here: https://github.com/splunk/fluent-plugin-splunk-hec
# Published Image available here: https://hub.docker.com/r/splunk/fluentd-hec
 
FROM splunk/fluentd-hec:latest

#Seed custom fluentd config for AWS Firelens log router image deploy of splunk-fluentd-hec

ADD splunk-firelens-demo.conf /splunk-firelens-demo.conf
