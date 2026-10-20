# Privacy Policy · Política de privacidad

**Lumio** · app id `app.lumio.player` · Last updated / Última actualización: 2026-10-20

[English](#english) · [Español](#español)

---

## English

Lumio is an IPTV player. It does **not** provide any channels, playlists or content: you add your own source (an M3U URL, a local file or an Xtream Codes account).

**We do not collect your data.** Lumio has no accounts, no analytics, no advertising, no crash reporting and no servers of its own. We (the developer) never receive any information about you or what you watch.

### What is stored on your device
- **Your source** (playlist URL, file path or Xtream server, username and password). Credentials are kept in the operating system's encrypted storage (Android Keystore / Keychain / libsecret) and are never written to logs.
- **Your library**: favorites, recently watched channels and playback progress, in a local file. You can move it to another device with a code that you copy yourself.
- **Settings**: the language you choose.
- **Caches** to start faster: downloaded playlists and channel/poster images.

Everything stays on your device. Deleting the source in *Settings* removes it; uninstalling the app removes the rest.

### Network connections
Lumio only connects to servers **you** configure (your IPTV provider) and to the image addresses contained in your lists. Your provider will see your IP address and what you watch, under its own privacy policy. The app can use cleartext `http` because many IPTV providers do not offer `https`.

If you use **Chromecast**, Lumio looks for Cast devices on your local network and sends them the address of the stream you chose.

### Permissions
Internet and network state (to play streams); local network / multicast (to find Chromecast devices). No location, contacts, camera, microphone or storage-wide access.

### Children
Lumio is not directed at children and collects no data from anyone.

### Changes and contact
If this policy changes, the new version will be published in this file with a new date. Questions: open an issue at <https://github.com/xrndev/lumio-iptv-app/issues>.

---

## Español

Lumio es un reproductor IPTV. **No** ofrece canales, listas ni contenido: tú añades tu propia fuente (una URL M3U, un archivo local o una cuenta Xtream Codes).

**No recopilamos tus datos.** Lumio no tiene cuentas, ni analítica, ni publicidad, ni informes de fallos, ni servidores propios. Nosotros (el desarrollador) nunca recibimos información sobre ti ni sobre lo que ves.

### Qué se guarda en tu dispositivo
- **Tu fuente** (URL de la lista, ruta del archivo o servidor, usuario y contraseña de Xtream). Las credenciales se guardan en el almacenamiento cifrado del sistema (Android Keystore / Llavero / libsecret) y nunca se escriben en registros.
- **Tu biblioteca**: favoritos, canales vistos recientemente y progreso de reproducción, en un archivo local. Puedes pasarla a otro dispositivo con un código que copias tú.
- **Ajustes**: el idioma que elijas.
- **Cachés** para arrancar más rápido: listas descargadas e imágenes de canales y pósteres.

Todo se queda en tu dispositivo. Al eliminar la fuente en *Ajustes* se borra; al desinstalar la app se borra el resto.

### Conexiones de red
Lumio solo se conecta a los servidores que **tú** configuras (tu proveedor IPTV) y a las direcciones de imágenes que contienen tus listas. Tu proveedor verá tu dirección IP y lo que ves, según su propia política de privacidad. La app admite `http` sin cifrar porque muchos proveedores IPTV no ofrecen `https`.

Si usas **Chromecast**, Lumio busca dispositivos Cast en tu red local y les envía la dirección del contenido que elijas.

### Permisos
Internet y estado de red (para reproducir); red local / multicast (para encontrar Chromecast). No se usa ubicación, contactos, cámara, micrófono ni acceso general al almacenamiento.

### Menores
Lumio no está dirigida a menores y no recopila datos de nadie.

### Cambios y contacto
Si esta política cambia, la nueva versión se publicará en este archivo con nueva fecha. Dudas: abre un *issue* en <https://github.com/xrndev/lumio-iptv-app/issues>.
