# Guía de Pruebas - Call Center Asterisk

## Configuración del Cliente SIP

Para probar el Call Center, necesitarás configurar clientes SIP. Puedes usar:
- **Zoiper** (gratuito)
- **X-Lite** (gratuito)
- **SIP Softphone** (móvil)

### Configuración del Cliente:
- **Servidor SIP:** IP del servidor Docker
- **Puerto:** 5060
- **Usuarios disponibles:** 100, 200, 600, 700
- **Contraseña:** 100 (para todos)

## Estrategias de Cola Disponibles

### 1. RingAll (Configuración por defecto)
- **Comportamiento:** Hace sonar todos los agentes disponibles simultáneamente
- **Uso:** Cuando quieres la respuesta más rápida posible
- **Modificación en CLI:**
```bash
*CLI> queue set strategy atencion ringall
```

### 2. RoundRobin
- **Comportamiento:** Distribuye llamadas secuencialmente entre agentes
- **Uso:** Distribución equitativa de carga
- **Comando:** `queue set strategy atencion roundrobin`

### 3. LeastRecent
- **Comportamiento:** Dirige llamadas al agente que menos recientemente atendió una llamada
- **Uso:** Balanceo basado en tiempo de última llamada
- **Comando:** `queue set strategy atencion leastrecent`

### 4. FewestCalls
- **Comportamiento:** Dirige llamadas al agente con menos llamadas atendidas
- **Uso:** Distribución equitativa por número de llamadas
- **Comando:** `queue set strategy atencion fewestcalls`

### 5. Random
- **Comportamiento:** Selecciona agentes aleatoriamente
- **Uso:** Distribución completamente aleatoria
- **Comando:** `queue set strategy atencion random`

### 6. RRMemory (Round Robin con Memoria)
- **Comportamiento:** Como roundrobin pero recuerda el último agente llamado
- **Uso:** Distribución secuencial que persiste entre reinicios
- **Comando:** `queue set strategy atencion rrmemory`

## Procedimiento de Pruebas

### Paso 1: Iniciar el Sistema
```bash
./setup.sh
docker-compose up -d
```

### Paso 2: Verificar Estado
```bash
docker exec -it asterisk-callcenter asterisk -r
*CLI> sip show peers
*CLI> queue show
```

### Paso 3: Login de Agentes
1. Configurar clientes SIP para usuarios 600 y 700
2. Desde cada agente, marcar su número (600 o 700) para hacer login
3. Verificar con `*CLI> queue show atencion`

### Paso 4: Realizar Llamadas de Prueba
1. Configurar clientes SIP para usuarios 100 y 200
2. Marcar *611 o 01800 para entrar a la cola
3. Observar el comportamiento según la estrategia configurada

### Paso 5: Cambiar Estrategias y Comparar
```bash
# En el CLI de Asterisk
*CLI> queue set strategy atencion roundrobin
*CLI> queue show atencion

# Realizar llamadas y observar diferencias
# Cambiar a otra estrategia
*CLI> queue set strategy atencion leastrecent
```

## Comandos Útiles del CLI

### Gestión de Colas
```bash
queue show                    # Mostrar todas las colas
queue show atencion          # Mostrar cola específica
queue add member SIP/600 to atencion    # Agregar miembro
queue remove member SIP/600 from atencion # Remover miembro
```

### Monitoreo
```bash
sip show peers              # Ver estado de usuarios SIP
core show channels          # Ver canales activos
queue show                  # Ver estadísticas de colas
```

### Debugging
```bash
sip set debug on            # Debug SIP
queue set debug on          # Debug de colas
core set verbose 5          # Aumentar verbosidad
```

## Métricas a Observar

### 1. Tiempo de Espera
- Tiempo que los callers esperan antes de ser atendidos
- Varía según estrategia y disponibilidad de agentes

### 2. Distribución de Llamadas
- **RingAll:** Primer agente disponible
- **RoundRobin:** Distribución secuencial
- **FewestCalls:** El menos ocupado
- **LeastRecent:** El menos recientemente usado
- **Random:** Distribución aleatoria

### 3. Eficiencia del Sistema
- Número de llamadas perdidas
- Tiempo promedio de atención
- Utilización de agentes

## Escenarios de Prueba Recomendados

### Escenario 1: Alta Demanda
- Simular 5+ llamadas simultáneas
- Comparar comportamiento entre estrategias
- Medir tiempos de espera

### Escenario 2: Agente Ocupado
- Un agente en llamada, otro disponible
- Observar cómo cada estrategia maneja la situación

### Escenario 3: Login/Logout Dinámico
- Agentes entrando y saliendo durante operación
- Verificar adaptación del sistema

## Resolución de Problemas Comunes

### Problema: No se conectan los clientes SIP
- **Solución:** Verificar que el puerto 5060 esté expuesto
- **Comando:** `docker port asterisk-callcenter`

### Problema: No suenan las llamadas
- **Solución:** Verificar configuración de códecs
- **Comando:** `*CLI> sip show peer 600`

### Problema: Cola no funciona
- **Solución:** Verificar que los agentes estén loggeados
- **Comando:** `*CLI> queue show atencion`

## Logs y Monitoreo
- **Logs del contenedor:** `docker logs asterisk-callcenter`
- **Logs de Asterisk:** `./logs/asterisk/messages`
- **Monitor en tiempo real:** `docker exec -it asterisk-callcenter asterisk -r`

#docker exec -it asterisk-callcenter asterisk -rvvv
