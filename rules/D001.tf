resource "splunk_saved_searches" "D001" {
    name                    = "D001 - AWS IAM Backdoor Users Keys"
    description             = "Detects AWS API key creation for a user by another user. Backdoored users can be used to obtain persistence in the AWS environment."
    search                  = <<-EOT
      index="main" sourcetype="aws:cloudtrail" eventSource="iam.amazonaws.com" eventName="CreateAccessKey" NOT userIdentity.arn="*responseElements.accessKey.userName*"
      | eval test_id=if(like(host, "test_%"), substr(host, 6), "not_test")
      | stats values(userIdentity.arn) as user_arn,values(userAgent) as userAgent count by _time,requestParameters.userName,awsRegion,test_id
      | eval detection="D001 - AWS IAM Backdoor Users Keys", tactics="persistence", techniques="t1098"
      | collect index=alerts
    EOT
    actions                 = "track"
    alert_track             = true
    alert_severity          = 3
    alert_digest_mode       = true
    dispatch_earliest_time  = "-1h"
    dispatch_latest_time    = "now"
    cron_schedule           = "40 * * * *"
    is_scheduled            = true
    acl {
      owner   = "admin"
      sharing = "app"
      app     = "search"
    }
    ## https://github.com/SigmaHQ/sigma/blob/master/rules/cloud/aws/cloudtrail/aws_iam_backdoor_users_keys.yml
}