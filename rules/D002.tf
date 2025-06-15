resource "splunk_saved_searches" "D002" {
    name                    = "D002 - MS365 Defender detected lateral movement"
    description             = "Lateral movement on another device was observed in close time proximity to a suspicious network event on this device. This could mean that an attacker is attempting to move laterally across devices to gather data or elevate privileges. This alert was triggered based on a Microsoft Defender for Endpoint alert."
    search                  = <<-EOT
      index="main" sourcetype="ms365:defender:incident:alerts" detectionSource="microsoft365Defender" category="LateralMovement" 
      | eval test_id=if(like(host, "test_%"), substr(host, 6), "not_test")
      | eval src_user='evidence{}.loggedOnUsers{}.accountName'
      | eval src_host='evidence{}.deviceDnsName'
      | stats values(firstActivityDateTime) as firstActivityDateTime,values(evidence{}.osPlatform) as osPlatform,values(recommendedActions) as recommendedActions values(alertWebUrl) as alertWebUrl count by _time,src_host,src_user,test_id 
      | eval tactics="lateral-movement", techniques="t1570,t1021"
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
      owner = "admin"
      sharing = "app"
      app = "search"
    }
}