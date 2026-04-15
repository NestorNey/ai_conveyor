#!/bin/bash

# Detener el script si ocurre algún error crítico
set -e

echo "🛠️  Iniciando despliegue de AI Conveyor..."

# ---------------------------------------------------------
# 1. LEVANTAR EL FRONTEND (UI) EN DOCKER
# ---------------------------------------------------------
echo "📦 Verificando imagen de UI..."

# Solo construye si la imagen NO existe
if [[ "$(docker images -q ai_conveyor_ui 2> /dev/null)" == "" ]]; then
    echo "🏗️  Imagen no encontrada. Construyendo..."
    docker build -t ai_conveyor_ui /app/ai_conveyor/ai_conveyor_ui
else
    echo "✅ La imagen ya existe, saltando construcción."
fi

# Detener y eliminar el contenedor viejo si existe
docker rm -f ai_conveyor_ui_container 2>/dev/null || true

echo "🚀 Iniciando contenedor de UI..."
docker run -d \
  --name ai_conveyor_ui_container \
  -p 5173:5173 \
  --restart unless-stopped \
  ai_conveyor_ui

# ---------------------------------------------------------
# 2. PREPARAR EL SISTEMA OPERATIVO
# ---------------------------------------------------------
echo "⚙️  Instalando dependencias del sistema..."
# No usamos update siempre para no perder tiempo si el servicio reinicia seguido
sudo apt-get install -y swig libcap-dev python3-dev build-essential python3-libcamera libcamera-dev liblgpio-dev || echo "Omitiendo algunas dependencias..."

# ---------------------------------------------------------
# 3. PREPARAR Y COMPILAR CON UV
# ---------------------------------------------------------
echo "🐍 Configurando entorno virtual..."
cd /app/ai_conveyor/ai_conveyor_api

# Solo borramos y recreamos si NO existe el venv
if [ ! -d ".venv" ]; then
    echo "Creating fresh venv..."
    uv venv --python /usr/bin/python3.13 --system-site-packages
fi

# Sincronizamos dependencias
uv sync

# 🔥 CORRECCIÓN CRÍTICA: El link debe apuntar a la carpeta 3.13, no 3.11
echo "🔗 Enlazando libcamera al venv de Python 3.13..."
ln -sf /usr/lib/python3/dist-packages/libcamera /app/ai_conveyor/ai_conveyor_api/.venv/lib/python3.13/site-packages/ 2>/dev/null || true

# ---------------------------------------------------------
# 4. ARRANCAR EL BACKEND (FASTAPI)
# ---------------------------------------------------------
echo "🚀 Arrancando FastAPI en el host..."
/app/ai_conveyor/ai_conveyor_api/.venv/bin/python -m uvicorn src.main:app --host 0.0.0.0 --port 8000