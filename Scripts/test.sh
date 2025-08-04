#!/bin/bash
# contact: Akhil Jayendran TEKsystems
output_file="converted_log.txt"


generate_random_string() {
  head /dev/urandom | tr -dc A-Za-z0-9 | head -c 8
}


generate_dummy_file() {
  local dummy_filename="$1"
  local num_lines=20

  echo "Creating dummy log file: $dummy_filename with $num_lines random entries."
  > "$dummy_filename" 

  for i in $(seq 1 $num_lines); do
    log_type=$(( RANDOM % 3 )) 


    local current_ts_full="[$(date '+%d/%b/%Y:%H:%M:%S %z')]"
    local current_ts_short="$(date '+%b %d %H:%M:%S')"

    local json_datetime_part=$(date '+%Y-%m-%dT%H:%M:%S')
    local nanoseconds=$(date '+%N' 2>/dev/null || echo "000000000")
    local microseconds=$(echo "$nanoseconds" | cut -c1-6)
    local timezone_offset_raw=$(date '+%z')
    local timezone_offset_formatted
    if [[ "$timezone_offset_raw" =~ ^[+-][0-9]{4}$ ]]; then
      timezone_offset_formatted="${timezone_offset_raw:0:3}:${timezone_offset_raw:3:2}"
    else
      timezone_offset_formatted="+00:00"
    fi
    local current_ts_json="${json_datetime_part}.${microseconds}${timezone_offset_formatted}"


    case $log_type in
      0)
        messages=(
          "INFO: User 'testuser$((RANDOM % 100))' logged in successfully from 192.168.1.$((RANDOM % 255))."
          "WARNING: Disk space low on /var. Free: $((RANDOM % 100))MB."
          "ERROR: Failed to connect to database 'db_prod' on port 5432."
          "DEBUG: Processing request for /api/data?id=$((RANDOM % 1000))."
        )
        echo "$current_ts_full ${messages[$((RANDOM % ${#messages[@]}))]}" >> "$dummy_filename"
        ;;
      1) 
        hostnames=("webserver01" "dbserver01" "appserver01")
        processes=("sshd" "apache" "nginx" "mysqld")
        syslog_messages=(
          "authentication failure; user unknown"
          "connection reset by peer from 10.0.0.$((RANDOM % 255))"
          "Invalid user 'admin' from $((RANDOM % 255)).$((RANDOM % 255)).$((RANDOM % 255)).$((RANDOM % 255));"
          "INFO: Service 'cron' started."
        )
        echo "$current_ts_short ${hostnames[$((RANDOM % ${#hostnames[@]}))]} ${processes[$((RANDOM % ${#processes[@]}))]}[$((RANDOM % 50000))]: ${syslog_messages[$((RANDOM % ${#syslog_messages[@]}))]}" >> "$dummy_filename"
        ;;
      2) 
        json_messages=(
          "{\"EventTime\":\"${current_ts_json}\",\"Hostname\":\"host$((RANDOM % 5))\",\"Keywords\":\"12345\",\"EventType\":\"AUDIT_SUCCESS\",\"Message\":\"User $((RANDOM % 100)) accessed resource /data/file$((RANDOM % 20)).txt\",\"Category\":\"File Access\",\"SourceModuleType\":\"im_filelog\",\"EventReceivedTime\":\"${current_ts_json}\"}"
          "{\"EventTime\":\"${current_ts_json}\",\"Hostname\":\"firewall$((RANDOM % 3))\",\"EventType\":\"FIREWALL_DENY\",\"Severity\":\"HIGH\",\"Message\":\"Blocked connection from $((RANDOM % 255)).$((RANDOM % 255)).$((RANDOM % 255)).$((RANDOM % 255)) to port 80\",\"SourceModuleType\":\"in_netflow\",\"IpAddress\":\"$((RANDOM % 255)).$((RANDOM % 255)).$((RANDOM % 255)).$((RANDOM % 255))\",\"Port\":\"$((RANDOM % 65535))\",\"EventReceivedTime\":\"${current_ts_json}\"}"
          "{\"EventTime\":\"${current_ts_json}\",\"method\":\"GET\",\"path\":\"/api/users/$((RANDOM % 1000))\",\"status\":200,\"response_time_ms\":$((RANDOM % 500)),\"user_agent\":\"Mozilla/5.0\",\"EventReceivedTime\":\"${current_ts_json}\"}"
          "{\"EventTime\":\"${current_ts_json}\",\"method\":\"POST\",\"path\":\"/api/orders\",\"status\":500,\"error\":\"Internal Server Error\",\"request_body_size\":$((RANDOM % 1024)),\"EventReceivedTime\":\"${current_ts_json}\"}"
        )
        echo "${json_messages[$((RANDOM % ${#json_messages[@]}))]}" >> "$dummy_filename"
        ;;
    esac
  done
  echo "Dummy file generation complete."
}


read -p "📝 Please enter the input file name (e.g., your_file.txt), or press Enter to generate a dummy file: " input_file


if [[ -z "$input_file" ]]; then
  input_file="dummy_log_$(date +%Y%m%d%H%M%S).txt"
  generate_dummy_file "$input_file"
fi


if [[ ! -f "$input_file" ]]; then
  echo "❌ Input file '$input_file' not found."
  exit 1
fi


current_date_full_formatted="[$(date '+%d/%b/%Y:%H:%M:%S %z')]"


current_date_short_formatted="$(date '+%b %d %H:%M:%S')"


json_datetime_part=$(date '+%Y-%m-%dT%H:%M:%S')
nanoseconds=$(date '+%N' 2>/dev/null || echo "000000000")
microseconds=$(echo "$nanoseconds" | cut -c1-6)
timezone_offset_raw=$(date '+%z')
if [[ "$timezone_offset_raw" =~ ^[+-][0-9]{4}$ ]]; then
  timezone_offset_formatted="${timezone_offset_raw:0:3}:${timezone_offset_raw:3:2}"
