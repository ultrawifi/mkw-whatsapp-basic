Bot-MKW Pro: Gateway de WhatsApp para Mikrowisp
Bot-MKW Pro es una solución integral que conecta tu sistema de gestión Mikrowisp con WhatsApp, permitiéndote enviar notificaciones automáticas a tus clientes. Incluye un panel de control web para monitorear y gestionar el estado del bot en tiempo real.

🚀 Características Principales
API Segura: Un endpoint protegido por token para que Mikrowisp envíe mensajes de forma segura.

Panel de Control Web: Interfaz gráfica para iniciar sesión, monitorear el estado del bot, escanear el código QR y ver una consola de logs en vivo.

Instalación Automatizada: Un script install.sh que configura todo el entorno, genera un token único y lanza la aplicación.

Gestión de Procesos con PM2: Asegura que el bot se mantenga siempre en línea y se reinicie automáticamente si falla.

Comunicación en Tiempo Real: Usa WebSockets para una actualización instantánea del estado en el panel web.

📋 Requisitos Previos
Para instalar y ejecutar este bot, tu servidor (preferiblemente un VPS con Debian o Ubuntu) necesita tener lo siguiente:

Acceso root o un usuario con privilegios sudo.

Node.js (versión 18 o superior).

npm (generalmente se instala con Node.js).

PM2 (gestor de procesos para Node.js).

unzip para descomprimir el proyecto.

Nota: El script de instalación intentará instalar estas dependencias automáticamente si no las encuentra.

⚙️ Instalación (Método Rápido)
La instalación es sencilla. Simplemente clona este repositorio o descarga el script install.sh y ejecútalo con permisos de superusuario.

Conéctate a tu servidor por SSH.

Ejecuta el siguiente comando:

wget -O install.sh [https://raw.githubusercontent.com/ultrawifi/mkw-whatsapp-basic/main/install.sh](https://raw.githubusercontent.com/ultrawifi/mkw-whatsapp-basic/main/install.sh) && chmod +x install.sh && ./install.sh

El script se encargará de todo:

Generará un token de API único y seguro.

Descargará la última versión del bot.

Instalará las dependencias.

Te pedirá que crees un usuario y contraseña para el panel.

Iniciará el bot con PM2.

Al finalizar, el script te mostrará toda la información necesaria para configurar el Gateway en Mikrowisp.

🛠️ Configuración en Mikrowisp
Una vez finalizada la instalación, el script te proporcionará los datos para configurar el Gateway Genérico en Mikrowisp.

Ve a Mikrowisp -> Gateways SMS -> Agregar.

Rellena los campos con la información que te dio el script al final de la instalación:

URL Gateway: http://12-7.0.0.1:3000/send-message

Parámetros: destinatario={{destinatario}}&mensaje={{mensaje}}

Método: Envío GET

Token Authorization Bearer: Pega aquí el token único que generó el script

Límite Caracteres: 2000

Pausa Entre Mensaje: 5

Marca la opción "Activar Gateway" y guarda.

🖥️ Uso del Panel de Control
Accede al Panel: Abre tu navegador y ve a la dirección que te proporcionó el script de instalación (ej: http://TU_IP_DEL_SERVIDOR:6780).

Inicia Sesión: Usa el usuario y contraseña que creaste durante la instalación.

Conecta el Bot:

La primera vez, el estado será "DESCONECTADO".

Haz clic en el botón "Conectar".

Aparecerá un código QR. Escanéalo con la aplicación de WhatsApp desde el teléfono que funcionará como bot.

¡Listo! Una vez escaneado, el estado cambiará a "CONECTADO" y el sistema estará operativo.

Desde el panel podrás ver los logs en tiempo real, el estado de la conexión y desconectar el bot si es necesario.# mkw-whatsapp-basic
