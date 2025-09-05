# Script de Setup para Call Center Asterisk (PowerShell Windows)
# Compatible con Windows PowerShell y PowerShell Core

Write-Host "=== Setup Call Center con Asterisk en Docker ===" -ForegroundColor Cyan

# Función para mostrar mensajes con colores
function Write-Status {
    param(
        [string]$Message,
        [string]$Type = "Info"
    )
    
    switch ($Type) {
        "Success" { Write-Host "[OK] $Message" -ForegroundColor Green }
        "Error"   { Write-Host "[ERROR] $Message" -ForegroundColor Red }
        "Warning" { Write-Host "[WARNING] $Message" -ForegroundColor Yellow }
        "Info"    { Write-Host "[INFO] $Message" -ForegroundColor Blue }
        default   { Write-Host "$Message" -ForegroundColor White }
    }
}

# Verificar si Docker está disponible
Write-Status "Verificando requisitos..." "Info"
try {
    $dockerVersion = docker --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Status "Docker no esta instalado o no esta disponible" "Error"
        exit 1
    }
    Write-Status "Docker encontrado: $dockerVersion" "Success"
} catch {
    Write-Status "Error verificando Docker: $($_.Exception.Message)" "Error"
    exit 1
}

try {
    $composeVersion = docker-compose --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Status "Docker Compose no esta instalado" "Warning"
        Write-Status "Intentando usar 'docker compose'..." "Info"
    } else {
        Write-Status "Docker Compose encontrado: $composeVersion" "Success"
    }
} catch {
    Write-Status "Advertencia: Docker Compose podria no estar disponible" "Warning"
}

# Crear estructura de directorios
Write-Status "Creando estructura de directorios..." "Info"
$directories = @("config", "logs", "recordings", "scripts", "docs", "examples")

