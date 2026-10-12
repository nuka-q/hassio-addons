#!/usr/bin/with-contenv bashio
set -e
bashio::log.debug "Building ngrok.yml..."
configPath="/ngrok-config/ngrok.yml"
mkdir -p /ngrok-config
echo "version: 3" > $configPath
echo "agent:" >> $configPath
echo "  log: stdout" >> $configPath
bashio::log.debug "Web interface port: $(bashio::addon.port 4040)"
if bashio::var.has_value "$(bashio::addon.port 4040)"; then
  echo "  web_addr: 0.0.0.0:$(bashio::addon.port 4040)" >> $configPath
fi
if bashio::var.has_value "$(bashio::config 'log_level')"; then
  echo "  log_level: $(bashio::config 'log_level')" >> $configPath
fi
if bashio::var.has_value "$(bashio::config 'auth_token')"; then
  echo "  authtoken: $(bashio::config 'auth_token')" >> $configPath
fi
# ngrok v3 does not accept the legacy region setting in the agent config.
# If a region is required for a specific deployment, it must be configured through
# a supported ngrok endpoint or account level setting instead.

echo "" >> $configPath
echo "tunnels:" >> $configPath
for id in $(bashio::config "tunnels|keys"); do
  name=$(bashio::config "tunnels[${id}].name")
  echo "  $name:" >> $configPath
  proto=$(bashio::config "tunnels[${id}].proto")
  if [[ $proto != "null" ]]; then
    echo "    proto: $proto" >> $configPath
  fi
  addr=$(bashio::config "tunnels[${id}].addr")
  if [[ $addr != "null" ]]; then
    if [[ $addr =~ ^([1-9]|[1-5]?[0-9]{2,4}|6[1-4][0-9]{3}|65[1-4][0-9]{2}|655[1-2][0-9]|6553[1-5])$ ]]; then
      echo "    addr: 172.30.32.1:$addr" >> $configPath
    else
      echo "    addr: $addr" >> $configPath
    fi
  fi
  inspect=$(bashio::config "tunnels[${id}].inspect")
  if [[ $inspect != "null" ]]; then
    echo "    inspect: $inspect" >> $configPath
  fi
  # ngrok v3 no longer accepts the legacy basic-auth tunnel field.
  # The add-on still retains the value in the HA config, but it is intentionally
  # omitted here to keep the config compatible with the current ngrok agent.
  host_header=$(bashio::config "tunnels[${id}].host_header")
  if [[ $host_header != "null" ]]; then
    echo "    host_header: $host_header" >> $configPath
  fi
  bind_tls=$(bashio::config "tunnels[${id}].bind_tls")
  if [[ $bind_tls != "null" ]]; then
    echo "    bind_tls: $bind_tls" >> $configPath
  fi
  subdomain=$(bashio::config "tunnels[${id}].subdomain")
  if [[ $subdomain != "null" ]]; then
    echo "    subdomain: $subdomain" >> $configPath
  fi
  hostname=$(bashio::config "tunnels[${id}].hostname")
  if [[ $hostname != "null" ]]; then
    echo "    hostname: $hostname" >> $configPath
  fi
  crt=$(bashio::config "tunnels[${id}].crt")
  if [[ $crt != "null" ]]; then
    echo "    crt: $crt" >> $configPath
  fi
  key=$(bashio::config "tunnels[${id}].key")
  if [[ $key != "null" ]]; then
    echo "    key: $key" >> $configPath
  fi
  client_cas=$(bashio::config "tunnels[${id}].client_cas")
  if [[ $client_cas != "null" ]]; then
    echo "    client_cas: $client_cas" >> $configPath
  fi
  remote_addr=$(bashio::config "tunnels[${id}].remote_addr")
  if [[ $remote_addr != "null" ]]; then
    echo "    remote_addr: $remote_addr" >> $configPath
  fi
  metadata=$(bashio::config "tunnels[${id}].metadata")
  if [[ $metadata != "null" ]]; then
    echo "    metadata: $metadata" >> $configPath
  fi
done
configfile=$(cat $configPath)
bashio::log.debug "Config file: \n${configfile}"
bashio::log.info "Starting ngrok..."
ngrok start --config $configPath --all
