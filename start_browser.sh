#!/bin/bash

# Esperar a que el puerto 5173 (Vite/UI) esté abierto
echo "Esperando a que la UI esté lista..."
while ! nc -z localhost 5173; do   
  sleep 1
done

echo "¡UI lista! Abriendo Firefox en modo kiosko..."

# Abrir Firefox en modo kiosko
# --kiosk abre en pantalla completa sin barras de herramientas
# --private-window opcional por si no quieres que guarde caché
firefox --kiosk http://localhost:5173