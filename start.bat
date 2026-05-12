@echo off
echo Lancement du projet Soeurise...
echo.

echo Lancement du Backend...
start "Soeurise Backend" cmd /k "cd soeurise-backend && npm install && npm run dev"

echo Lancement du Frontend...
start "Soeurise Frontend" cmd /k "cd soeurise-frontend && flutter pub get && flutter run -d windows"


echo.
echo Les deux projets sont en cours de lancement dans des fenêtres séparées.
