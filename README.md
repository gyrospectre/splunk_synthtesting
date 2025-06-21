# Splunk Synthetic Detection Testing Sandbox

A sandbox environment that implements integration testing for threat detection rules implemented in Splunk. It's intended as a companion to a 2 part Medium post, so go have a read if you've stumbled across this repo some other way.

<img src="https://img.shields.io/badge/Medium-12100E?style=for-the-badge&logo=medium&logoColor=white" /> [Why You Should be Testing Your Detection Rules (Part 1](https://v22bis.medium.com/why-you-should-be-testing-your-detection-rules-part-1-ab6f74fc5116)
[, Part 2)](https://v22bis.medium.com/why-you-should-be-testing-your-detection-rules-part-2-0c485b55bc82)

## Setup

If you're on a Linux/MacOS based system, `setup.sh` should do most of the setup work for you. It will spin up a local Splunk instance in Docker, configure everything, and send in an initial set of synthetic events.

You'll need to have requires Python3, Docker and Terraform installed before running it.

Once done, you can login to the Splunk UI at http://127.0.0.1:8000/ with a username of *"admin"* and the password you specified when running the script.

## Adhoc Test Runs

If you need to send in addition tests after the intial setup, you can do this via:

```
export HEC_TOKEN=`terraform output | cut -f2 -d\"`
source env/bin/activate
python synthtest.py
```

## Fancy Dashboards

The testing overview dashboard seen in the blog post requires manual importing, because I didn't see an easy way to do this in Terraform.

To install:
1. Install the "MITRE ATTCK Heatmap for Splunk" from Splunkbase.
2. From the Splunk UI, select `Apps > Find More Apps`.
3. Search for the app name and install using your Splunkbase login (create one [here](https://idp.login.splunk.com/signin/register) if needed).
4. The app requires a Splunk reboot post install, just follow the prompts.
5. Once back up, create a new classic dashboard, edit, edit source and paste in the xml from [synth_testing_overview.xml](dashboards/synth_testing_overview.xml).

## Cleanup

To clean everything up, no need to do a `terraform destroy`, just run the following to remove all resources:

```
deactivate
rm -rf env .terraform terraform.tfstate .terraform.lock.hcl
docker rm -f `docker ps | grep splunk/splunk | cut -f1 -d' '`
```
