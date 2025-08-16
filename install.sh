#!/bin/bash

# ==============================================================================
# == INSTALADOR TODO-EN-UNO PARA BOT-MKW (v5.0 - Con Dependencias) =============
# ==============================================================================
#
# Este script es completamente autónomo. No descarga archivos adicionales.
# Contiene todo el código del proyecto y lo crea en el servidor del cliente.
# AÑADIDO: Instala las dependencias de sistema para Puppeteer/Chromium.
#
# ==============================================================================

# --- Variables de configuración ---
PROJECT_DIR="mkw-support"
PM2_APP_NAME="bot-mkw"
REQUIRED_NODE_VERSION=18

# --- Colores para la salida ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# ==============================================================================
# == SECCIÓN 1: CREACIÓN DE LOS ARCHIVOS DEL PROYECTO ==========================
# ==============================================================================

create_project_files() {
    echo -e "${YELLOW}---> Creando la estructura de directorios del proyecto...${NC}"
    rm -rf "$PROJECT_DIR"
    mkdir -p "$PROJECT_DIR/public" "$PROJECT_DIR/modules"
    cd "$PROJECT_DIR" || { echo -e "${RED}Error: No se pudo crear el directorio del proyecto.${NC}"; exit 1; }
    echo -e "${GREEN}Estructura creada con éxito.${NC}\n"

    echo -e "${YELLOW}---> Creando archivos del proyecto desde la memoria interna...${NC}"

# --- Creando app.js ---
cat << 'EOF' > app.js
// app.js
const http = require('http');
const express = require('express');
const chalk = require('chalk');

// Módulos de nuestra aplicación
const whatsappClient = require('./modules/whatsappClient');
const createMikrowispApi = require('./modules/mikrowispApi');
const createWebPanel = require('./modules/webPanel');

// --- INICIAR API PARA MIKROWISP (Puerto 3000) ---
const mikrowispApp = express();
createMikrowispApi(mikrowispApp, whatsappClient);
const mikrowispServer = http.createServer(mikrowispApp);
mikrowispServer.listen(3000, () => {
    // Este log no se enviará al panel porque la función de broadcast aún no existe.
    console.log(chalk.blue('🚀 API para Mikrowisp escuchando en el puerto 3000'));
});


// --- INICIAR PANEL DE CONTROL WEB (Puerto 6780) ---
const webPanelApp = express();
const webPanelServer = http.createServer(webPanelApp);
// Modificamos para capturar la función de broadcast que retorna el módulo del panel.
const { broadcast } = createWebPanel(webPanelApp, webPanelServer, whatsappClient);

webPanelServer.listen(6780, () => {
    // Este tampoco se enviará.
    console.log(chalk.magenta('🖥️  Panel de Control Web escuchando en el puerto 6780'));
});

// --- INICIO DE LA NUEVA FUNCIONALIDAD: CONSOLA EN VIVO ---
// Guardamos las funciones originales de la consola.
const originalLog = console.log;
const originalError = console.error;
const originalWarn = console.warn;

// Sobrescribimos console.log
console.log = function(...args) {
    originalLog.apply(console, args); // Mantenemos el log original en la terminal de PM2
    const message = args.map(arg => (typeof arg === 'object' && arg !== null) ? JSON.stringify(arg, null, 2) : arg).join(' ');
    // Usamos la función de broadcast para enviar el log al panel web.
    if (broadcast) broadcast({ type: 'log', data: { level: 'log', message } });
};

// Sobrescribimos console.error
console.error = function(...args) {
    originalError.apply(console, args);
    const message = args.map(arg => (typeof arg === 'object' && arg !== null) ? JSON.stringify(arg, null, 2) : arg).join(' ');
    if (broadcast) broadcast({ type: 'log', data: { level: 'error', message } });
};

// Sobrescribimos console.warn
console.warn = function(...args) {
    originalWarn.apply(console, args);
    const message = args.map(arg => (typeof arg === 'object' && arg !== null) ? JSON.stringify(arg, null, 2) : arg).join(' ');
    if (broadcast) broadcast({ type: 'log', data: { level: 'warn', message } });
};
// --- FIN DE LA NUEVA FUNCIONALIDAD ---

console.log(chalk.green.bold('Aplicación Bot-MKW iniciada y sistema de logs activado.'));

// Se inicia la conexión del bot automáticamente al arrancar la aplicación.
console.log(chalk.yellow('Iniciando conexión automática del bot...'));
whatsappClient.initialize();
EOF

# --- Creando package.json ---
cat << 'EOF' > package.json
{
  "name": "bot-mkw-pro",
  "version": "2.0.0",
  "description": "Bot de WhatsApp con API para Mikrowisp y Panel de Control Web",
  "main": "app.js",
  "scripts": {
    "start": "node app.js"
  },
  "keywords": [
    "whatsapp",
    "bot",
    "node",
    "mikrowisp",
    "express"
  ],
  "author": "Your Name",
  "license": "ISC",
  "dependencies": {
    "body-parser": "^1.20.2",
    "chalk": "^4.1.2",
    "express": "^4.18.2",
    "express-session": "^1.17.3",
    "qrcode": "^1.5.3",
    "whatsapp-web.js": "^1.23.0",
    "ws": "^8.13.0"
  }
}
EOF

# --- Creando .gitignore ---
cat << 'EOF' > .gitignore
# Archivo .gitignore para Bot-MKW Pro

# Dependencias de Node.js (se instalan con 'npm install')
node_modules/

# Archivos de sesión de WhatsApp-Web.js
# ¡Contiene información sensible de la sesión!
.wwebjs_auth/

# Archivo de usuarios con contraseñas
users.json

# Logs de PM2 (si se generan localmente)
*.log
logs/

# Archivos del sistema operativo
.DS_Store
Thumbs.db

core
EOF

# --- Creando modules/mikrowispApi.js ---
cat << 'EOF' > modules/mikrowispApi.js
// modules/mikrowispApi.js
const express = require('express');
const chalk = require('chalk');

const API_TOKEN = 'token_a_reemplazar'; // Este token será reemplazado por el script de instalación

function createMikrowispApi(app, whatsappClient) {
    app.use(express.json());

    // Middleware de autenticación
    const authenticateToken = (req, res, next) => {
        const authHeader = req.headers['authorization'];
        const token = authHeader && authHeader.split(' ')[1];
        if (token == null) return res.status(401).json({ error: 'Token no proporcionado' });
        if (token !== API_TOKEN) return res.status(403).json({ error: 'Token inválido' });
        next();
    };

    app.get('/send-message', authenticateToken, async (req, res) => {
        const now = new Date();
        const horaActual = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}:${now.getSeconds().toString().padStart(2, '0')}`;
        const { destinatario, mensaje } = req.query;

        console.log(chalk.magenta(`\n📡 Petición de Mikrowisp para enviar a: ${chalk.bold(destinatario)} - 🕒 ${horaActual}`));

        if (!destinatario || !mensaje) {
            return res.status(400).json({ status: 'error', message: 'Faltan los parámetros "destinatario" o "mensaje"' });
        }

        const numeroLimpio = destinatario.replace(/\D/g, '');
        const chatId = `549${numeroLimpio}@c.us`;
        const mensajeSinCorchetes = mensaje.replace(/[{}]/g, '');
        const mensajeFinal = `*MENSAJE AUTOMÁTICO*\n\n${mensajeSinCorchetes}`;

        console.log(chalk.cyan(`   Mensaje final a enviar: "${mensajeFinal}"`));

        try {
            if (whatsappClient.getStatus() !== 'CONECTADO') {
                throw new Error('El cliente de WhatsApp no está conectado. No se puede enviar el mensaje.');
            }
            await whatsappClient.sendMessage(chatId, mensajeFinal);
            console.log(chalk.green(`Mensaje enviado exitosamente a ${chatId} ✅`));
            res.status(200).json({ status: 'success', message: 'Mensaje enviado correctamente' });
        } catch (error) {
            console.error(chalk.red(`❌ Error al enviar mensaje a ${chatId}:`), error.message);
            res.status(500).json({ status: 'error', message: 'El bot no pudo enviar el mensaje.', details: error.message });
        }
    });

    return app;
}

module.exports = createMikrowispApi;
EOF

# --- Creando modules/webPanel.js ---
cat << 'EOF' > modules/webPanel.js
// modules/webPanel.js
const express = require('express');
const session = require('express-session');
const bodyParser = require('body-parser');
const path = require('path');
const fs = require('fs');
const { WebSocketServer } = require('ws');
const qrcode = require('qrcode');

function createWebPanel(app, server, whatsappClient) {
    const wss = new WebSocketServer({ server });

    app.use(session({
        secret: 'una-clave-muy-secreta-para-mkw',
        resave: false,
        saveUninitialized: true,
        cookie: { secure: false }
    }));
    app.use(express.static(path.join(__dirname, '..', 'public')));
    app.use(bodyParser.urlencoded({ extended: true }));

    const checkAuth = (req, res, next) => {
        if (req.session.loggedin) {
            next();
        } else {
            res.redirect('/');
        }
    };

    app.get('/', (req, res) => res.sendFile(path.join(__dirname, '..', 'public', 'login.html')));
    app.post('/login', (req, res) => {
        const { username, password } = req.body;
        const users = JSON.parse(fs.readFileSync(path.join(__dirname, '..', 'users.json')));
        if (users[username] && users[username] === password) {
            req.session.loggedin = true;
            req.session.username = username;
            res.redirect('/panel');
        } else {
            res.send('Usuario o Contraseña Incorrecta!');
        }
    });
    app.get('/panel', checkAuth, (req, res) => res.sendFile(path.join(__dirname, '..', 'public', 'mkwap.html')));
    app.get('/logout', (req, res) => {
        req.session.destroy(() => res.redirect('/'));
    });
    app.get('/api/connect', checkAuth, (req, res) => {
        if (whatsappClient.getStatus() === 'DESCONECTADO' || whatsappClient.getStatus() === 'ERROR') {
            whatsappClient.initialize();
            res.json({ message: 'Comando de conexión enviado.' });
        } else {
            res.json({ message: 'El cliente ya está conectado o en proceso.' });
        }
    });
    app.get('/api/disconnect', checkAuth, (req, res) => {
        whatsappClient.disconnect();
        res.json({ message: 'Comando de reinicio enviado. El servicio se reiniciará en breve.' });
        setTimeout(() => {
            console.log('REINICIANDO EL SERVICIO...');
            process.exit(1);
        }, 1000);
    });
    app.get('/api/status', checkAuth, (req, res) => res.json({ status: whatsappClient.getStatus() }));

    wss.on('connection', (ws) => {
        console.log('Cliente conectado al panel de control.');
        ws.on('close', () => console.log('Cliente del panel desconectado.'));
    });

    function broadcast(data) {
        wss.clients.forEach((client) => {
            if (client.readyState === 1) {
                client.send(JSON.stringify(data));
            }
        });
    }

    whatsappClient.on('statusChange', (status) => broadcast({ type: 'status', data: status }));
    whatsappClient.on('qr', async (qr) => {
        try {
            const qrDataURL = await qrcode.toDataURL(qr);
            broadcast({ type: 'qr', data: qrDataURL });
        } catch (err) {
            console.error('Error al generar QR para el panel web:', err);
        }
    });

    // Retornamos la función de broadcast para que app.js pueda usarla.
    return { broadcast };
}

module.exports = createWebPanel;
EOF

# --- Creando modules/whatsappClient.js ---
cat << 'EOF' > modules/whatsappClient.js
// modules/whatsappClient.js
const { Client, LocalAuth } = require('whatsapp-web.js');
const { EventEmitter } = require('events');
const chalk = require('chalk');

class WhatsAppClient extends EventEmitter {
    constructor() {
        super();
        this.client = null;
        this.status = 'DESCONECTADO';
    }

    initialize() {
        if (this.client || this.status === 'INICIALIZANDO') {
            return;
        }
        this.updateStatus('INICIALIZANDO');
        this.client = new Client({
            authStrategy: new LocalAuth({ clientId: "bot_mkw" }),
            puppeteer: {
                args: ['--no-sandbox', '--disable-setuid-sandbox'],
            },
             webVersionCache: {
              type: 'remote',
              remotePath: 'https://raw.githubusercontent.com/wppconnect-team/wa-version/main/html/2.2412.54.html',
            }
        });

        this.client.on('qr', (qr) => {
            this.updateStatus('ESPERANDO QR');
            this.emit('qr', qr);
        });
        this.client.on('ready', () => this.updateStatus('CONECTADO'));
        this.client.on('disconnected', (reason) => {
            this.client = null;
            this.updateStatus('DESCONECTADO');
        });
        this.client.on('auth_failure', () => this.updateStatus('ERROR DE AUTENTICACIÓN'));
        this.client.on('message', this.handleMessage.bind(this));
        this.client.initialize().catch(() => this.updateStatus('ERROR'));
    }

    async disconnect() {
        if (this.client) {
            await this.client.destroy();
            this.client = null;
            this.updateStatus('DESCONECTADO');
        }
    }

    handleMessage(message) {
        // --- INICIO DE LA MODIFICACIÓN ---
        // Filtro para ignorar los estados de WhatsApp y no mostrarlos en consola.
        if (message.from === 'status@broadcast') {
            return;
        }
        // --- FIN DE LA MODIFICACIÓN ---

        if (!this.client) return;
        console.log(chalk.blue(`📥 Mensaje recibido de ${chalk.bold(message.from)}:`) + ` ${message.body}`);
        if (message.body.toLowerCase() === '!ping') {
            this.client.sendMessage(message.from, 'pong');
        }
    }

    async sendMessage(chatId, message) {
        if (this.status !== 'CONECTADO' || !this.client) {
            throw new Error('El cliente no está conectado.');
        }
        return this.client.sendMessage(chatId, message);
    }

    updateStatus(newStatus) {
        if (this.status === newStatus) return;
        this.status = newStatus;
        this.emit('statusChange', this.status);
    }

    getStatus() {
        return this.status;
    }
}

module.exports = new WhatsAppClient();
EOF

# --- Creando public/client.js ---
cat << 'EOF' > public/client.js
// public/client.js
document.addEventListener('DOMContentLoaded', () => {
    const statusText = document.getElementById('status-text');
    const qrContainer = document.getElementById('qr-container');
    const qrImage = document.getElementById('qr-image');
    const connectBtn = document.getElementById('connect-btn');
    const disconnectBtn = document.getElementById('disconnect-btn');
    const logIframe = document.getElementById('log-iframe'); // Referencia al iframe

    // --- WEBSOCKET CONNECTION ---
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const ws = new WebSocket(`${protocol}//${window.location.host}`);

    ws.onopen = () => {
        console.log('Conectado al servidor del panel.');
        fetch('/api/status').then(res => res.json()).then(data => {
            updateStatusUI(data.status);
        });
    };

    ws.onmessage = (event) => {
        const message = JSON.parse(event.data);
        if (message.type === 'status') {
            updateStatusUI(message.data);
        } else if (message.type === 'qr') {
            qrImage.src = message.data;
            qrContainer.style.display = 'block';
        } else if (message.type === 'log') {
            // Enviamos el mensaje al iframe
            if (logIframe && logIframe.contentWindow) {
                logIframe.contentWindow.postMessage(message.data, '*');
            }
        }
    };

    ws.onclose = () => {
        console.log('Conexión con el servidor perdida. Recargando la página en 3 segundos...');
        updateStatusUI('SERVIDOR_REINICIANDO');
        setTimeout(() => {
            window.location.reload();
        }, 3000);
    };

    // --- UI UPDATES ---
    function updateStatusUI(status) {
        statusText.textContent = status.replace(/_/g, ' ');
        statusText.className = `status-${status}`;
        if (status !== 'ESPERANDO QR') {
            qrContainer.style.display = 'none';
        }
        if (status === 'CONECTADO') {
            connectBtn.disabled = true;
            disconnectBtn.disabled = false;
        } else if (status === 'DESCONECTADO' || status === 'ERROR') {
            connectBtn.disabled = false;
            disconnectBtn.disabled = true;
        } else {
            connectBtn.disabled = true;
            disconnectBtn.disabled = true;
        }
    }

    // --- EVENT LISTENERS ---
    connectBtn.addEventListener('click', () => {
        fetch('/api/connect').then(res => res.json()).then(data => console.log(data.message));
    });

    disconnectBtn.addEventListener('click', () => {
        fetch('/api/disconnect').then(res => res.json()).then(data => console.log(data.message));
    });
});
EOF

# --- Creando public/console.html ---
cat << 'EOF' > public/console.html
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Consola en Vivo</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">
    <style>
        /* Estilos específicos para la consola dentro del iframe */
        @import url('https://fonts.googleapis.com/css2?family=Fira+Code:wght@400;500&display=swap');

        body {
            background-color: #1e1e1e;
            color: #d4d4d4;
            font-family: 'Fira Code', 'Menlo', 'Monaco', 'Courier New', monospace;
            font-size: 0.9em;
            margin: 0;
            padding: 15px;
            word-break: break-all;
        }

        .log-entry {
            margin: 0;
            padding: 3px 5px;
            line-height: 1.5;
            display: flex;
            align-items: center;
            gap: 10px;
            border-radius: 3px;
        }
        
        .log-entry:hover {
            background-color: #2a2d2e;
        }

        .icon { font-size: 0.8em; }
        .timestamp { color: #6a9955; font-weight: 500; }
        .message { white-space: pre-wrap; }

        .log-info .icon { color: #569cd6; }
        .log-log .icon { color: #9cdcfe; }
        .log-warn .icon { color: #ce9178; }
        .log-error .icon { color: #f44747; }
        
        .log-info .message { color: #569cd6; }
        .log-log .message { color: #d4d4d4; }
        .log-warn .message { color: #ce9178; }
        .log-error .message { color: #f44747; font-weight: 500; }
    </style>
</head>
<body>
    <div class="log-entry log-info">
        <span class="message">Esperando logs del servidor...</span>
    </div>

    <script>
        let initialLogCleared = false;

        // Escuchamos los mensajes que nos envía la página principal (mkwap.html)
        window.addEventListener('message', (event) => {
            // Por seguridad, podríamos comprobar el origen: if (event.origin !== 'http://tu-dominio.com') return;
            
            if (!initialLogCleared) {
                document.body.innerHTML = ''; // Limpiamos el mensaje inicial
                initialLogCleared = true;
            }

            const { level, message } = event.data;
            addLogEntry(level, message);
        });

        function addLogEntry(level, message) {
            const logEntry = document.createElement('div');
            logEntry.className = `log-entry log-${level}`;

            const iconSpan = document.createElement('span');
            iconSpan.className = 'icon';
            const icons = {
                'log': 'fas fa-info-circle',
                'warn': 'fas fa-exclamation-triangle',
                'error': 'fas fa-times-circle',
                'info': 'fas fa-bell'
            };
            iconSpan.innerHTML = `<i class="${icons[level] || 'fas fa-angle-right'}"></i>`;

            const timestampSpan = document.createElement('span');
            timestampSpan.className = 'timestamp';
            timestampSpan.textContent = `[${new Date().toLocaleTimeString()}]`;

            const messageSpan = document.createElement('span');
            messageSpan.className = 'message';
            messageSpan.textContent = message.replace(/[\u001b\u009b][[()#;?]*(?:[0-9]{1,4}(?:;[0-9]{0,4})*)?[0-9A-ORZcf-nqry=><]/g, '');

            logEntry.appendChild(iconSpan);
            logEntry.appendChild(timestampSpan);
            logEntry.appendChild(messageSpan);
            
            document.body.appendChild(logEntry);
            // Auto-scroll al fondo
            window.scrollTo(0, document.body.scrollHeight);
        }
    </script>
</body>
</html>
EOF

# --- Creando public/login.html ---
cat << 'EOF' > public/login.html
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Acceso al Panel - MKW Bot</title>
    <!-- Asegúrate de que la ruta a styles.css sea correcta -->
    <link rel="stylesheet" href="styles.css">
    <!-- Font Awesome para íconos -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">
</head>
<body class="login-page">

    <div class="login-container">
        <!-- Logo -->
        <div class="login-header">
            <!-- Usando el logo de tu archivo original -->
            <img src="https://m.ultrawifi.com.ar/admin/images/logo.png" alt="Logo de la Empresa">
        </div>

        <!-- Caja de Inicio de Sesión -->
        <div class="login-card">
            <h1>Acceso al Panel</h1>
            <p class="login-subtitle">Ingresa tus credenciales para continuar</p>
            
            <form action="/login" method="post">
                <div class="form-group">
                    <i class="fas fa-user icon"></i>
                    <input type="text" name="username" id="username" placeholder="Nombre de usuario" required>
                </div>
                <div class="form-group">
                    <i class="fas fa-lock icon"></i>
                    <input type="password" name="password" id="password" placeholder="Contraseña" required>
                </div>
                <div class="form-options">
                    <label class="remember-me">
                        <input type="checkbox" name="remember"> Recordarme
                    </label>
                </div>
                <button type="submit">Ingresar</button>
            </form>
        </div>
        
        <!-- Pie de Página -->
        <footer class="login-footer">
            <p>&copy; 2025 MKW Support. Todos los derechos reservados.</p>
        </footer>
    </div>

</body>
</html>
EOF

# --- Creando public/mkwap.html ---
cat << 'EOF' > public/mkwap.html
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MKW-AP - Panel de Control</title>
    <!-- Asegúrate de que la ruta a styles.css sea correcta -->
    <link rel="stylesheet" href="styles.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">
</head>
<body>
    <div class="panel-container">
        <header>
            <h1><b>MKW</b> WhatsApp Bot</h1>
            <a href="/logout">
                <i class="fas fa-sign-out-alt"></i>
                <span>Cerrar Sesión</span>
            </a>
        </header>
        
        <main>
            <div class="card card-full">
                <div class="card-header">
                    <span class="icon"><i class="fas fa-wifi"></i></span>
                    <h2>Estado del Bot</h2>
                </div>
                <p id="status-text" class="status-disconnected">Desconectado</p>
            </div>

            <div class="card card-full" id="qr-container">
                <div class="card-header">
                    <span class="icon"><i class="fas fa-qrcode"></i></span>
                    <h2>Código QR</h2>
                </div>
                <p>Escanea el código con tu WhatsApp para conectar el bot.</p>
                <img id="qr-image" src="" alt="Código QR aparecerá aquí">
            </div>

            <div class="card card-full actions-card">
                 <div class="card-header">
                    <span class="icon"><i class="fas fa-cogs"></i></span>
                    <h2>Acciones</h2>
                </div>
                <div class="button-group">
                    <button id="connect-btn"><i class="fas fa-play-circle"></i> Conectar</button>
                    <button id="disconnect-btn"><i class="fas fa-stop-circle"></i> Desconectar</button>
                </div>
            </div>

            <!-- He añadido la clase 'console-card' para un mejor control del estilo -->
            <div class="card card-full console-card">
                <div class="card-header">
                    <span class="icon"><i class="fas fa-terminal"></i></span>
                    <h2>Consola en Vivo</h2>
                </div>
                <!-- El iframe ahora se expandirá para llenar el espacio de la tarjeta -->
                <iframe id="log-iframe" src="console.html" class="log-viewer-iframe"></iframe>
            </div>
        </main>
    </div>

    <!-- Asegúrate de que la ruta a client.js sea correcta -->
    <script src="client.js"></script>
</body>
</html>
EOF

# --- Creando public/styles.css ---
cat << 'EOF' > public/styles.css
/* public/style.css - Rediseño Total v3.0 */
@import url('https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700&display=swap');
@import url('https://fonts.googleapis.com/css2?family=Fira+Code:wght@400;500&display=swap'); /* Fuente para la consola */

:root {
    --bg-color: #f4f6f9; /* Un gris más claro para el fondo */
    --primary-color: #3c8dbc;
    --secondary-color: #00c0ef;
    --font-color: #333;
    --card-bg: #ffffff;
    --shadow: 0 4px 15px rgba(0,0,0,0.07); /* Sombra un poco más suave */
    --border-color: #e9ecef;
    --green: #00a65a;
    --red: #dd4b39;
    --orange: #f39c12;
    --blue: #0073b7;
}

* {
    box-sizing: border-box;
}

html {
    height: 100%;
}

body {
    font-family: 'Roboto', sans-serif;
    background-color: var(--bg-color);
    color: var(--font-color);
    margin: 0;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
    height: 100%;
}

/* --- ESTILOS DEL PANEL PRINCIPAL --- */

.panel-container {
    width: 95%;
    margin: 20px auto;
    height: 100%;
    max-height: calc(100% - 40px);
    display: flex;
    flex-direction: column;
}

header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 15px 30px;
    background: var(--card-bg);
    border-radius: 8px;
    box-shadow: var(--shadow);
    margin-bottom: 25px;
    flex-shrink: 0;
}

header h1 {
    margin: 0;
    font-size: 1.5em;
    font-weight: 500;
}
header h1 b {
    font-weight: 700;
}
header a {
    display: flex;
    align-items: center;
    gap: 8px;
    color: var(--red);
    text-decoration: none;
    font-weight: 500;
    padding: 8px 15px;
    border-radius: 5px;
    transition: background-color 0.3s, color 0.3s;
}
header a:hover {
    background-color: var(--red);
    color: white;
}

main {
    display: grid;
    grid-template-columns: 1fr;
    grid-template-rows: auto auto auto 1fr;
    gap: 25px;
    flex-grow: 1;
    min-height: 0;
}

.card {
    background: var(--card-bg);
    padding: 25px;
    border-radius: 8px;
    box-shadow: var(--shadow);
}

.console-card {
    display: flex;
    flex-direction: column;
    padding-bottom: 15px;
}

.card-full {
    grid-column: 1 / -1;
}
.card-header {
    display: flex;
    align-items: center;
    gap: 15px;
    margin-bottom: 20px;
    padding-bottom: 15px;
    border-bottom: 1px solid var(--border-color);
}
.card-header .icon {
    font-size: 1.8em;
    color: var(--primary-color);
}
.card-header h2 {
    margin: 0;
    font-size: 1.2em;
    font-weight: 500;
}
#status-text {
    font-size: 2.5em;
    font-weight: 700;
    text-align: center;
    padding: 20px;
    border-radius: 5px;
    letter-spacing: 1px;
}
.status-CONECTADO { color: var(--green); }
.status-DESCONECTADO, .status-ERROR { color: var(--red); }
.status-INICIALIZANDO, .status-ESPERANDO_QR, .status-DESCONECTANDO { color: var(--orange); }
.status-SERVIDOR_REINICIANDO { color: var(--blue); }
#qr-container {
    text-align: center;
    display: none;
}
#qr-image {
    max-width: 100%;
    width: 280px;
    height: 280px;
    border: 5px solid var(--bg-color);
    padding: 10px;
    border-radius: 8px;
}
.actions-card .button-group {
    display: flex;
    gap: 20px;
}
.actions-card button {
    flex: 1;
    padding: 12px;
    border: none;
    border-radius: 5px;
    font-weight: 500;
    font-size: 16px;
    cursor: pointer;
    transition: transform 0.2s, box-shadow 0.3s;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}
.actions-card button:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 8px rgba(0,0,0,0.15);
}
#connect-btn { background: linear-gradient(45deg, var(--green), #29b472); color: white; }
#disconnect-btn { background: linear-gradient(45deg, var(--red), #e87a6d); color: white; }

.log-viewer-iframe {
    width: 100%;
    height: 100%;
    border: 1px solid #ddd;
    border-radius: 8px;
    box-shadow: inset 0 2px 5px rgba(0,0,0,0.1);
}

@media (max-width: 768px) {
    .panel-container {
        width: 100%;
        margin: 0;
        max-height: 100%;
        border-radius: 0;
    }
    header {
        flex-direction: column;
        gap: 15px;
        border-radius: 0;
    }
    main {
        padding: 15px;
        gap: 15px;
    }
}

/* --- ESTILOS PARA LA PÁGINA DE LOGIN --- */

.login-page {
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 100vh;
    padding: 20px;
}

.login-container {
    width: 100%;
    max-width: 420px;
    text-align: center;
}

.login-header {
    margin-bottom: 30px;
}

.login-header img {
    max-width: 180px;
    height: auto;
}

.login-card {
    background: var(--card-bg);
    padding: 40px;
    border-radius: 12px;
    box-shadow: var(--shadow);
    text-align: left;
}

.login-card h1 {
    font-size: 1.6em;
    font-weight: 500;
    margin-top: 0;
    margin-bottom: 10px;
    text-align: center;
    color: var(--font-color);
}

.login-subtitle {
    text-align: center;
    color: #888;
    margin-top: 0;
    margin-bottom: 30px;
}

.form-group {
    position: relative;
    margin-bottom: 20px;
}

.form-group .icon {
    position: absolute;
    left: 15px;
    top: 50%;
    transform: translateY(-50%);
    color: #ccc;
    transition: color 0.3s;
}

.form-group input:focus + .icon {
    color: var(--primary-color);
}

.form-group input[type="text"],
.form-group input[type="password"] {
    width: 100%;
    padding: 14px 15px 14px 45px; /* Padding izquierdo para el ícono */
    border: 1px solid var(--border-color);
    border-radius: 8px;
    font-size: 16px;
    background-color: #fdfdfd;
    transition: border-color 0.3s, box-shadow 0.3s;
}

.form-group input:focus {
    outline: none;
    border-color: var(--primary-color);
    box-shadow: 0 0 0 3px rgba(60, 141, 188, 0.2);
    background-color: #fff;
}

.form-options {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 30px;
    font-size: 14px;
}

.remember-me {
    display: flex;
    align-items: center;
    cursor: pointer;
    color: #666;
}

.remember-me input {
    margin-right: 8px;
    accent-color: var(--primary-color);
}

.login-card button {
    width: 100%;
    padding: 15px;
    border: none;
    border-radius: 8px;
    font-weight: 500;
    font-size: 16px;
    color: white;
    cursor: pointer;
    background: linear-gradient(45deg, var(--blue), var(--primary-color));
    transition: transform 0.2s, box-shadow 0.3s;
    box-shadow: 0 4px 12px rgba(0, 115, 183, 0.25);
    letter-spacing: 0.5px;
}

.login-card button:hover {
    transform: translateY(-3px);
    box-shadow: 0 6px 16px rgba(0, 115, 183, 0.35);
}

.login-footer {
    margin-top: 30px;
    font-size: 14px;
    color: #999;
}
EOF

    echo -e "${GREEN}Todos los archivos del proyecto han sido creados con éxito.${NC}\n"
}


# ==============================================================================
# == SECCIÓN 2: LÓGICA DE INSTALACIÓN ==========================================
# ==============================================================================

# --- Función para instalar Node.js v18 ---
install_nodejs() {
    echo -e "${YELLOW}---> Instalando Node.js v18...${NC}"
    apt-get update
    apt-get install -y curl ca-certificates gnupg
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$REQUIRED_NODE_VERSION.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
    apt-get update
    apt-get install -y nodejs
    echo -e "${GREEN}Node.js v18 instalado con éxito.${NC}"
}

# --- Inicio del Script de Instalación ---
echo -e "${BLUE}==================================================${NC}"
echo -e "${BLUE}== Iniciando la instalación de Bot-MKW          ==${NC}"
echo -e "${BLUE}==================================================${NC}\n"

# --- 0. Advertencia de Compatibilidad ---
echo -e "${YELLOW}AVISO:${NC} Este script está diseñado para funcionar en ${CYAN}Debian y Ubuntu${NC}."
echo -e "Puede que no funcione en otros sistemas operativos.\n"
sleep 2

# --- 1. Verificación de Permisos y Dependencias ---
echo -e "${YELLOW}---> Verificando permisos y dependencias del sistema...${NC}"

if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}Error: Este script debe ejecutarse como root o con sudo.${NC}"
  exit 1
fi

if command -v node &> /dev/null; then
    CURRENT_NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$CURRENT_NODE_VERSION" -ge "$REQUIRED_NODE_VERSION" ]; then
        echo -e "${GREEN}Node.js ya está instalado y la versión ($CURRENT_NODE_VERSION) es correcta.${NC}"
    else
        echo "La versión de Node.js ($CURRENT_NODE_VERSION) es demasiado antigua. Se requiere v$REQUIRED_NODE_VERSION+."
        install_nodejs
    fi
else
    echo "Node.js no está instalado."
    install_nodejs
fi

if ! command -v pm2 &> /dev/null; then
    echo "PM2 no está instalado. Instalando globalmente..."
    npm install pm2 -g
fi

echo -e "${GREEN}Dependencias básicas listas.${NC}\n"

# --- 2. Instalación de dependencias para Chromium ---
echo -e "${YELLOW}---> Instalando dependencias de sistema para el navegador del bot...${NC}"
apt-get update
apt-get install -y gconf-service libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 ca-certificates fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils wget
echo -e "${GREEN}Dependencias de sistema instaladas.${NC}\n"


# --- 3. Creación de archivos ---
create_project_files

# --- 4. Generación de Token de API ---
echo -e "${YELLOW}---> Generando y configurando un nuevo token de API seguro...${NC}"
NEW_API_TOKEN=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
sed -i "s/const API_TOKEN = '.*';/const API_TOKEN = '$NEW_API_TOKEN';/" "modules/mikrowispApi.js"
echo -e "${GREEN}Token generado y configurado con éxito.${NC}\n"

# --- 5. Instalación de Dependencias de Node ---
echo -e "${YELLOW}---> Instalando dependencias del proyecto (npm install)...${NC}"
npm install
echo ""

# --- 6. Configuración del Usuario del Panel ---
echo -e "${YELLOW}---> Configurando el archivo de usuarios (users.json)...${NC}"
read -p "Introduce el nombre de usuario para el panel de control: " admin_user
read -s -p "Introduce la contraseña para '$admin_user': " admin_pass
echo
JSON_CONTENT="{\n  \"$admin_user\": \"$admin_pass\"\n}"
echo -e "$JSON_CONTENT" > users.json
echo -e "${GREEN}¡Archivo 'users.json' creado con éxito!${NC}\n"

# --- 7. Iniciar la Aplicación con PM2 ---
echo -e "${YELLOW}---> Iniciando la aplicación con PM2...${NC}"
pm2 delete "$PM2_APP_NAME" &>/dev/null
pm2 start app.js --name "$PM2_APP_NAME"
pm2 save
echo ""

# --- 8. Configuración del Inicio Automático ---
echo -e "${YELLOW}---> Generando comando de inicio automático...${NC}"
echo -e "Para que el bot se inicie automáticamente si el servidor se reinicia,"
echo -e "ejecuta el siguiente comando que PM2 ha generado y sigue las instrucciones:"
pm2 startup
echo ""

# --- 9. Mensaje Final con Instrucciones ---
SERVER_IP=$(hostname -I | awk '{print $1}')

echo -e "${CYAN}======================================================================${NC}"
echo -e "${GREEN}            ✅ ¡INSTALACIÓN COMPLETADA! ✅            ${NC}"
echo -e "${CYAN}======================================================================${NC}"
echo ""
echo -e "➡️  **Panel de Control Web:**"
echo -e "    Puedes acceder al panel desde un navegador en: ${YELLOW}http://$SERVER_IP:6780${NC}"
echo ""
echo -e "➡️  **Instrucciones para configurar el Gateway en Mikrowisp:**"
echo -e "    Copia y pega los siguientes valores en la sección 'Gateway Genérico':"
echo ""
echo -e "    ${BLUE}URL Gateway:${NC}"
echo -e "    ${YELLOW}http://127.0.0.1:3000/send-message${NC}"
echo ""
echo -e "    ${BLUE}Parámetros:${NC}"
echo -e "    ${YELLOW}destinatario={{destinatario}}&mensaje={{mensaje}}${NC}"
echo ""
echo -e "    ${BLUE}Método:${NC}"
echo -e "    ${YELLOW}Envío GET${NC}"
echo ""
echo -e "    ${BLUE}Token Authorization Bearer:${NC}"
echo -e "    ${YELLOW}$NEW_API_TOKEN${NC}   <-- ¡Este es tu nuevo token!"
echo ""
echo -e "    ${BLUE}Límite Caracteres:${NC} ${YELLOW}2000${NC}"
echo -e "    ${BLUE}Pausa Entre Mensaje:${NC} ${YELLOW}5${NC}"
echo ""
echo -e "    Y no olvides marcar la opción **'Activar Gateway'**."
echo ""
echo -e "${CYAN}======================================================================${NC}"