else
  timezone_offset_formatted="+00:00"
fi
current_date_json_formatted="${json_datetime_part}.${microseconds}${timezone_offset_formatted}"


awk -v newdate_full="$current_date_full_formatted" \
    -v newdate_short="$current_date_short_formatted" \
    -v newdate_json="$current_date_json_formatted" '
{
  # Regex for the first timestamp format: [DD/Mon/YYYY:HH:MM:S +ZZZZ]
  if ($0 ~ /\[[0-9]{2}\/[A-Za-z]{3}\/[0-9]{4}:[0-9]{2}:[0-9]{2}:[0-9]{2} [+-][0-9]{4}\]/) {
    gsub(/\[[0-9]{2}\/[A-Za-z]{3}\/[0-9]{4}:[0-9]{2}:[0-9]{2}:[0-9]{2} [+-][0-9]{4}\]/, newdate_full);
  }
  # Regex for the second timestamp format: Mon DD HH:MM:SS
  else if ($0 ~ /^[A-Za-z]{3} +[0-9]{1,2} +[0-9]{2}:[0-9]{2}:[0-9]{2}/) {
    sub(/^[A-Za-z]{3} +[0-9]{1,2} +[0-9]{2}:[0-9]{2}:[0-9]{2}/, newdate_short);
  }
  # Regex for JSON logs with "EventTime" and "EventReceivedTime" fields
  else if ($0 ~ /\{.*("EventTime"|"EventReceivedTime"):".*}/) {
      sub(/"EventTime":"[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+[+-][0-9]{2}:[0-9]{2}"/, "\"EventTime\":\"" newdate_json "\"", $0);
      sub(/"EventReceivedTime":"[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+[+-][0-9]{2}:[0-9]{2}"/, "\"EventReceivedTime\":\"" newdate_json "\"", $0);
  }
  print;
}' "$input_file" > "$output_file"

echo "✅ Conversion complete. Output written to $output_file"


read -p "🚀 Do you want to upload the updated log to Splunk? (yes/no): " upload_decision

if [[ "$upload_decision" =~ ^[Yy][Ee]?[Ss]$ ]]; then
  read -p "🔑 Enter Splunk Tenant ID (e.g., prd-p-xxxx): " tenant_id
  read -p "🪪 Enter Splunk HEC Token: " token
  read -p "📦 Enter Sourcetype (e.g., test_script): " sourcetype
  read -p "📁 Enter Index (e.g., main): " index

  echo "📤 Uploading converted logs to Splunk HEC..."

  while IFS= read -r line; do
  
    if [[ "$line" =~ ^\{.*\}$ ]]; then
      json_payload=$(cat <<EOF
{
  "event": $line,
  "sourcetype": "$sourcetype",
  "host": "server02",
  "source": "/opt/var/logs/access.log",
  "index": "$index"
}
EOF
)
    else
      escaped_line=$(echo "$line" | sed 's/"/\\"/g')
      json_payload=$(cat <<EOF
{
  "event": "$escaped_line",
  "sourcetype": "$sourcetype",
  "host": "server02",
  "source": "/opt/var/logs/access.log",
  "index": "$index"
}
EOF
)
    fi

    
    response=$(curl -k -s -o /dev/null -w "%{http_code}" \
      "https://${tenant_id}.splunkcloud.com:8088/services/collector" \
      -H "Authorization: Splunk $token" \
      -H "Content-Type: application/json" \
      -d "$json_payload")

    echo "📨 Sent log line -> HTTP status: $response"
  done < "$output_file"
else
  echo "🚫 Splunk upload skipped."
fi


read -p "🚀 Do you want to upload the updated log to Dynatrace? (yes/no): " dynatrace_upload_decision

if [[ "$dynatrace_upload_decision" =~ ^[Yy][Ee]?[Ss]$ ]]; then
  read -p "🔑 Enter Dynatrace Tenant ID (e.g., yourtenant.live.dynatrace.com): " dynatrace_tenant_id
  read -p "🪪 Enter Dynatrace API Token: " dynatrace_token
  read -p "📦 Enter Dynatrace Log Source (optional, e.g., my_app_logs): " dynatrace_log_source
  read -p "📁 Enter Dynatrace Host (optional, e.g., blabla011): " dynatrace_host

  echo "📤 Uploading converted logs to Dynatrace Logs API..."

  dynatrace_api_url="https://${dynatrace_tenant_id}.live.dynatrace.com/api/v2/logs/ingest"

  while IFS= read -r line; do

    escaped_line_for_dynatrace=$(echo "$line" | sed 's/"/\\"/g')


    dynatrace_payload="{\"content\": \"$escaped_line_for_dynatrace\""


    if [[ -n "$dynatrace_log_source" ]]; then
      dynatrace_payload+=",\"log.source\": \"$dynatrace_log_source\""
    fi

    dynatrace_payload+=",\"timestamp\": \"$current_date_json_formatted\""

    if [[ -n "$dynatrace_host" ]]; then
      dynatrace_payload+=",\"host\": \"$dynatrace_host\""
    fi

    dynatrace_payload+="}" 

  
    response=$(curl -w '%{http_code}' \
      -X 'POST' \
      "$dynatrace_api_url" \
      -H 'Accept: application/json; charset=utf-8' \
      -H "Authorization: Api-Token $dynatrace_token" \
      -H 'Content-Type: application/json; charset=utf-8' \
      -d "$dynatrace_payload")

    echo "📨 Sent log line to Dynatrace -> HTTP status: $response"
  done < "$output_file"
else
  echo "🚫 Dynatrace upload skipped."
fi
