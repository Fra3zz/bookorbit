#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="server/.env"
ENV_EXAMPLE="server/.env.example"

# ── Helpers ──────────────────────────────────────────────────────────────────

log()  { printf '\033[1;34m[dev]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[dev]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[dev]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[dev]\033[0m %s\n' "$*" >&2; exit 1; }

gen_secret() {
  # 32 random bytes -> 64 hex chars (256-bit key)
  openssl rand -hex 32
}

gen_token() {
  # 16 random bytes -> 32 hex chars
  openssl rand -hex 16
}

# ── Dependency checks ─────────────────────────────────────────────────────────

command -v docker  >/dev/null 2>&1 || die "docker is not installed or not in PATH"
command -v pnpm    >/dev/null 2>&1 || die "pnpm is not installed or not in PATH"
command -v openssl >/dev/null 2>&1 || die "openssl is not installed or not in PATH"
command -v node    >/dev/null 2>&1 || die "node is not installed or not in PATH"

NODE_MAJOR=$(node -e 'process.stdout.write(process.versions.node.split(".")[0])')
if [ "$NODE_MAJOR" -lt 24 ]; then
  die "Node >= 24 is required (found $(node --version))"
fi

# ── Create .env if missing ────────────────────────────────────────────────────

if [ ! -f "$ENV_FILE" ]; then
  log "No server/.env found - generating one from .env.example with secure secrets..."

  JWT_SECRET_VAL=$(gen_secret)
  SETUP_TOKEN_VAL=$(gen_token)
  EMAIL_KEY_VAL=$(gen_secret)
  MIGRATION_KEY_VAL=$(gen_secret)
  BOOK_REQUEST_KEY_VAL=$(gen_secret)

  # Copy the example, then substitute the placeholder values with generated ones.
  cp "$ENV_EXAMPLE" "$ENV_FILE"

  # JWT_SECRET
  sed -i.bak "s|^JWT_SECRET=.*|JWT_SECRET=${JWT_SECRET_VAL}|" "$ENV_FILE"

  # SETUP_BOOTSTRAP_TOKEN (was blank in the example)
  sed -i.bak "s|^SETUP_BOOTSTRAP_TOKEN=.*|SETUP_BOOTSTRAP_TOKEN=${SETUP_TOKEN_VAL}|" "$ENV_FILE"

  # Uncomment and fill the optional encryption keys for a more complete dev env
  sed -i.bak "s|^# EMAIL_ENCRYPTION_KEY=.*|EMAIL_ENCRYPTION_KEY=${EMAIL_KEY_VAL}|" "$ENV_FILE"
  sed -i.bak "s|^# MIGRATION_ENCRYPTION_KEY=.*|MIGRATION_ENCRYPTION_KEY=${MIGRATION_KEY_VAL}|" "$ENV_FILE"
  sed -i.bak "s|^# BOOK_REQUEST_ENCRYPTION_KEY=.*|BOOK_REQUEST_ENCRYPTION_KEY=${BOOK_REQUEST_KEY_VAL}|" "$ENV_FILE"

  rm -f "${ENV_FILE}.bak"

  ok "server/.env created"
  warn "  JWT_SECRET and SETUP_BOOTSTRAP_TOKEN have been randomly generated."
  warn "  The bootstrap token is only needed during first-time setup at /setup."
else
  ok "server/.env already exists - skipping generation"
fi

# ── Install dependencies ──────────────────────────────────────────────────────

log "Installing dependencies..."
pnpm install --frozen-lockfile

# ── Start PostgreSQL ──────────────────────────────────────────────────────────

log "Starting PostgreSQL (dev compose)..."
docker compose -f docker-compose.dev.yml up -d

log "Waiting for PostgreSQL to be ready..."
RETRIES=20
until docker compose -f docker-compose.dev.yml exec -T postgres \
    pg_isready -U bookorbit -d bookorbit >/dev/null 2>&1; do
  RETRIES=$((RETRIES - 1))
  if [ "$RETRIES" -le 0 ]; then
    die "PostgreSQL did not become ready in time"
  fi
  sleep 1
done
ok "PostgreSQL is ready"

# ── Run migrations ────────────────────────────────────────────────────────────

log "Running database migrations..."
(cd server && pnpm db:migrate)
ok "Migrations complete"

# ── Start dev servers ─────────────────────────────────────────────────────────

ok "Starting dev servers..."
echo ""
echo "  Client  →  http://localhost:6263"
echo "  Server  →  http://localhost:6262"
echo " "

pnpm dev
