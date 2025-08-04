# Splunk
All Splunk-related details and commands will be shared in this repository.

In the **mid-2000s**, data was broadly categorized into:
- **User Data**
- **Infrastructure Data**
- **Application Data**

For example:
- Based on user searches, platforms like **YouTube** began recommending similar content.
- Similarly, websites started using **user data** for personalized recommendations.

During this period, data from infrastructure, users, and applications was stored in systems like:
- **Data Warehouses**
- **Data Lakes**

---

## 🔍 Search Engines and Splunk Buckets

- In **Splunk**, data is managed through different types of **buckets** (e.g., hot, warm, cold, frozen) that represent the data lifecycle stages.
- In **Dynatrace**, the data processing is more abstracted and focused on end-to-end observability rather than raw log analysis.

---

## 🆚 Observability vs. Monitoring

**Monitoring** and **Observability** serve different purposes:

| Aspect           | Monitoring                        | Observability                                        |
|------------------|-----------------------------------|------------------------------------------------------|
| Approach         | Reactive                          | Proactive                                            |
| Purpose          | Detect and respond to issues      | Understand system behavior before issues arise       |
| Tools Used       | Alerts, thresholds, dashboards    | Metrics, logs, traces                                |
| Action Timing    | After a problem occurs            | Before the problem becomes critical                  |

---

## 📊 Three Pillars of Observability

1. **Metrics**  
   - Numerical data showing performance (e.g., CPU usage, request rates).

2. **Logs**  
   - Time-stamped event records, mainly used for debugging and tracking changes.

3. **Traces**  
   - Show the end-to-end journey of a request across multiple services or nodes.

Here is a polished and structured version of your notes on **Data Injections in Splunk**:

---

## **Data Injections in Splunk**

Splunk supports two primary methods for ingesting data:

* **Agent-based (using a software agent)**
* **Agentless (without installing software on the source machine)**

### **1. Forwarders (Agent-based)**

* **Universal Forwarder (UF):** Lightweight agent installed on the source system to collect and forward logs to the Splunk Indexer.
* **Heavy Forwarder (HF):** Capable of parsing, filtering, and routing data before forwarding.

### **2. Scripted Inputs**

* Used to collect data via custom scripts (e.g., Python, Bash).
* Useful for collecting metrics from APIs, command outputs, etc.
* Runs at a scheduled interval from within Splunk.

### **3. HTTP Event Collector (HEC)**

* Enables data ingestion over HTTP/HTTPS.
* Typically used for real-time data from applications, IoT devices, mobile apps, etc.
* Token-based authentication.

### **4. Splunk Apps or Add-ons**

* Prebuilt integrations for specific technologies (e.g., AWS, Microsoft, Cisco).
* Often include inputs, dashboards, and knowledge objects for specific data sources.

### **5. Syslog (Agentless)**

* Devices send log data via the Syslog protocol (UDP 514/TCP 514).
* Data is received by a Syslog server or Splunk instance configured to receive syslog messages.

---

## **Components of Splunk**
Splunk architecture is divided into **Core Components** and **Management Servers**.
### 🔹 **Core Components**
1. **Forwarder**

   * Collects and sends data to the indexer.
   * Two types: **Universal Forwarder** (lightweight) and **Heavy Forwarder** (with parsing capability).

2. **Indexer**
   * Stores, parses, and indexes incoming data.
   * Splunk's internal database where the searchable data resides.

3. **Search Head**
   * The user interface (GUI) where users can run searches, create reports, dashboards, and alerts.
   * Does not store data but distributes search queries across indexers.

4. **License Master**
   * Manages Splunk license usage.
   * Monitors indexing volume across all Splunk instances.

### 🔹 **Management Servers**
5. **Deployment Server**
   * Used to centrally manage and distribute configurations and apps to multiple forwarders.

6. **Deployer**
   * Specifically used in **Search Head Clustering** to distribute configurations and apps across clustered search heads.

7. **Cluster Master (now called Cluster Manager)**
   * Manages **Indexer Clustering**.
   * Ensures data replication, indexing integrity, and coordination between peer nodes.
---
## **Splunk Licensing**
---
### 🔹 **License Master**
* Acts as a **policy enforcer** to ensure all Splunk components comply with the licensing terms.
* Tracks and monitors the amount of data indexed per day across the deployment.
* Issues warnings if data ingestion exceeds the licensed volume.
---
### 🔹 **License Cycle**
* Splunk licenses operate on a **24-hour cycle**, resetting daily.
* The cycle typically runs from **12:00 AM to 11:59 PM** (not 12 AM to 9 PM).
* Licensing is based on the **daily volume of indexed data** (measured in GB or TB).
* **Bulk license purchases** often come with **discounted pricing** — the more you buy, the lower the cost per GB.
---
### 🔹 **Types of Splunk Licensing Models**
1. **Splunk Enterprise (Self-Managed)**
   * Installed and managed on-premises or in your own cloud environment.
   * You handle infrastructure, scaling, and maintenance.

2. **Splunk Cloud (SaaS)**
   * Fully managed by Splunk as a **Software-as-a-Service (SaaS)** offering.
   * Splunk handles updates, scaling, and infrastructure management.
---



