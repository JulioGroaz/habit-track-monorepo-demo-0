#!/usr/bin/env bash
set -euo pipefail

docker compose up -d db

if [[ "${WITH_MOBILE:-}" == "1" ]]; then
  (cd backend && mvn spring-boot:run) &
  (cd mobile && flutter run)
else
  echo "Backend running. In another terminal: cd mobile && flutter run"
  (cd backend && mvn spring-boot:run)
fi
