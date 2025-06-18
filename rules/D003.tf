resource "splunk_saved_searches" "D003" {
    name                    = "D003 - Successful Attempt to Download EC2 Instance User Data"
    description             = "Detects access to EC2 user data from an unexpected source."
    search                  = <<-EOT
      index="main" sourcetype="something_that_doesn't exist"
      | eval detection="D003 - Successful Attempt to Download EC2 Instance User Data"
      | eval tactics="discovery", techniques="t1082"
      | collect index=alerts
    EOT
    actions                 = "track"
    alert_track             = true
    alert_severity          = 2
    alert_digest_mode       = true
    dispatch_earliest_time  = "-33m"
    dispatch_latest_time    = "now"
    cron_schedule           = "*/30 * * * *"
    is_scheduled            = true
    acl {
      owner   = "admin"
      sharing = "app"
      app     = "search"
    }
    ## https://stratus-red-team.cloud/attack-techniques/AWS/aws.discovery.ec2-download-user-data/
}