# Container Monitoring & Auto-Healing System

Automated Bash monitoring and self-healing solution that inspects Docker containers, restarts failed services, creates Jira incident tickets, and sends real-time Slack alerts.

## Architecture Flow
1. **Health Verification:** Checks container runtime status (`docker inspect`) and HTTP availability (`curl`) every 2 minutes via `cron`.
2. **Auto-Healing:** Automatically restarts stopped or unhealthy containers (`docker restart`) and verifies `HTTP 200` recovery.
3. **Incident Management:** Opens a tracked Jira ticket automatically using the Jira REST API v3 and `jq`.
4. **Real-Time Alerting:** Dispatches a formatted incident alert with a direct Jira ticket link to Slack via Incoming Webhooks.

## Setup Instructions
1. Clone the repository:
   ```bash
   git clone https://github.com/goswamikashyap/container-auto-heale.git
   cd container-auto-healer
   ```
2. Copy the environment template and fill in your credentials:
   ```bash
   cp .env.example .env
   ```
3. Run the idempotent cron installer:
   ```bash
   chmod +x setup_cron.sh && ./setup_cron.sh
   ```
--------------------------------------------------------------------------------------------------------------------------------------------------
## Live Proof of Execution

### 1. Automated Recovery Log
<img width="1088" height="301" alt="recoverylogs" src="https://github.com/user-attachments/assets/208e6cfe-5c56-4780-b0a9-902f943cd3bb" />

### 2. Real-Time Slack Incident Alert
<img width="1280" height="683" alt="slack" src="https://github.com/user-attachments/assets/8140e636-9271-4ece-b991-dca746f81082" />

### 3. Automated Jira Incident Ticket
<img width="821" height="670" alt="jiraticket" src="https://github.com/user-attachments/assets/3982d106-820a-4d15-be26-149b007a850a" />

