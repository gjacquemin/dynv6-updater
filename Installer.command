#!/bin/bash
set -euo pipefail

SERVICE='com.dynv6.updater'
TARGET_DIR="$HOME/Library/LaunchAgents"
TARGET="$TARGET_DIR/$SERVICE.plist"
LOG_DIR="$HOME/Library/Logs/dynv6"
DOMAIN="gui/$(id -u)"

read -r -p 'Domaine dynv6 (ex. monsite.dynv6.net) : ' ZONE
ZONE="${ZONE#https://}"
ZONE="${ZONE#http://}"
if [[ -z "$ZONE" || "$ZONE" == *[!a-zA-Z0-9.-]* || "$ZONE" == .* || "$ZONE" == *..* ]]; then
  echo 'Domaine invalide.' >&2; exit 1
fi
read -r -s -p 'Token dynv6 : ' TOKEN
printf '\n'
if [[ -z "$TOKEN" || "$TOKEN" == *$'\n'* ]]; then echo 'Token invalide.' >&2; exit 1; fi

CURL=$(command -v curl) || { echo 'curl introuvable.' >&2; exit 1; }
PYTHON=$(command -v python3) || { echo 'python3 introuvable.' >&2; exit 1; }
mkdir -p "$TARGET_DIR" "$LOG_DIR"
chmod 700 "$LOG_DIR"

# Encodage URL du token et échappement XML de tous les paramètres dynamiques.
XML_URL=$(TOKEN="$TOKEN" ZONE="$ZONE" "$PYTHON" -c '
import os, urllib.parse, html
query = urllib.parse.urlencode({"ipv6": "auto", "zone": os.environ["ZONE"], "token": os.environ["TOKEN"]})
print(html.escape("https://ipv6.dynv6.com/api/update?" + query, quote=True))
')
unset TOKEN
TMP=$(mktemp "$TARGET_DIR/.dynv6.XXXXXXXX")
trap 'rm -f "$TMP"' EXIT
chmod 600 "$TMP"
cat > "$TMP" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>Label</key><string>$SERVICE</string>
<key>ProgramArguments</key><array>
<string>$CURL</string>
<string>--silent</string><string>--show-error</string>
<string>--fail-with-body</string><string>--max-time</string><string>30</string>
<string>--output</string><string>$LOG_DIR/response.log</string>
<string>$XML_URL</string>
</array>
<key>RunAtLoad</key><true/>
<key>StartInterval</key><integer>600</integer>
<key>StandardErrorPath</key><string>$LOG_DIR/error.log</string>
</dict></plist>
PLIST
plutil -lint "$TMP"

# Retire l'ancienne version de ce service, si présente.
launchctl bootout "$DOMAIN" "$TARGET" 2>/dev/null || true
mv -f "$TMP" "$TARGET"
chmod 600 "$TARGET"
# Le PLIST est généré localement ; ne retirer la quarantaine que de ce fichier.
xattr -d com.apple.quarantine "$TARGET" 2>/dev/null || true
launchctl enable "$DOMAIN/$SERVICE"
if launchctl bootstrap "$DOMAIN" "$TARGET"; then
  echo 'Installation réussie : mise à jour à la connexion puis environ toutes les 10 minutes.'
  echo "Logs : $LOG_DIR"
else
  echo 'Échec du chargement. Derniers messages launchd :' >&2
  log show --last 2m --style compact --predicate 'process == "launchd"' 2>/dev/null | grep -i 'dynv6' | tail -15 || true
  exit 1
fi
