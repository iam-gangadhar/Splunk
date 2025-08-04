import random
import datetime
import json
import re
import requests
import urllib3
import warnings
from pathlib import Path

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def generate_random_string(length=8):
    return ''.join(random.choices('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', k=length))

def get_current_timestamps():
    now = datetime.datetime.now(datetime.timezone.utc).astimezone()
    full = now.strftime("[%d/%b/%Y:%H:%M:%S %z]")
    short = now.strftime("%b %d %H:%M:%S")
    iso = now.isoformat(timespec='microseconds')
    return full, short, iso

def generate_dummy_file(dummy_filename):
    print(f"Creating dummy log file: {dummy_filename} with 20 random entries.")
    with open(dummy_filename, 'w') as f:
        for _ in range(20):
            log_type = random.randint(0, 2)
            full, short, iso = get_current_timestamps()
            if log_type == 0:
                messages = [
                    f"INFO: User 'testuser{random.randint(0,99)}' logged in from 192.168.1.{random.randint(0,254)}.",
                    f"WARNING: Disk space low on /var. Free: {random.randint(0,99)}MB.",
                    "ERROR: Failed to connect to database 'db_prod' on port 5432.",
                    f"DEBUG: Processing request for /api/data?id={random.randint(0,999)}."
                ]
                f.write(f"{full} {random.choice(messages)}\n")
            elif log_type == 1:
                hostnames = ["webserver01", "dbserver01", "appserver01"]
                processes = ["sshd", "apache", "nginx", "mysqld"]
                syslog_messages = [
                    "authentication failure; user unknown",
                    f"connection reset by peer from 10.0.0.{random.randint(0,254)}",
                    f"Invalid user 'admin' from {random.randint(0,255)}.{random.randint(0,255)}.{random.randint(0,255)}.{random.randint(0,255)};",
                    "INFO: Service 'cron' started."
                ]
                f.write(f"{short} {random.choice(hostnames)} {random.choice(processes)}[{random.randint(1000,49999)}]: {random.choice(syslog_messages)}\n")
            else:
                json_messages = [
                    {"EventTime": iso, "Hostname": f"host{random.randint(0,4)}", "Keywords": "12345", "EventType": "AUDIT_SUCCESS",
                     "Message": f"User {random.randint(0,99)} accessed resource /data/file{random.randint(0,19)}.txt", "Category": "File Access",
                     "SourceModuleType": "im_filelog", "EventReceivedTime": iso},
                    {"EventTime": iso, "Hostname": f"firewall{random.randint(0,2)}", "EventType": "FIREWALL_DENY", "Severity": "HIGH",
                     "Message": f"Blocked connection from {'.'.join(str(random.randint(0,255)) for _ in range(4))} to port 80",
                     "SourceModuleType": "in_netflow", "IpAddress": f"{'.'.join(str(random.randint(0,255)) for _ in range(4))}",
                     "Port": str(random.randint(0,65534)), "EventReceivedTime": iso},
                    {"EventTime": iso, "method": "GET", "path": f"/api/users/{random.randint(0,999)}", "status": 200,
                     "response_time_ms": random.randint(0,499), "user_agent": "Mozilla/5.0", "EventReceivedTime": iso},
                    {"EventTime": iso, "method": "POST", "path": "/api/orders", "status": 500,
                     "error": "Internal Server Error", "request_body_size": random.randint(0,1023),
                     "EventReceivedTime": iso}
                ]
                f.write(json.dumps(random.choice(json_messages)) + '\n')
    print("Dummy file generation complete.")

def replace_timestamps(input_file, output_file):
    full, short, iso = get_current_timestamps()
    with open(input_file, 'r') as infile, open(output_file, 'w') as outfile:
        for line in infile:
            line = re.sub(r'\[\d{2}/[A-Za-z]{3}/\d{4}:\d{2}:\d{2}:\d{2} [+-]\d{4}\]', full, line)
            line = re.sub(r'^[A-Za-z]{3} +\d{1,2} +\d{2}:\d{2}:\d{2}', short, line)
            line = re.sub(r'"EventTime":"[^"]+"', f'"EventTime":"{iso}"', line)
            line = re.sub(r'"EventReceivedTime":"[^"]+"', f'"EventReceivedTime":"{iso}"', line)
            outfile.write(line)
    print(f"✅ Conversion complete. Output written to {output_file}")

