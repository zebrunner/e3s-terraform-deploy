#!/bin/bash
set -euxo pipefail

user="ubuntu"

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y install jq unzip curl ca-certificates

# aws cli (used only for diagnostics; Nexus uses the instance role directly)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
./aws/install

# docker
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
usermod -aG docker "$user"

# nexus data dir (container runs as uid 200)
mkdir -p /opt/nexus-data
chown -R 200:200 /opt/nexus-data

docker run -d --restart unless-stopped --name nexus \
  -p 8081:8081 \
  -v /opt/nexus-data:/nexus-data \
  ${nexus_image}

NEXUS="http://localhost:8081"

# wait until Nexus is up (up to ~15 minutes on first boot)
for i in $(seq 1 60); do
  code=$(curl -s -o /dev/null -w "%%{http_code}" "$NEXUS/service/rest/v1/status" || true)
  if [ "$code" = "200" ]; then
    break
  fi
  sleep 15
done

# initial admin password is generated on first start
PASS=$(docker exec nexus cat /nexus-data/admin.password 2>/dev/null || cat /opt/nexus-data/admin.password)

AUTH=(-u "admin:$PASS")
JSONH=(-H "Content-Type: application/json")

# 1) S3 blob store (uses the instance role via the default AWS credential chain)
curl -s "$${AUTH[@]}" "$${JSONH[@]}" -X POST "$NEXUS/service/rest/v1/blobstores/s3" --data-binary @- <<'JSON' || true
{
  "name": "s3",
  "bucketConfiguration": {
    "bucket": {
      "region": "${region}",
      "name": "${nexus_bucket}",
      "prefix": "",
      "expiration": 3
    }
  }
}
JSON

# 2) remove the default maven repositories (they sit on the local 'default' blob store)
curl -s "$${AUTH[@]}" -X DELETE "$NEXUS/service/rest/v1/repositories/maven-public"   || true
curl -s "$${AUTH[@]}" -X DELETE "$NEXUS/service/rest/v1/repositories/maven-releases"  || true
curl -s "$${AUTH[@]}" -X DELETE "$NEXUS/service/rest/v1/repositories/maven-snapshots" || true
curl -s "$${AUTH[@]}" -X DELETE "$NEXUS/service/rest/v1/repositories/maven-central"   || true

# 3) maven proxy that caches Maven Central, stored on the S3 blob store
curl -s "$${AUTH[@]}" "$${JSONH[@]}" -X POST "$NEXUS/service/rest/v1/repositories/maven/proxy" --data-binary @- <<'JSON' || true
{
  "name": "maven-central",
  "online": true,
  "storage": {
    "blobStoreName": "s3",
    "strictContentTypeValidation": false
  },
  "proxy": {
    "remoteUrl": "${maven_remote_url}",
    "contentMaxAge": -1,
    "metadataMaxAge": 1440
  },
  "negativeCache": {
    "enabled": true,
    "timeToLive": 1440
  },
  "httpClient": {
    "blocked": false,
    "autoBlock": true
  },
  "maven": {
    "versionPolicy": "MIXED",
    "layoutPolicy": "PERMISSIVE",
    "contentDisposition": "INLINE"
  }
}
JSON

# 4) group that clients point at
curl -s "$${AUTH[@]}" "$${JSONH[@]}" -X POST "$NEXUS/service/rest/v1/repositories/maven/group" --data-binary @- <<'JSON' || true
{
  "name": "maven-public",
  "online": true,
  "storage": {
    "blobStoreName": "s3",
    "strictContentTypeValidation": false
  },
  "group": {
    "memberNames": ["maven-central"]
  }
}
JSON

# 5) allow anonymous read, so clients need no credentials
curl -s "$${AUTH[@]}" "$${JSONH[@]}" -X PUT "$NEXUS/service/rest/v1/security/anonymous" --data-binary @- <<'JSON' || true
{
  "enabled": true,
  "userId": "anonymous",
  "realmName": "NexusAuthorizingRealm"
}
JSON

# 6) set a fixed admin password when one is provided (empty keeps the generated password)
cat > /tmp/nexus_admin_pass <<'PASS'
${admin_password}
PASS
NEW=$(head -n1 /tmp/nexus_admin_pass)
if [ -n "$NEW" ]; then
  curl -s "$${AUTH[@]}" -H "Content-Type: text/plain" -X PUT "$NEXUS/service/rest/v1/security/users/admin/change-password" -d "$NEW" || true
fi
rm -f /tmp/nexus_admin_pass
