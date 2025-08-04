# 📘 Splunk Learning Commands & Notes

This file contains key Splunk SPL commands with brief explanations for quick reference and learning.

---

## 📊 Basic `stats` Commands

### 1. Sum of Bytes by Sourcetype
```spl
index="_internal"
| stats sum(bytes) as bytes by sourcetype
```

* Aggregates and displays the total bytes for each sourcetype.

### 2. Average of Bytes by Sourcetype
```
index="_internal"
| stats avg(bytes) as bytes by sourcetype
```
* Calculates the average bytes for each sourcetype.

### 📂 stats with list and values
### 3. Unique Values of source per Sourcetype
```
index="_internal"
| stats values(source) as source by sourcetype
```
*  Returns only unique source values for each sourcetype.

### 4. All Values of source per Sourcetype
```
index="_internal"
| stats list(source) as source by sourcetype
```
* Returns all (including duplicates) source values for each sourcetype.
    - values() ➜ Only unique values
    - list() ➜ All values, including duplicates
### 🧮 eval Command (Used for calculations or conditionals)
### 5. Convert Bytes to KB
```
index="_internal"
| eval kb = round(bytes/1024, 3)." KB"
| table bytes, kb
```
* Converts bytes to kilobytes with 3 decimal precision and displays both.
### 6. if Condition Example
```
index="main" sourcetype="linux_bootlog"
| stats count by user
| eval user_type = if(user="root", "super_user", "test_user")
```
### 7. 🧹 Remove Duplicate Values
using dedup
```
index="main" sourcetype="linux_bootlog"
| dedup user
```
### 8. 🔍 Filtering Data
```
index="main" sourcetype="linux_bootlog"
| stats count by user 
| eval threshold = 15 
| search count > 10 
| where count > threshold
```
* search is used to filter results directly (e.g., count > 10).
    - where is used to compare two fields/expressions (e.g., count > threshold).
    - Use search for simple field filtering.
    - Use where for comparing field values or expressions.

### 9. Rename Fields with table and rename
```
index="main" sourcetype="linux_bootlog"
| table rhost, user 
| rename rhost as "Host Name", user as user_nam
```
* table selects and displays only the rhost and user fields.
    - rename changes:
    - rhost ➜ "Host Name" (note the space and quotes)
    - user ➜ user_nam (new alias for user field)
* 🔄 Use rename to improve field readability or map field names to desired labels in reports and dashboards.