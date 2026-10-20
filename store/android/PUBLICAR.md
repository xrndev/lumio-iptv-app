# Publicar Lumio en Google Play

Qué deja preparado el repositorio y qué tienes que hacer tú (cuenta, formularios, subida).
**Nada de esto se ha subido a Google**: lo decides tú en cada paso.

## Ya preparado en el repo

| Pieza | Dónde |
|---|---|
| Firma de release con clave de subida (`android/key.properties`, ignorado por git) | `android/app/build.gradle.kts` |
| AAB firmado en CI (si existen los secretos) | `.github/workflows/release.yml` → artefacto `android-aab` |
| Política de privacidad (es/en) | `PRIVACY.md` |
| Textos de la ficha (es/en) y datos generales | `store/android/listing.md` |
| Icono 512×512, gráfico de funciones 1024×500 | `store/android/icon-512.png`, `feature-graphic.png` |
| Capturas teléfono 1080×1920 y horizontales 1920×1080, es/en, con contenido ficticio | `store/android/screenshots/` |
| Banner de Android TV 1280×720 | `assets/branding/lumio_banner_1280.png` |
| Lista de prueba para los revisores de Google | `store/android/review-playlist.m3u` |
| Requisitos técnicos verificados | `targetSdk 36` · librerías nativas alineadas a 16 KB · ABIs arm64, armeabi-v7a y x86_64 |

Regenerar capturas: `LUMIO_SHOTS_LOCALE=es|en flutter test integration_test/store_shots_test.dart -d windows`
(con `LUMIO_SHOTS_DIR` para elegir la carpeta).

## 1. Clave de subida (una vez) — ¡haz copia de seguridad!

La clave está en `~/.lumio-keys/lumio-upload.p12` y su contraseña en `android/key.properties`
(ambos fuera de git). **Guarda una copia de los dos en un sitio seguro** (gestor de contraseñas).
Si la pierdes puedes pedir a Google que la restablezca, pero es un trámite lento.

Si la quieres en CI, crea los secretos del repositorio (Settings → Secrets and variables → Actions):

```bash
base64 -w0 ~/.lumio-keys/lumio-upload.p12 | gh secret set ANDROID_KEYSTORE_BASE64
grep storePassword android/key.properties | cut -d= -f2- | gh secret set ANDROID_KEYSTORE_PASSWORD
```

Sin secretos el workflow sigue funcionando, pero firma el APK con la clave de depuración y no genera AAB.

## 2. Cuenta de Play Console

- Alta en <https://play.google.com/console> (pago único de 25 USD) y verificación de identidad.
- **Cuentas personales nuevas**: antes de pedir producción, Google exige una **prueba cerrada con al menos
  12 testers durante 14 días seguidos**. Las cuentas de organización (con D-U-N-S) no lo necesitan.

## 3. Generar el AAB

```bash
# en local (usa android/key.properties)
flutter build appbundle --release        # → build/app/outputs/bundle/release/app-release.aab
```
o en GitHub: Actions → Release → Run workflow → artefacto `android-aab`.

Cada subida necesita un `versionCode` mayor: sube el número tras el `+` en `pubspec.yaml`
(`version: 0.1.0+2`).

## 4. Crear la app y rellenar la Consola

1. **Crear app**: nombre `Lumio: IPTV Player`, español (España), *App*, *Gratuita*
   (una app gratuita no puede pasar a ser de pago después).
2. **Ficha principal**: copia los textos de `listing.md` (es-ES y en-US), sube icono, gráfico y capturas.
   Para la sección de **Android TV** sube las capturas `wide_*` y el banner.
3. **Política de privacidad**: `https://github.com/xrndev/lumio-iptv-app/blob/main/PRIVACY.md`
4. **Acceso a la aplicación** → "Hay funciones restringidas" e indica a los revisores:
   > Lumio no incluye contenido. Para probarla: Ajustes → Añadir fuente → pestaña "URL M3U" y pega
   > `https://raw.githubusercontent.com/xrndev/lumio-iptv-app/main/store/android/review-playlist.m3u`
   > (streams de demostración públicos). Después abre cualquier canal de la lista.

   (Esa URL funciona cuando esta rama esté fusionada en `main`.) **No** des tu cuenta Xtream personal.
5. **Anuncios**: No contiene anuncios.
6. **Clasificación de contenido** (cuestionario IARC): la app no genera contenido, pero reproduce lo que
   el usuario añade desde internet; responde con honestidad a las preguntas sobre contenido de
   terceros/acceso a internet sin restricciones.
7. **Público objetivo**: 18+ (no dirigida a niños, así evitas la política de Familias).
8. **Seguridad de los datos**: *No recopila ni comparte datos de usuario* (las credenciales se
   guardan cifradas solo en el dispositivo y nunca se envían a nosotros). Coherente con `PRIVACY.md`.
9. **Categoría**: Reproductores y editores de vídeo. Contacto: tu correo (es público).
10. **Android TV**: marca la app como compatible con TV (ya declara `leanback` y banner).

## 5. Subir y probar

1. **Pruebas → Prueba interna** → crear versión → sube el AAB → añade tu correo como tester → instala
   desde el enlace de Play y comprueba arranque, añadir la lista de demostración y reproducir.
2. Cuenta personal nueva: **Prueba cerrada** con 12+ testers 14 días → después *Solicitar acceso a producción*.
3. **Producción** → enviar a revisión (suele tardar de unas horas a varios días).

**Play App Signing**: acepta la opción por defecto. Google guarda la clave de firma final y la tuya
solo sirve para subir. Consecuencia: el APK de GitHub (firmado con la clave de subida) y la app de Play
tienen firmas distintas; no se pueden actualizar una sobre otra (hay que desinstalar).

## Cosas a vigilar con las apps IPTV

- No menciones canales, deportes de pago ni "TV gratis" en la ficha o capturas, y no uses marcas ni logos
  de terceros (por eso las capturas son ficticias).
- Aclara siempre que **no se incluye contenido** (ya está en la descripción).
- El tráfico `http` sin cifrar está permitido (`usesCleartextTraffic`) porque muchos proveedores no
  ofrecen `https`; está documentado en la política de privacidad.
- Si Google rechaza la app por "propiedad intelectual", responde explicando que es un reproductor
  genérico sin contenido, con la lista de demostración legal.
- El `applicationId` (`app.lumio.player`) es **definitivo** tras la primera subida.
