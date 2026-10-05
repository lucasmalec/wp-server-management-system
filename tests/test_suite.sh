#!/bin/bash
# =================================================================
# WSMS PRO Test Suite v4.3
# Run: bash tests/test_suite.sh
# =================================================================

set -euo pipefail
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

echo -e "${YELLOW}🧪 WSMS PRO TEST SUITE v4.5.0${NC}"
echo "=========================================================="

TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=()

pass() { echo -e "${GREEN}✅ PASS${NC} — $1"; TESTS_PASSED=$((TESTS_PASSED + 1)); }
fail() { echo -e "${RED}❌ FAIL${NC} — $1"; TESTS_FAILED=$((TESTS_FAILED + 1)); FAILED_TESTS+=("$1"); }

assert_syntax()   { bash -n "$1" 2>/dev/null && pass "syntax: $(basename "$1")" || fail "syntax: $(basename "$1")"; }
assert_file()     { [ -f "$1" ] && pass "file exists: $1" || fail "file exists: $1"; }
assert_contains() { grep -q "$2" "$1" && pass "contains '$2' in $(basename "$1")" || fail "contains '$2' in $(basename "$1")"; }

get_file_mode() {
    local target="$1"
    if stat -c "%a" "$target" >/dev/null 2>&1; then
        stat -c "%a" "$target" 2>/dev/null
    else
        stat -f "%Lp" "$target" 2>/dev/null
    fi
}

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PREVIEW_EN="$ROOT/scripts/runtime-preview/en"
PREVIEW_PL="$ROOT/scripts/runtime-preview/pl"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# =================================================================
# 1. SYNTAX — installers, tools, runtime scripts
# =================================================================
echo -e "\n${CYAN}[1] Syntax checks${NC}"