def upload_to_splunk(file_path, tenant_id, token, sourcetype, index, batch_size=80):
    print("📤 Uploading to Splunk (batched)...")
    url = f"https://{tenant_id}.splunkcloud.com:8088/services/collector"
    headers = {
        "Authorization": f"Splunk {token}",
        "Content-Type": "application/json"
    }
    batch = []
    with open(file_path, 'r') as f:
        for line in f:
            payload = {
                "event": json.loads(line) if line.strip().startswith("{") else line.strip(),
                "sourcetype": sourcetype,
                "host": "server02",
                "source": "/opt/var/logs/access.log",
                "index": index
            }
            batch.append(payload)
            if len(batch) >= batch_size:
                try:
                    response = requests.post(url, headers=headers, data=json.dumps(batch), verify=False)
                    print(f"📨 Sent batch -> HTTP {response.status_code}")
                except Exception as e:
                    print(f"❌ Error: {e}")
                batch = []
    if batch:
        try:
            response = requests.post(url, headers=headers, data=json.dumps(batch), verify=False)
            print(f"📨 Sent final batch -> HTTP {response.status_code}")
        except Exception as e:
            print(f"❌ Error: {e}")

def upload_to_dynatrace(file_path, tenant_id, api_token, log_source=None, host=None, batch_size=80):
    print("📤 Uploading to Dynatrace (batched)...")
    url = f"https://{tenant_id}.live.dynatrace.com/api/v2/logs/ingest"
    headers = {
        "Authorization": f"Api-Token {api_token}",
        "Content-Type": "application/json"
    }
    _, _, timestamp = get_current_timestamps()
    batch = []

    with open(file_path, 'r') as f:
        for line in f:
            if not line.strip():
                continue
            payload = {"content": line.strip(), "timestamp": timestamp}
            if log_source:
                payload["log.source"] = log_source
            if host:
                payload["host"] = host
            batch.append(payload)

            if len(batch) >= batch_size:
                try:
                    response = requests.post(url, headers=headers, json=batch)
                    print(f"📨 Sent batch -> HTTP {response.status_code}")
                except Exception as e:
                    print(f"❌ Error: {e}")
                batch = []

    if batch:
        try:
            response = requests.post(url, headers=headers, json=batch)
            print(f"📨 Sent final batch -> HTTP {response.status_code}")
        except Exception as e:
            print(f"❌ Error: {e}")

def main():
    input_file = input("📝 Enter input file name (press Enter to generate dummy): ").strip()
    if not input_file:
        input_file = f"dummy_log_{datetime.datetime.now().strftime('%Y%m%d%H%M%S')}.txt"
        generate_dummy_file(input_file)
    elif not Path(input_file).is_file():
        print("❌ File not found.")
        return

    output_file = f"{Path(input_file).stem}-converted{Path(input_file).suffix}"
    replace_timestamps(input_file, output_file)

    if input("Upload to Splunk? (yes/no): ").strip().lower() in ['yes', 'y']:
        tenant_id = input("Splunk Tenant ID: ")
        token = input("Splunk HEC Token: ")
        sourcetype = input("Sourcetype: ")
        index = input("Index: ")
        upload_to_splunk(output_file, tenant_id, token, sourcetype, index)

    if input("Upload to Dynatrace? (yes/no): ").strip().lower() in ['yes', 'y']:
        tenant_id = input("Dynatrace Tenant ID (no .live): ")
        token = input("Dynatrace API Token: ")
        log_source = input("Dynatrace Log Source (optional): ")
        host = input("Dynatrace Host (optional): ")
        upload_to_dynatrace(output_file, tenant_id, token, log_source, host)

if __name__ == "__main__":
    main()

