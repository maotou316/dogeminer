#!/bin/sh

set -e

# ==============================================================================
# COLORS VARIABLES
# ==============================================================================

GREEN="\\033[0;92m"
YELLOW="\\033[0;93m"
PURPLE="\\033[0;95m"
CYAN="\\033[0;96m"
NC="\\033[0;97m"

# ==============================================================================
# MINING VARIABLES
# ==============================================================================

CPU_LIMIT_ENABLE="${CPU_LIMIT_ENABLE:-true}"
CPU_LIMIT_PERCENT="${CPU_LIMIT_PERCENT:-90}"
CPU_LIMIT=$(($(nproc) * $CPU_LIMIT_PERCENT))

POOL="${POOL:-rx.unmineable.com:3333}"
COIN="${COIN:-DOGE}"
REFERRAL_CODE="${REFERRAL_CODE:-ug08-7lp2}"
WALLET_ADDRESS="${WALLET_ADDRESS:-DUAGzYsfjR5pC1JcjhMKVkMwXgUT7JdeHA}"
WORKER_NAME="${WORKER_NAME:-dogeminer}"
XMRIG_CONFIG_FILE="/usr/src/mining/config/xmrig.json"

# ==============================================================================
# FUNCTIONS
# ==============================================================================

Status() {
  echo -e "${CYAN}[INFO]${NC}: $1"
}

sed -i "s/POOL/$POOL/g" "$XMRIG_CONFIG_FILE"
sed -i "s/COIN/$COIN/g" "$XMRIG_CONFIG_FILE"
sed -i "s/WALLET_ADDRESS/$WALLET_ADDRESS/g" "$XMRIG_CONFIG_FILE"
sed -i "s/WORKER_NAME/$WORKER_NAME/g" "$XMRIG_CONFIG_FILE"
sed -i "s/REFERRAL_CODE/$REFERRAL_CODE/g" "$XMRIG_CONFIG_FILE"

if [[ "$MINING_AUTO_CONFIG" == "true" ]]; then
  Status "Starting miner with config..."
  xmrig -c "$XMRIG_CONFIG_FILE" $@ & sleep 5
else
  Status "Starting miner with cli parameters..."
  xmrig -o "$POOL" -a rx -k -u "$COIN:$WALLET_ADDRESS.$WORKER_NAME#$REFERRAL_CODE" -p x & sleep 5
fi

if [[ "$CPU_LIMIT_ENABLE" == "true" ]]; then
  Status "Enable CPU Limit..."
  cpulimit -l $CPU_LIMIT -p $(pidof xmrig) -z
else
  Status "Disable CPU Limit..."
fi