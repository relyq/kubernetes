#!/bin/bash

set -euo pipefail

hostname=https://obsidian-livesync.relyq.dev
username=relyq
password=

echo "--> Enabling single-node mode..."

until curl -fsS -X POST "${hostname}/_cluster_setup" \
  -H "Content-Type: application/json" \
  -d "{\"action\":\"enable_single_node\",\"username\":\"${username}\",\"password\":\"${password}\",\"bind_address\":\"0.0.0.0\",\"port\":5984,\"singlenode\":true}" \
  --user "${username}:${password}"; do
  echo "retrying cluster setup..."
  sleep 5
done

echo "--> Fetching active CouchDB node(s)..."

NODES=$(curl -fsS -u "${username}:${password}" "${hostname}/_membership" | jq -r '.cluster_nodes[] | select(contains("nonode") | not)')

if [ -z "$NODES" ]; then
  echo "no valid nodes found in cluster. aborting."
  exit 1
fi

echo "--> Found node(s):"
echo "$NODES"

for node in $NODES; do
  echo "--> Configuring node: $node"

  until curl -fsS -X PUT "${hostname}/_node/${node}/_config/chttpd/require_valid_user" \
    -H "Content-Type: application/json" \
    -d '"true"' --user "${username}:${password}"; do sleep 5; done

  until curl -fsS -X PUT "${hostname}/_node/${node}/_config/chttpd_auth/require_valid_user" \
    -H "Content-Type: application/json" \
    -d '"true"' --user "${username}:${password}"; do sleep 5; done

  until curl -fsS -X PUT "${hostname}/_node/${node}/_config/httpd/WWW-Authenticate" \
    -H "Content-Type: application/json" \
    -d '"Basic realm=\"couchdb\""' --user "${username}:${password}"; do sleep 5; done

  until curl -fsS -X PUT "${hostname}/_node/${node}/_config/httpd/enable_cors" \
    -H "Content-Type: application/json" \
    -d '"true"' --user "${username}:${password}"; do sleep 5; done

  until curl -fsS -X PUT "${hostname}/_node/${node}/_config/chttpd/enable_cors" \
    -H "Content-Type: application/json" \
    -d '"true"' --user "${username}:${password}"; do sleep 5; done

  until curl -fsS -X PUT "${hostname}/_node/${node}/_config/chttpd/max_http_request_size" \
    -H "Content-Type: application/json" \
    -d '"4294967296"' --user "${username}:${password}"; do sleep 5; done

  until curl -fsS -X PUT "${hostname}/_node/${node}/_config/couchdb/max_document_size" \
    -H "Content-Type: application/json" \
    -d '"50000000"' --user "${username}:${password}"; do sleep 5; done

  until curl -fsS -X PUT "${hostname}/_node/${node}/_config/cors/credentials" \
    -H "Content-Type: application/json" \
    -d '"true"' --user "${username}:${password}"; do sleep 5; done

  until curl -fsS -X PUT "${hostname}/_node/${node}/_config/cors/origins" \
    -H "Content-Type: application/json" \
    -d '"app://obsidian.md,capacitor://localhost,http://localhost,https://obsidian-livesync.relyq.dev"' --user "${username}:${password}"; do sleep 5; done
done

echo "--> CouchDB initialization complete."


# export hostname=https://obsidian-livesync.relyq.dev && export database=obsidian && export passphrase=cyfR9E2HUZdcokomtVHD && export username=relyq && export password=w4FsWfSJCahmXrQDSsd2 && deno run -A https://raw.githubusercontent.com/vrtmrz/obsidian-livesync/main/utils/flyio/generate_setupuri.ts
# curl -i -X OPTIONS https://obsidian-livesync.relyq.dev -H "Origin: app://obsidian.md" -H "Access-Control-Request-Method: PUT" -H "Access-Control-Request-Headers: authorization,content-type"