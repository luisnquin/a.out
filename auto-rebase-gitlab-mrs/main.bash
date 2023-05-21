#!/usr/bin/env bash

log_and_exit_1() {
    printf "\033[38;2;201;71;71m%s: %s\033[0m\n" "error" "$1"
    return 1
}

set -e

if ! command -v "jq" &>/dev/null; then
    log_and_exit_1 "'jq' was not found in your PATH"
fi

if [ "$GITLAB_PERSONAL_TOKEN" = "" ]; then
    log_and_exit_1 "missing 'GITLAB_PERSONAL_TOKEN' environment variable"
elif [ "$GITLAB_PROJECT_ID" = "" ]; then
    log_and_exit_1 "missing 'GITLAB_PROJECT_ID' environment variable"
elif ! [[ "$GITLAB_PROJECT_ID" =~ ^[0-9]+$ ]]; then
    log_and_exit_1 "'GITLAB_PROJECT_ID' value is not valid (not a number)"
elif [ "$GITLAB_HOST" = "" ]; then
    log_and_exit_1 "missing 'GITLAB_HOST' environment variable"
fi

api_base_url="$GITLAB_HOST/api/v4/projects"

echo "Fetching opened merge requests in project with id $GITLAB_PROJECT_ID..."

opened_merge_requests=$(curl -sH "Authorization: Bearer $GITLAB_PERSONAL_TOKEN" "$api_base_url/$GITLAB_PROJECT_ID/merge_requests?state=opened")

count=$(echo "$opened_merge_requests" | jq '. | length')

echo "There are $count merge requests opened, ensuring that they are up to date..."

for ((i = 0; i < count; i++)); do
    iid=$(echo "$opened_merge_requests" | jq -r '.['$i'].iid')

    echo "$opened_merge_requests" | jq -c '.['$i'] | {iid: .iid, title: .title, author: .author.name, created_at: .created_at, source_branch: .source_branch, target_branch: .target_branch}'

    curl -sX PUT -H "Authorization: Bearer $GITLAB_PERSONAL_TOKEN" "$api_base_url/$GITLAB_PROJECT_ID/merge_requests/$iid/rebase" >/dev/null && echo
done
