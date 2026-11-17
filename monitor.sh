#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE}")" && pwd)"
source "$SCRIPT_DIR/.env"

LOG_FILE="$SCRIPT_DIR/logs/health.log"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

log_message() {
    echo "[$TIMESTAMP] $1" >> "$LOG_FILE"
}

send_slack_alert() {
    local message="$1"
    curl -s -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"$message\"}" \
        "$SLACK_WEBHOOK_URL" > /dev/null
}

create_jira_ticket() {
    local summary="$1"
    local description="$2"

    JSON_PAYLOAD=$(jq -n \
        --arg proj "$JIRA_PROJECT_KEY" \
        --arg sum "$summary" \
        --arg desc "$description" \
        '{
            fields: {
                project: { key: $proj },
                summary: $sum,
                description: {
                    type: "doc",
                    version: 1,
                    content: [{
                        type: "paragraph",
                        content: [{ type: "text", text: $desc }]
                    }]
                },
                issuetype: { name: "Task" }
            }
        }')

    RESPONSE=$(curl -s -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
        -X POST \
        -H "Content-Type: application/json" \
        --data "$JSON_PAYLOAD" \
        "$JIRA_BASE_URL/rest/api/3/issue")

    echo "$RESPONSE" | jq -r '.key // "FAILED"'
}

# 1. Check container status and HTTP response
IS_RUNNING=$(docker inspect -f '{{.State.Running}}' "$CONTAINER_NAME" 2>/dev/null)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_URL")

if [ "$IS_RUNNING" == "true" ] && [ "$HTTP_CODE" == "200" ]; then
    log_message "OK: $CONTAINER_NAME is healthy (HTTP $HTTP_CODE)."
    exit 0
fi

# 2. Restart failed container
log_message "ALERT: $CONTAINER_NAME failed (Running=$IS_RUNNING, HTTP=$HTTP_CODE). Restarting..."
docker restart "$CONTAINER_NAME" > /dev/null 2>&1
sleep 3

# 3. Verify recovery
NEW_HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_URL")

if [ "$NEW_HTTP_CODE" == "200" ]; then
    STATUS_MSG="Auto-healed successfully (HTTP $NEW_HTTP_CODE)."
else
    STATUS_MSG="CRITICAL: Restart failed! Manual intervention required."
fi

log_message "$STATUS_MSG"

# 4. Create Jira Ticket & Alert Slack
JIRA_SUMMARY="[Auto-Heal] Container $CONTAINER_NAME crashed on $(hostname)"
JIRA_DESC="Failure detected at $TIMESTAMP. Initial state: Running=$IS_RUNNING, HTTP=$HTTP_CODE. Recovery result: $STATUS_MSG"
TICKET_ID=$(create_jira_ticket "$JIRA_SUMMARY" "$JIRA_DESC")

log_message "Jira ticket created: $TICKET_ID"

SLACK_TEXT="🚨 *Container Incident Detected*\n• *Host:* $(hostname)\n• *Container:* \`$CONTAINER_NAME\`\n• *Status:* $STATUS_MSG\n• *Jira Ticket:* <$JIRA_BASE_URL/browse/$TICKET_ID|$TICKET_ID>"
send_slack_alert "$SLACK_TEXT"

