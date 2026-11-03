#!/usr/bin/env bash
set -e

SKIP_BUILD=false
SKIP_WEB=false
SKIP_WORKER=false
DEPLOY_WORKER=false
DEPLOY_FIRESTORE=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-build)
      SKIP_BUILD=true
      shift
      ;;
    --skip-web)
      SKIP_WEB=true
      shift
      ;;
    --skip-worker)
      SKIP_WORKER=true
      shift
      ;;
    --deploy-worker)
      DEPLOY_WORKER=true
      shift
      ;;
    --deploy-firestore)
      DEPLOY_FIRESTORE=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
WORKER_DIR="$ROOT_DIR/workers/auth-otp"

# Step 1: Worker check
if [ "$SKIP_BUILD" = false ] && [ "$SKIP_WORKER" = false ]; then
  echo ">>> Step 1/3: Verifying & Testing Auth OTP Worker..."
  "$SCRIPT_DIR/build.sh" worker
else
  echo ">>> Step 1/3: Skipping worker check..."
fi

# Optional: Deploy Worker
if [ "$DEPLOY_WORKER" = true ]; then
  echo -e "\n>>> Deploying Auth OTP Worker to Cloudflare..."
  cd "$WORKER_DIR"
  worker_args=("deploy")
  if [ "$DRY_RUN" = true ]; then worker_args+=("--dry-run"); fi
  npx wrangler "${worker_args[@]}"
fi

# Step 2: Flutter Web build
if [ "$SKIP_BUILD" = false ] && [ "$SKIP_WEB" = false ]; then
  echo -e "\n>>> Step 2/3: Building Flutter Web PWA..."
  "$SCRIPT_DIR/build.sh" web
else
  echo -e "\n>>> Step 2/3: Skipping web build..."
fi

# Step 3: Cloudflare deploy
echo -e "\n>>> Step 3/3: Deploying Web Assets to Cloudflare..."
cd "$ROOT_DIR"
deploy_args=("deploy" "--config" "wrangler.jsonc")
if [ "$DRY_RUN" = true ]; then deploy_args+=("--dry-run"); fi
npx wrangler "${deploy_args[@]}"

# Step 4 (Optional): Firestore deploy
if [ "$DEPLOY_FIRESTORE" = true ]; then
  echo -e "\n>>> Step 4: Deploying Cloud Firestore Rules & Indexes to Firebase..."
  cd "$ROOT_DIR"
  npx -y firebase-tools@latest deploy --only firestore
fi

echo -e "\n========================================"
echo " Deployment completed successfully!"
echo "========================================"