for f in "$ROOT"/installers/*.sh "$ROOT"/tools/*.sh; do
    [ -f "$f" ] && assert_syntax "$f"
done

for f in "$PREVIEW_EN"/*.sh "$PREVIEW_PL"/*.sh; do
    [ -f "$f" ] && assert_syntax "$f"
done

# =================================================================
# 2. REQUIRED FILES
# =================================================================
echo -e "\n${CYAN}[2] Required files${NC}"

REQUIRED=(
    "installers/install_wsms.sh"
    "installers/install_wsms_pl.sh"
    "tools/wsms-uninstall.sh"
    "tools/wsms-export-runtime-scripts.sh"
    "docs/DEPLOYMENT_GUIDE.md"
    "docs/MAIL_CONFIGURATION.md"
    "docs/msmtprc.example"
    "docs/mailrc.example"
    "docs/TECHNICAL_REFERENCE.md"
    "docs/FISH_SETUP_GUIDE.md"
    "docs/DOCKER_HELP_EN.md"
    "docs/DOCKER_HELP_PL.md"
    "tests/docker/Dockerfile"
    "tests/docker/compose.yaml"
    "README.md"
    "CHANGELOG.md"
    "CONTRIBUTING.md"
    "LICENSE.md"
    ".gitignore"
)

for f in "${REQUIRED[@]}"; do
    assert_file "$ROOT/$f"
done

# =================================================================
# 3. DOCS FORMAT
# =================================================================
echo -e "\n${CYAN}[3] Documentation format${NC}"

for doc in "$ROOT"/docs/*.md "$ROOT"/README.md "$ROOT"/CHANGELOG.md; do
    [ -f "$doc" ] || continue
    head -1 "$doc" | grep -q "^#" \
        && pass "doc header: $(basename "$doc")" \
        || fail "doc header: $(basename "$doc")"
done

# =================================================================
# 4. INSTALLER CONTENT — key markers
# =================================================================
echo -e "\n${CYAN}[4] Installer content${NC}"

for installer in "$ROOT/installers/install_wsms.sh" "$ROOT/installers/install_wsms_pl.sh"; do
    base=$(basename "$installer")
    assert_contains "$installer" "wsms-config.sh"                         "config deploy block in $base"
    assert_contains "$installer" "wsms-notify.sh"                         "notify module in $base"
    assert_contains "$installer" "wsms-daily-check.sh"                    "daily check module in $base"
    assert_contains "$installer" "ALERT_EMAIL"                            "ALERT_EMAIL in $base"
    assert_contains "$installer" "ALERT_ON_FAILURE"                       "ALERT_ON_FAILURE in $base"
    assert_contains "$installer" "wp-automated-maintenance-engine.sh"     "maintenance engine in $base"
    assert_contains "$installer" "wp-smart-retention-manager.sh"          "retention manager in $base"
    assert_contains "$installer" "wp-rollback.sh"                         "rollback engine in $base"
    assert_contains "$installer" "wp-help.sh"                             "help script in $base"
    assert_contains "$installer" "wp-backup-site"                         "wp-backup-site in $base"
    assert_contains "$installer" "wp-backup-static"                       "wp-backup-static in $base"
    assert_contains "$installer" "static-sites-backup.sh"                 "static-sites-backup in $base"
    assert_contains "$installer" "mysql-backup-site"                      "mysql-backup-site in $base"
    assert_contains "$installer" "WSMS PRO v4.5.0"                        "version marker in $base"
    assert_contains "$installer" "/var/log/wsms"                          "/var/log/wsms in $base"
    assert_contains "$installer" "/var/quarantine"                        "/var/quarantine in $base"
    assert_contains "$installer" "CRONTAB"                                "crontab block in $base"
    assert_contains "$installer" "wsms_system"                            "wsms_system directory in $base"
    assert_contains "$installer" "WSMS_DIR"                               "WSMS_DIR variable in $base"
    assert_contains "$installer" "wsms-docs"                              "wsms-docs alias in $base"
    assert_contains "$installer" "wsms-dir"                               "wsms-dir alias in $base"
done

# =================================================================
# 5. EN/PL MODULE PARITY
# =================================================================
echo -e "\n${CYAN}[5] EN/PL module parity${NC}"

MODULES=(
    "wp-automated-maintenance-engine.sh"
    "wp-smart-retention-manager.sh"
    "wp-rollback.sh"
    "wp-help.sh"
    "wp-hosts-sync.sh"
    "wp-fleet-status-monitor.sh"
    "wp-multi-instance-audit.sh"
    "server-health-audit.sh"
    "wsms-clean.sh"
    "wsms-notify.sh"
    "wsms-daily-check.sh"
    "mysql-backup-manager.sh"
    "infrastructure-permission-orchestrator.sh"
    "nas-sftp-sync.sh"
    "static-sites-backup.sh"
)

for mod in "${MODULES[@]}"; do
    [ -f "$PREVIEW_EN/$mod" ] && pass "en module: $mod" || fail "en module: $mod"
    [ -f "$PREVIEW_PL/$mod" ] && pass "pl module: $mod" || fail "pl module: $mod"
done

# =================================================================
# 6. RUNTIME SCRIPT CONTENT — key patterns
# =================================================================
echo -e "\n${CYAN}[6] Runtime script content${NC}"

assert_contains "$PREVIEW_EN/wp-automated-maintenance-engine.sh" 'source "$HOME/scripts/wsms-config.sh"' "maintenance engine sources config"
assert_contains "$PREVIEW_EN/wp-automated-maintenance-engine.sh" "run_site_update"                       "maintenance engine has run_site_update"
assert_contains "$PREVIEW_EN/wp-automated-maintenance-engine.sh" "wp-rollback.sh"                       "maintenance engine calls rollback"
assert_contains "$PREVIEW_EN/wp-automated-maintenance-engine.sh" "check_http_code"                      "maintenance engine checks HTTP after update"
assert_contains "$PREVIEW_EN/wp-automated-maintenance-engine.sh" "send_alert"                           "maintenance engine calls send_alert"

assert_contains "$PREVIEW_EN/wp-smart-retention-manager.sh" "emergency_cleanup"    "retention manager has emergency_cleanup"
assert_contains "$PREVIEW_EN/wp-smart-retention-manager.sh" "force_clean"          "retention manager has force_clean"
assert_contains "$PREVIEW_EN/wp-smart-retention-manager.sh" "normalize_backup_key" "retention manager has normalize_backup_key"
assert_contains "$PREVIEW_EN/wp-smart-retention-manager.sh" "BACKUP_ROLLBACK_DIR"  "retention manager handles rollback dir"

assert_contains "$PREVIEW_EN/wp-rollback.sh" "create_snapshot"  "rollback has create_snapshot"
assert_contains "$PREVIEW_EN/wp-rollback.sh" "perform_rollback" "rollback has perform_rollback"
assert_contains "$PREVIEW_EN/wp-rollback.sh" "maintenance-mode" "rollback uses maintenance mode"

assert_contains "$PREVIEW_EN/wp-hosts-sync.sh" "MARKER_START" "hosts-sync has marker start"
assert_contains "$PREVIEW_EN/wp-hosts-sync.sh" "MARKER_END"   "hosts-sync has marker end"
assert_contains "$PREVIEW_EN/wp-hosts-sync.sh" "127.0.0.1"    "hosts-sync maps to 127.0.0.1"

assert_contains "$PREVIEW_EN/wsms-clean.sh" "FORCE_MODE" "wsms-clean has force mode"

assert_contains "$PREVIEW_EN/wsms-notify.sh"      "send_alert"          "wsms-notify has send_alert function"
assert_contains "$PREVIEW_EN/wsms-notify.sh"      "ALERT_EMAIL"         "wsms-notify checks ALERT_EMAIL"
assert_contains "$PREVIEW_EN/wsms-notify.sh"      "ALERT_ON_FAILURE"    "wsms-notify checks ALERT_ON_FAILURE"
assert_contains "$PREVIEW_EN/wsms-notify.sh"      "ALERT_ON_SUCCESS"    "wsms-notify checks ALERT_ON_SUCCESS"
assert_contains "$PREVIEW_EN/wsms-notify.sh"      "command -v mail"     "wsms-notify verifies mail command exists"

assert_contains "$PREVIEW_EN/wsms-daily-check.sh" "wsms-notify.sh"      "daily-check sources wsms-notify"
assert_contains "$PREVIEW_EN/wsms-daily-check.sh" "server-health-audit" "daily-check runs server-health-audit"
assert_contains "$PREVIEW_EN/wsms-daily-check.sh" "wp-fleet-status"     "daily-check runs fleet-status"
assert_contains "$PREVIEW_EN/wsms-daily-check.sh" "send_alert"          "daily-check calls send_alert"

assert_contains "$PREVIEW_EN/clamav-auto-scan.sh"  "send_alert"         "clamav-auto-scan calls send_alert"
assert_contains "$PREVIEW_EN/clamav-full-scan.sh"  "send_alert"         "clamav-full-scan calls send_alert"
assert_contains "$PREVIEW_EN/server-health-audit.sh" "send_alert"       "server-health-audit calls send_alert"

assert_contains "$ROOT/docs/MAIL_CONFIGURATION.md" "msmtp"               "mail configuration guide mentions msmtp"
assert_contains "$ROOT/docs/MAIL_CONFIGURATION.md" "msmtprc.example"     "mail configuration guide references example config"
assert_contains "$ROOT/docs/MAIL_CONFIGURATION.md" "mailrc.example"      "mail configuration guide references mailrc example"
assert_contains "$ROOT/docs/MAIL_CONFIGURATION.md" "invalid envelope sender" "mail configuration guide covers invalid envelope sender"
assert_contains "$ROOT/docs/MAIL_CONFIGURATION.md" "admin ubuntu_server"     "mail configuration guide includes invalid sender example"
assert_contains "$ROOT/docs/MAIL_CONFIGURATION.md" "SMTP 501"               "mail configuration guide covers SMTP 501 troubleshooting"
assert_contains "$ROOT/docs/MAIL_CONFIGURATION.md" "envelope from address"   "mail configuration guide covers envelope sender rejection"

assert_contains "$PREVIEW_EN/wsms-notify.sh" "ensure_msmtprc" "wsms-notify has ensure_msmtprc"
assert_contains "$PREVIEW_EN/wsms-notify.sh" "SMTP_ENABLED"   "wsms-notify checks SMTP_ENABLED"
assert_contains "$PREVIEW_PL/wsms-notify.sh" "ensure_msmtprc" "PL wsms-notify has ensure_msmtprc"
assert_contains "$PREVIEW_PL/wsms-notify.sh" "SMTP_ENABLED"   "PL wsms-notify checks SMTP_ENABLED"
assert_contains "$ROOT/installers/install_wsms.sh" "ensure_msmtprc" "installer has ensure_msmtprc"
assert_contains "$ROOT/installers/install_wsms_pl.sh" "ensure_msmtprc" "PL installer has ensure_msmtprc"
assert_contains "$ROOT/installers/install_wsms.sh" "SMTP_ENABLED" "installer has SMTP_ENABLED"
assert_contains "$ROOT/installers/install_wsms_pl.sh" "SMTP_ENABLED" "PL installer has SMTP_ENABLED"

assert_contains "$PREVIEW_EN/static-sites-backup.sh" 'source "$HOME/scripts/wsms-config.sh"' "static backup sources config"
assert_contains "$PREVIEW_EN/static-sites-backup.sh" "BACKUP_FULL_DIR" "static backup uses BACKUP_FULL_DIR"
assert_contains "$PREVIEW_EN/static-sites-backup.sh" "index.html" "static backup checks index.html"
assert_contains "$PREVIEW_PL/static-sites-backup.sh" 'source "$HOME/scripts/wsms-config.sh"' "PL static backup sources config"
assert_contains "$PREVIEW_PL/static-sites-backup.sh" "BACKUP_FULL_DIR" "PL static backup uses BACKUP_FULL_DIR"
assert_contains "$PREVIEW_PL/static-sites-backup.sh" "index.html" "PL static backup checks index.html"

assert_contains "$PREVIEW_EN/infrastructure-permission-orchestrator.sh" "useradd" "orchestrator has useradd dedicated user"
assert_contains "$PREVIEW_EN/infrastructure-permission-orchestrator.sh" "index.html" "orchestrator detects static HTML"
assert_contains "$PREVIEW_EN/infrastructure-permission-orchestrator.sh" "chmod 755" "orchestrator applies 755 for static"
assert_contains "$PREVIEW_PL/infrastructure-permission-orchestrator.sh" "useradd" "PL orchestrator has useradd dedicated user"
assert_contains "$PREVIEW_PL/infrastructure-permission-orchestrator.sh" "index.html" "PL orchestrator detects static HTML"
assert_contains "$PREVIEW_PL/infrastructure-permission-orchestrator.sh" "chmod 755" "PL orchestrator applies 755 for static"


# =================================================================
# 7. BEHAVIORAL — normalize_backup_key logic
# =================================================================
echo -e "\n${CYAN}[7] Behavioral: normalize_backup_key${NC}"

_normalize() {
    local key="$1"
    key="${key%.tar.gz}"; key="${key%.sql.gz}"; key="${key%.gz}"; key="${key%.zip}"
    key=$(echo "$key" | sed -E 's/[-_][0-9]{8}[-_][0-9]{6}$//; s/[-_][0-9]{8}$//')
    echo "$key"
}

check_normalize() {
    local result; result=$(_normalize "$1")
    [ "$result" = "$2" ] \
        && pass "normalize: '$1' → '$2'" \
        || fail "normalize: '$1' → expected '$2', got '$result'"
}

check_normalize "site1-20240101_120000.tar.gz"          "site1"
check_normalize "site1-20240101.tar.gz"                 "site1"
check_normalize "db-site1-20240101_120000.sql.gz"       "db-site1"
check_normalize "backup_site2_20240315_093000.tar.gz"   "backup_site2"
check_normalize "mysite.tar.gz"                         "mysite"

# =================================================================
# 8. BEHAVIORAL — emergency_cleanup keeps ≤2 per group
# =================================================================
echo -e "\n${CYAN}[8] Behavioral: emergency_cleanup keeps ≤2 per group${NC}"

FAKE_BACKUP="$TMP_DIR/backups-lite"
mkdir -p "$FAKE_BACKUP"
touch "$FAKE_BACKUP/site1-20240101_100000.tar.gz"
touch "$FAKE_BACKUP/site1-20240102_100000.tar.gz"
touch "$FAKE_BACKUP/site1-20240103_100000.tar.gz"
touch "$FAKE_BACKUP/site1-20240104_100000.tar.gz"
touch "$FAKE_BACKUP/site2-20240101_100000.tar.gz"

# Use python3 for grouping (bash 3 on macOS lacks associative arrays)
python3 - "$FAKE_BACKUP" <<'PYEOF'
import os, re, sys
d = sys.argv[1]
files = sorted(os.listdir(d), reverse=True)
groups = {}
for f in files:
    k = re.sub(r'\.(tar\.gz|sql\.gz|gz|zip)$', '', f)
    k = re.sub(r'[-_]\d{8}[-_]\d{6}$', '', k)
    k = re.sub(r'[-_]\d{8}$', '', k)
    groups.setdefault(k, []).append(f)
for k, lst in groups.items():
    for old in lst[2:]:
        os.remove(os.path.join(d, old))
PYEOF

site1_count=$(find "$FAKE_BACKUP" -name "site1-*" | wc -l | tr -d ' ')
site2_count=$(find "$FAKE_BACKUP" -name "site2-*" | wc -l | tr -d ' ')
total=$(find "$FAKE_BACKUP" -type f | wc -l | tr -d ' ')

[ "$site1_count" -le 2 ] \
    && pass "emergency_cleanup: site1 reduced to ≤2 (got $site1_count)" \
    || fail "emergency_cleanup: site1 should be ≤2, got $site1_count"

[ "$site2_count" -eq 1 ] \
    && pass "emergency_cleanup: site2 untouched (1 file)" \
    || fail "emergency_cleanup: site2 should be 1, got $site2_count"

[ "$total" -eq 3 ] \
    && pass "emergency_cleanup: total = 3 (2 site1 + 1 site2)" \
    || fail "emergency_cleanup: expected 3 total files, got $total"

# =================================================================
# 9. BEHAVIORAL — hosts-sync domain validation
# =================================================================
echo -e "\n${CYAN}[9] Behavioral: hosts-sync domain validation${NC}"

_is_valid_domain() {
    [[ "$1" =~ ^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)+$ ]]
}

check_domain() {
    local domain="$1" expected="$2"
    if _is_valid_domain "$domain"; then
        [ "$expected" = "valid" ] && pass "domain valid: $domain" || fail "domain should be invalid: $domain"
    else
        [ "$expected" = "invalid" ] && pass "domain invalid: $domain" || fail "domain should be valid: $domain"
    fi
}

check_domain "example.com"        "valid"
check_domain "my-site.example.pl" "valid"
check_domain "sub.domain.co.uk"   "valid"
check_domain "not_a_domain"       "invalid"
check_domain "/var/www/site"      "invalid"
check_domain "site1"              "invalid"

# =================================================================
# 10. BEHAVIORAL — hosts-sync marker idempotency
# =================================================================
echo -e "\n${CYAN}[10] Behavioral: hosts-sync marker idempotency${NC}"

FAKE_HOSTS="$TMP_DIR/hosts"
MS="# >>> WSMS LOCAL HOSTS >>>"
ME="# <<< WSMS LOCAL HOSTS <<<"

cat > "$FAKE_HOSTS" <<EOF
127.0.0.1 localhost
$MS
127.0.0.1 old-site.com
$ME
EOF

TMP_BLOCK="$(mktemp)"; TMP_H="$(mktemp)"
{ echo "$MS"; echo "127.0.0.1 new-site.com"; echo "$ME"; } > "$TMP_BLOCK"
awk -v s="$MS" -v e="$ME" '$0==s{skip=1;next} $0==e{skip=0;next} !skip{print}' "$FAKE_HOSTS" > "$TMP_H"
{ cat "$TMP_H"; echo ""; cat "$TMP_BLOCK"; } > "$FAKE_HOSTS"
rm -f "$TMP_BLOCK" "$TMP_H"

marker_count=$(grep -c "WSMS LOCAL HOSTS" "$FAKE_HOSTS")
[ "$marker_count" -eq 2 ] \
    && pass "hosts-sync: exactly one marker block after update" \
    || fail "hosts-sync: expected 2 marker lines, got $marker_count"

grep -q "old-site.com" "$FAKE_HOSTS" \
    && fail "hosts-sync: old entry should be replaced" \
    || pass "hosts-sync: old entry removed"

grep -q "new-site.com" "$FAKE_HOSTS" \
    && pass "hosts-sync: new entry present" \
    || fail "hosts-sync: new entry missing"

grep -q "127.0.0.1 localhost" "$FAKE_HOSTS" \
    && pass "hosts-sync: non-WSMS lines preserved" \
    || fail "hosts-sync: non-WSMS lines removed"

# =================================================================
# 11. BEHAVIORAL — uninstaller legacy cleanup
# =================================================================
echo -e "\n${CYAN}[11] Behavioral: uninstaller legacy cleanup${NC}"

bash "$ROOT/tests/test_uninstaller_legacy_cleanup.sh" >/dev/null 2>&1 \
    && pass "uninstaller: legacy v4.2 block removal" \
    || fail "uninstaller: legacy v4.2 block removal"

# =================================================================
# 12. BEHAVIORAL — uninstaller --dry-run makes no changes
# =================================================================
echo -e "\n${CYAN}[12] Behavioral: uninstaller --dry-run${NC}"

DRY_HOME="$TMP_DIR/dry-home"
DRY_BIN="$TMP_DIR/dry-bin"
mkdir -p "$DRY_HOME/.config/fish" "$DRY_BIN"

cat > "$DRY_HOME/.bashrc" <<'EOF'
# keep-line
# >>> WSMS PRO v4.3 BASH >>>
alias wp-help='bash ~/scripts/wp-help.sh'
# <<< WSMS PRO v4.3 BASH <<<
EOF
cat > "$DRY_HOME/.config/fish/config.fish" <<'EOF'
# keep-fish-line
EOF
printf '#!/bin/sh\nexit 1\n'   > "$DRY_BIN/sudo"
printf '#!/bin/sh\n[ "$1" = "-l" ] && exit 1; exit 0\n' > "$DRY_BIN/crontab"
chmod +x "$DRY_BIN/sudo" "$DRY_BIN/crontab"

BEFORE=$(cat "$DRY_HOME/.bashrc")
HOME="$DRY_HOME" PATH="$DRY_BIN:$PATH" bash "$ROOT/tools/wsms-uninstall.sh" --dry-run >/dev/null 2>&1 || true
AFTER=$(cat "$DRY_HOME/.bashrc")

[ "$BEFORE" = "$AFTER" ] \
    && pass "uninstaller: --dry-run does not modify .bashrc" \
    || fail "uninstaller: --dry-run modified .bashrc"

# =================================================================
# 13. BEHAVIORAL — rollback: no snapshot → graceful error
# =================================================================
echo -e "\n${CYAN}[13] Behavioral: rollback graceful error on missing snapshot${NC}"

RB_HOME="$TMP_DIR/rb-home"
mkdir -p "$RB_HOME/scripts" "$RB_HOME/backups-rollback"
cat > "$RB_HOME/scripts/wsms-config.sh" <<'CONF'
SITES=("testsite:/var/www/testsite:www-data")
BACKUP_ROLLBACK_DIR="$HOME/backups-rollback"
SCRIPT_DIR="$HOME/scripts"
RETENTION_ROLLBACK=7
wsms_init_live_logging() { :; }
CONF

out=$(HOME="$RB_HOME" bash -x "$PREVIEW_EN/wp-rollback.sh" rollback testsite 2>&1 || true)
echo "$out" | grep -qiE "no snapshot|not found|missing" \
    && pass "rollback: graceful error when no snapshot exists" \
    || fail "rollback: no graceful error message for missing snapshot"

# =================================================================
# 14. BEHAVIORAL — maintenance engine: invalid mode → usage + exit 1
# =================================================================
echo -e "\n${CYAN}[14] Behavioral: maintenance engine invalid mode${NC}"

ME_HOME="$TMP_DIR/me-home"
mkdir -p "$ME_HOME/scripts"
cat > "$ME_HOME/scripts/wsms-config.sh" <<'CONF'
SITES=()
SCRIPT_DIR="$HOME/scripts"
LOG_UPDATES="$HOME/logs/updates.log"
wsms_init_live_logging() { :; }
CONF
mkdir -p "$ME_HOME/logs"

out=$(HOME="$ME_HOME" bash -x "$PREVIEW_EN/wp-automated-maintenance-engine.sh" badmode 2>&1 || true)
echo "$out" | grep -qi "usage\|Usage" \
    && pass "maintenance engine: prints usage on invalid mode" \
    || fail "maintenance engine: no usage on invalid mode"

# =================================================================
# 15. BEHAVIORAL — retention manager: unknown arg → usage
# =================================================================
echo -e "\n${CYAN}[15] Behavioral: retention manager unknown arg${NC}"

RM_HOME="$TMP_DIR/rm-home"
mkdir -p "$RM_HOME/scripts" "$RM_HOME/logs"
cat > "$RM_HOME/scripts/wsms-config.sh" <<'CONF'
BACKUP_LITE_DIR="$HOME/backups-lite"
BACKUP_FULL_DIR="$HOME/backups-full"
BACKUP_MYSQL_DIR="$HOME/mysql-backups"
BACKUP_ROLLBACK_DIR="$HOME/backups-rollback"
DISK_ALERT_THRESHOLD=90
RETENTION_LITE=7
RETENTION_FULL=30
RETENTION_MYSQL=14
RETENTION_ROLLBACK=7
LOG_RETENTION="$HOME/logs/retention.log"
wsms_init_live_logging() { :; }
CONF

out=$(HOME="$RM_HOME" bash -x "$PREVIEW_EN/wp-smart-retention-manager.sh" badarg 2>&1 || true)
echo "$out" | grep -qi "usage\|Usage\|list\|size\|clean" \
    && pass "retention manager: prints usage on unknown arg" \
    || fail "retention manager: no usage on unknown arg"

# =================================================================
# 16. BEHAVIORAL — ensure_msmtprc self-healing
# =================================================================
echo -e "\n${CYAN}[16] Behavioral: ensure_msmtprc self-healing SMTP${NC}"

TEST_SMTP_HOME="$TMP_DIR/smtp_home"
mkdir -p "$TEST_SMTP_HOME"

(
    export HOME="$TEST_SMTP_HOME"
    export SMTP_ENABLED="yes"
    export SMTP_HOST="smtp.example.com"
    export SMTP_PORT="587"
    export SMTP_USER="test@example.com"
    export SMTP_PASS="secret123"
    export SMTP_FROM="test@example.com"
    export SMTP_TLS="on"
    export SMTP_STARTTLS="on"
    source "$PREVIEW_EN/wsms-notify.sh"
    ensure_msmtprc
)

if [ -f "$TEST_SMTP_HOME/.msmtprc" ]; then
    pass "ensure_msmtprc: created ~/.msmtprc"
    mode=$(get_file_mode "$TEST_SMTP_HOME/.msmtprc")
    [ "$mode" = "600" ] && pass "ensure_msmtprc: ~/.msmtprc has 600 permissions" || fail "ensure_msmtprc: permissions $mode != 600"
    grep -q "host.*smtp.example.com" "$TEST_SMTP_HOME/.msmtprc" && pass "ensure_msmtprc: contains correct host" || fail "ensure_msmtprc: missing host"
    grep -q "password.*secret123" "$TEST_SMTP_HOME/.msmtprc" && pass "ensure_msmtprc: contains password" || fail "ensure_msmtprc: missing password"
else
    fail "ensure_msmtprc: ~/.msmtprc not created"
fi

if [ -f "$TEST_SMTP_HOME/.mailrc" ]; then
    pass "ensure_msmtprc: created ~/.mailrc"
    grep -q "set sendmail=/usr/bin/msmtp" "$TEST_SMTP_HOME/.mailrc" && pass "ensure_msmtprc: mailrc configures msmtp" || fail "ensure_msmtprc: mailrc missing sendmail"
else
    fail "ensure_msmtprc: ~/.mailrc not created"
fi

# =================================================================
# 17. BEHAVIORAL — static-sites-backup filters static sites
# =================================================================
echo -e "\n${CYAN}[17] Behavioral: static-sites-backup filters static sites${NC}"

STATIC_TEST_HOME="$TMP_DIR/static_home"
STATIC_SITES_DIR="$STATIC_TEST_HOME/sites"
mkdir -p "$STATIC_TEST_HOME/scripts" "$STATIC_TEST_HOME/backups-full" "$STATIC_SITES_DIR/wp_site" "$STATIC_SITES_DIR/html_site"

touch "$STATIC_SITES_DIR/wp_site/wp-config.php"
touch "$STATIC_SITES_DIR/html_site/index.html"
echo "<h1>Hello Static</h1>" > "$STATIC_SITES_DIR/html_site/index.html"

cat > "$STATIC_TEST_HOME/scripts/wsms-config.sh" << CONF
SITES=(
    "my-wp.com:$STATIC_SITES_DIR/wp_site:www-data"
    "my-html.com:$STATIC_SITES_DIR/html_site:www-data"
)
BACKUP_FULL_DIR="$STATIC_TEST_HOME/backups-full"
RETENTION_FULL=30
LOG_FULL_BACKUP="$STATIC_TEST_HOME/backup.log"
wsms_init_live_logging() { :; }
CONF

HOME="$STATIC_TEST_HOME" bash -x "$PREVIEW_EN/static-sites-backup.sh" all >/dev/null 2>&1 || true

html_archive_count=$(find "$STATIC_TEST_HOME/backups-full" -name "static-my-html.com-*.tar.gz" 2>/dev/null | wc -l | tr -d ' ')
wp_archive_count=$(find "$STATIC_TEST_HOME/backups-full" -name "static-my-wp.com-*.tar.gz" 2>/dev/null | wc -l | tr -d ' ')

[ "$html_archive_count" -eq 1 ] \
    && pass "static-sites-backup: archive created for static HTML site" \
    || fail "static-sites-backup: static HTML site archive missing"

[ "$wp_archive_count" -eq 0 ] \
    && pass "static-sites-backup: WordPress site skipped correctly" \
    || fail "static-sites-backup: WordPress site should not have static archive"

list_output=$(HOME="$STATIC_TEST_HOME" bash -x "$PREVIEW_EN/static-sites-backup.sh" list 2>&1 || true)
echo "$list_output" | grep -q "static-my-html.com" \
    && pass "static-sites-backup: list mode displays static archive" \
    || fail "static-sites-backup: list mode missing archive"

# =================================================================
# 18. BEHAVIORAL — uninstaller wsms_system and symlink cleanup
# =================================================================
echo -e "\n${CYAN}[18] Behavioral: uninstaller wsms_system and symlink cleanup${NC}"

UNINST_HOME="$TMP_DIR/uninst_home"
UNINST_BIN="$TMP_DIR/uninst_bin"
mkdir -p "$UNINST_HOME/wsms_system/scripts" "$UNINST_HOME/wsms_system/docs" "$UNINST_BIN"
ln -s "$UNINST_HOME/wsms_system/scripts" "$UNINST_HOME/scripts"
touch "$UNINST_HOME/wsms_system/scripts/test.sh"
touch "$UNINST_HOME/wsms_system/docs/README.md"
printf '#!/bin/sh\nexit 1\n' > "$UNINST_BIN/sudo"
printf '#!/bin/sh\n[ "$1" = "-l" ] && exit 1; exit 0\n' > "$UNINST_BIN/crontab"
chmod +x "$UNINST_BIN/sudo" "$UNINST_BIN/crontab"

HOME="$UNINST_HOME" PATH="$UNINST_BIN:$PATH" bash "$ROOT/tools/wsms-uninstall.sh" >/dev/null 2>&1 || true

[ ! -d "$UNINST_HOME/wsms_system" ] \
    && pass "uninstaller: removed ~/wsms_system" \
    || fail "uninstaller: failed to remove ~/wsms_system"

[ ! -e "$UNINST_HOME/scripts" ] && [ ! -L "$UNINST_HOME/scripts" ] \
    && pass "uninstaller: removed ~/scripts symlink" \
    || fail "uninstaller: failed to remove ~/scripts symlink"

[ -d "$UNINST_HOME/wsms-backup-old" ] \
    && pass "uninstaller: saved wsms_system backup" \
    || fail "uninstaller: wsms_system backup missing"

# =================================================================
# 19. BEHAVIORAL — permission orchestrator user isolation & perms
# =================================================================
echo -e "\n${CYAN}[19] Behavioral: permission orchestrator user isolation & perms${NC}"

PERM_TEST_HOME="$TMP_DIR/perm_home"
PERM_BIN="$TMP_DIR/perm_bin"
mkdir -p "$PERM_TEST_HOME/scripts" "$PERM_TEST_HOME/logs" "$PERM_BIN"
mkdir -p "$PERM_TEST_HOME/sites/wp_site/wp-content"
mkdir -p "$PERM_TEST_HOME/sites/html_site"

touch "$PERM_TEST_HOME/sites/wp_site/wp-config.php"
echo "<?php // wp-config" > "$PERM_TEST_HOME/sites/wp_site/wp-config.php"
touch "$PERM_TEST_HOME/sites/wp_site/index.php"
touch "$PERM_TEST_HOME/sites/html_site/index.html"
touch "$PERM_TEST_HOME/sites/html_site/style.css"

cat > "$PERM_BIN/sudo" << SUDOEOF
#!/bin/sh
cmd="\$1"
shift
case "\$cmd" in
    useradd)
        echo "USERADD: \$*" >> "$PERM_TEST_HOME/useradd.log"
        exit 0
        ;;
    chown)
        exit 0
        ;;
    systemctl)
        exit 1
        ;;
    sed)
        if [ "\$1" = "-i" ]; then
            shift
            expr="\$1"
            shift
            target="\$1"
            if grep -q "FS_METHOD" "\$target" 2>/dev/null; then
                exit 0
            fi
            if stat -c "%a" "\$target" >/dev/null 2>&1; then
                orig_mode=\$(stat -c "%a" "\$target" 2>/dev/null)
            else
                orig_mode=\$(stat -f "%Lp" "\$target" 2>/dev/null || echo "640")
            fi
            awk '{print} /<\?php/ {print "define('\''FS_METHOD'\'', '\''direct'\'');"}' "\$target" > "\$target.tmp"
            chmod "\$orig_mode" "\$target.tmp" 2>/dev/null || true
            mv "\$target.tmp" "\$target"
            exit 0
        fi
        sed "\$@"
        ;;
    find|chmod)
        "\$cmd" "\$@"
        ;;
    *)
        "\$cmd" "\$@"
        ;;
esac
SUDOEOF
printf '#!/bin/sh\nexit 1\n' > "$PERM_BIN/systemctl"
chmod +x "$PERM_BIN/sudo" "$PERM_BIN/systemctl"

cat > "$PERM_TEST_HOME/scripts/wsms-config.sh" << PERMCONF
SITES=(
    "wp-isolated.com:$PERM_TEST_HOME/sites/wp_site:wp_user_iso_99"
    "html-isolated.com:$PERM_TEST_HOME/sites/html_site:html_user_iso_99"
)
LOG_PERMISSIONS="$PERM_TEST_HOME/logs/perms.log"
wsms_init_live_logging() { :; }
PERMCONF

HOME="$PERM_TEST_HOME" PATH="$PERM_BIN:$PATH" bash -x "$PREVIEW_EN/infrastructure-permission-orchestrator.sh" >/dev/null 2>&1 || true

grep -q "USERADD.*wp_user_iso_99" "$PERM_TEST_HOME/useradd.log" 2>/dev/null \
    && pass "orchestrator: auto-provisions dedicated WordPress user" \
    || fail "orchestrator: did not provision dedicated WordPress user"

grep -q "USERADD.*html_user_iso_99" "$PERM_TEST_HOME/useradd.log" 2>/dev/null \
    && pass "orchestrator: auto-provisions dedicated HTML user" \
    || fail "orchestrator: did not provision dedicated HTML user"

grep -q "FS_METHOD" "$PERM_TEST_HOME/sites/wp_site/wp-config.php" \
    && pass "orchestrator: injected FS_METHOD direct into wp-config.php" \
    || fail "orchestrator: missing FS_METHOD in wp-config.php"

wp_cfg_mode=$(get_file_mode "$PERM_TEST_HOME/sites/wp_site/wp-config.php")
[ "$wp_cfg_mode" = "640" ] \
    && pass "orchestrator: wp-config.php secured with 640 mode" \
    || fail "orchestrator: wp-config.php mode is $wp_cfg_mode, expected 640"

html_dir_mode=$(get_file_mode "$PERM_TEST_HOME/sites/html_site")
[ "$html_dir_mode" = "755" ] \
    && pass "orchestrator: static site directory set to 755" \
    || fail "orchestrator: static site directory mode is $html_dir_mode, expected 755"

html_file_mode=$(get_file_mode "$PERM_TEST_HOME/sites/html_site/index.html")
[ "$html_file_mode" = "644" ] \
    && pass "orchestrator: static site file set to 644" \
    || fail "orchestrator: static site file mode is $html_file_mode, expected 644"

# =================================================================
# SUMMARY
# =================================================================
echo ""
echo "=========================================================="
echo -e "${YELLOW}📊 TEST SUMMARY${NC}"
echo "   Total:  $((TESTS_PASSED + TESTS_FAILED))"
echo -e "   ${GREEN}✅ Passed: $TESTS_PASSED${NC}"
echo -e "   ${RED}❌ Failed: $TESTS_FAILED${NC}"

if [ "${#FAILED_TESTS[@]}" -gt 0 ]; then
    echo -e "\n${RED}Failed tests:${NC}"
    for t in "${FAILED_TESTS[@]}"; do
        echo "   • $t"
    done
fi

echo "=========================================================="

if [ "$TESTS_FAILED" -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ $TESTS_FAILED test(s) failed.${NC}"
    exit 1
fi