foreach ($dir in $directories) {
    try {
        if (!(Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Status "Directorio creado: $dir" "Success"
        } else {
            Write-Status "Directorio ya existe: $dir" "Warning"
        }
    } catch {
        Write-Status "Error creando directorio ${dir}: $($_.Exception.Message)" "Error"
    }
}

# Verificar archivos de configuración
Write-Status "Verificando archivos de configuracion..." "Info"
$configFiles = @(
    "config/asterisk.conf",
    "config/sip.conf", 
    "config/extensions.conf",
    "config/queues.conf",
    "config/agents.conf",
    "config/modules.conf"
)

$missingFiles = @()
foreach ($file in $configFiles) {
    if (!(Test-Path $file)) {
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Status "Archivos de configuracion faltantes:" "Warning"
    foreach ($file in $missingFiles) {
        Write-Host "   - $file" -ForegroundColor Yellow
    }
    Write-Status "Asegurate de copiar todos los archivos de configuracion antes de continuar" "Warning"
}

# Verificar Dockerfile y docker-compose.yml
if (!(Test-Path "Dockerfile")) {
    Write-Status "Dockerfile no encontrado" "Error"
    exit 1
}

if (!(Test-Path "docker-compose.yml")) {
    Write-Status "docker-compose.yml no encontrado" "Error"
    exit 1
}

# Construir imagen Docker
Write-Status "Construyendo imagen Docker..." "Info"
try {
    $buildProcess = Start-Process -FilePath "docker" -ArgumentList "build", "-t", "asterisk-callcenter", "." -Wait -PassThru -NoNewWindow
    if ($buildProcess.ExitCode -eq 0) {
        Write-Status "Imagen Docker construida exitosamente" "Success"
        
        # Mostrar información de la imagen
        try {
            $imageInfo = docker images asterisk-callcenter --format "{{.Repository}}:{{.Tag}} {{.Size}} {{.CreatedAt}}"
            Write-Host ""
            Write-Host "Informacion de la imagen:" -ForegroundColor Cyan
            Write-Host "   $imageInfo" -ForegroundColor White
        } catch {
            Write-Status "No se pudo obtener informacion de la imagen" "Warning"
        }
    } else {
        Write-Status "Error construyendo la imagen Docker" "Error"
        exit 1
    }
} catch {
    Write-Status "Error en el proceso de build: $($_.Exception.Message)" "Error"
    exit 1
}

# Iniciar contenedores
Write-Status "Iniciando contenedores..." "Info"
try {
    # Intentar con docker-compose primero, luego con docker compose
    $composeCmd = "docker-compose"
    if (!(Get-Command docker-compose -ErrorAction SilentlyContinue)) {
        $composeCmd = "docker compose"
    }
    
    $startProcess = Start-Process -FilePath $composeCmd.Split()[0] -ArgumentList $composeCmd.Split()[1], "up", "-d" -Wait -PassThru -NoNewWindow
    if ($startProcess.ExitCode -eq 0) {
        Write-Status "Contenedores iniciados exitosamente" "Success"
        
        # Esperar un momento para que el contenedor se inicie completamente
        Write-Status "Esperando que el contenedor se inicie completamente..." "Info"
        Start-Sleep -Seconds 5
        
        # Verificar estado del contenedor
        try {
            $containerStatus = docker ps --filter "name=asterisk-callcenter" --format "{{.Names}} | {{.Status}} | {{.Ports}}"
            Write-Host ""
            Write-Host "Estado del contenedor:" -ForegroundColor Cyan
            Write-Host "   $containerStatus" -ForegroundColor White
        } catch {
            Write-Status "No se pudo verificar el estado del contenedor" "Warning"
        }
        
    } else {
        Write-Status "Error iniciando los contenedores" "Error"
        exit 1
    }
} catch {
    Write-Status "Error en el proceso de inicio: $($_.Exception.Message)" "Error"
    exit 1
}

# Verificar que Asterisk esté funcionando
Write-Status "Verificando que Asterisk este funcionando..." "Info"
Start-Sleep -Seconds 3
try {
    $asteriskStatus = docker exec asterisk-callcenter asterisk -x "core show version" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Status "Asterisk esta funcionando correctamente" "Success"
        Write-Host ""
        Write-Host "Version de Asterisk:" -ForegroundColor Cyan
        Write-Host "   $($asteriskStatus | Select-Object -First 1)" -ForegroundColor White
    } else {
        Write-Status "Asterisk podria no estar completamente inicializado" "Warning"
        Write-Status "Espera unos minutos e intenta conectarte manualmente" "Info"
    }
} catch {
    Write-Status "No se pudo verificar el estado de Asterisk" "Warning"
}

# Mostrar información del sistema
Write-Host ""
Write-Host ("="*60) -ForegroundColor Cyan
Write-Host "SETUP COMPLETADO EXITOSAMENTE" -ForegroundColor Green
Write-Host ("="*60) -ForegroundColor Cyan

Write-Host ""
Write-Host "INFORMACION DEL CALL CENTER:" -ForegroundColor Cyan
Write-Host "   Contenedor: asterisk-callcenter" -ForegroundColor White
Write-Host "   Puerto SIP: 5060" -ForegroundColor White
Write-Host "   Puertos RTP: 10000-10100" -ForegroundColor White

# Obtener IP del contenedor
try {
    $containerIP = docker inspect -f "{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}" asterisk-callcenter 2>$null
    if ($containerIP -and $containerIP.Trim() -ne "") {
        Write-Host "   IP del Contenedor: $containerIP" -ForegroundColor White
    }
} catch {
    Write-Host "   IP del Contenedor: No disponible" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "USUARIOS CONFIGURADOS:" -ForegroundColor Cyan
$users = @(
    @{User="100"; Role="Cliente"; Pass="100"},
    @{User="200"; Role="Cliente"; Pass="100"},
    @{User="600"; Role="Agente (Mercado)"; Pass="100"},
    @{User="700"; Role="Agente (Reclamos)"; Pass="100"}
)

foreach ($user in $users) {
    Write-Host "   - Usuario: $($user.User) | $($user.Role) | Password: $($user.Pass)" -ForegroundColor White
}

Write-Host ""
Write-Host "EXTENSIONES PRINCIPALES:" -ForegroundColor Cyan
Write-Host "   - *611 o 01800: Acceder a cola de atencion" -ForegroundColor White
Write-Host "   - 600: Login agente Mercado" -ForegroundColor White
Write-Host "   - 700: Login agente Reclamos" -ForegroundColor White
Write-Host "   - *600: Logout agente 600" -ForegroundColor White
Write-Host "   - *700: Logout agente 700" -ForegroundColor White
Write-Host "   - *999: Estado de la cola" -ForegroundColor White

Write-Host ""
Write-Host "COMANDOS UTILES:" -ForegroundColor Cyan
Write-Host "   Conectar al CLI: " -ForegroundColor White -NoNewline
Write-Host "docker exec -it asterisk-callcenter asterisk -r" -ForegroundColor Yellow

Write-Host "   Ver logs: " -ForegroundColor White -NoNewline  
Write-Host "docker logs asterisk-callcenter" -ForegroundColor Yellow

Write-Host "   Estado del contenedor: " -ForegroundColor White -NoNewline
Write-Host "docker ps | findstr asterisk" -ForegroundColor Yellow

Write-Host "   Reiniciar: " -ForegroundColor White -NoNewline
Write-Host "docker-compose restart" -ForegroundColor Yellow

Write-Host ""
Write-Host "MONITOREO:" -ForegroundColor Cyan
Write-Host "   - Logs disponibles en: .\logs\" -ForegroundColor White
Write-Host "   - Grabaciones en: .\recordings\" -ForegroundColor White
Write-Host "   - Script de pruebas: .\scripts\test-strategies.ps1" -ForegroundColor White

Write-Host ""
Write-Host "PROXIMOS PASOS:" -ForegroundColor Cyan
Write-Host "   1. Configurar clientes SIP (Zoiper, X-Lite, etc.)" -ForegroundColor White
Write-Host "   2. Hacer login de agentes (marcar 600 y 700)" -ForegroundColor White
Write-Host "   3. Probar llamadas a *611 desde clientes" -ForegroundColor White
Write-Host "   4. Cambiar estrategias desde el CLI de Asterisk" -ForegroundColor White

Write-Host ""
Write-Host ("="*60) -ForegroundColor Cyan
Write-Status "Call Center listo para usar!" "Success"
Write-Host ("="*60) -ForegroundColor Cyan

Write-Host ""
Write-Status "Para conectarte al CLI de Asterisk, ejecuta:" "Info"
Write-Host "docker exec -it asterisk-callcenter asterisk -r" -ForegroundColor Yellow