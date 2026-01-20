param(
  [switch]$WithMobile
)

$ErrorActionPreference = "Stop"

docker compose up -d db

Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd backend; mvn spring-boot:run"

if ($WithMobile) {
  Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd mobile; flutter run"
} else {
  Write-Host "Backend avviato. In un altro terminale: cd mobile; flutter run"
}
