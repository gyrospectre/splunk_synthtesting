terraform {
  required_providers {
    splunk = {
      source = "splunk/splunk"
    }
  }
}

provider "splunk" {
  url                  = "localhost:8089"
  username             = "admin"
  password             = var.splunk_pass
  insecure_skip_verify = true
}

resource "splunk_indexes" "alerts" {
  name = "alerts"
}

resource "splunk_indexes" "synthtest" {
  name = "synthtest"
}

resource "splunk_inputs_http_event_collector" "synth-testing" {
  name       = "synth-testing"
  index      = "synthtest"
  indexes    = ["main", "synthtest", "alerts"]
  disabled   = false
  use_ack    = 0
  acl {
    owner   = "admin"
    sharing = "global"
    read    = ["admin"]
    write   = ["admin"]
  }
}

module "rules" {
  source    = "./rules"
}

resource "splunk_saved_searches" "test_results" {
    name                    = "Collect Synth Test Results"
    search                  = <<-EOT
        (index="synthtest" AND sourcetype="test_run") OR index="alerts"
        | eval rule=coalesce(search_name, tests_rule) 
        | eval test_time=if(index="synthtest",_time,null())
        | stats values(index) as indexes earliest(info_max_time) as alert_time earliest(test_time) as test_time values(expected_within) as expected_within latest(test_time) as most_recent_test values(tactics) as tactics values(techniques) as techniques by test_id,rule
        | convert num(alert_time)
        | convert num(test_time)
        | eval latency=tostring(round(alert_time-test_time), "duration")
        | eval index_count = mvcount(indexes)
        | eval _time = now()
        | fields - indexes, most_recent_test
        | eval status=if((latency < expected_within and index_count=2), "Passing", "Failing")
        | collect index=synthtest sourcetype=test_result
    EOT
    dispatch_earliest_time  = "-24h"
    dispatch_latest_time    = "now"
    cron_schedule           = "0 8 * * *"
    is_scheduled            = true
    acl {
      owner   = "admin"
      sharing = "app"
      app     = "search"
    }
}

resource "splunk_saved_searches" "failed_test_alert" {
    name                        = "Alert on Failed Tests"
    search                      = "index=synthtest sourcetype=test_result status=Failing"
    actions                     = "email"
    action_email_format         = "table"
    action_email_max_time       = "5m"
    action_email_max_results    = 10
    action_email_send_results   = true
    action_email_subject        = "Splunk Alert: $name$"
    action_email_to             = "alerts@gyrospectre.internal"
    action_email_track_alert    = true
    dispatch_earliest_time      = "-24h"
    dispatch_latest_time        = "now"
    cron_schedule               = "0 9 * * *"
    is_scheduled            = true
    acl {
      owner = "admin"
      sharing = "app"
      app = "search"
    }
}