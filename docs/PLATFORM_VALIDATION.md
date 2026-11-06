# Validación funcional reproducible

Las compilaciones, las pruebas automatizadas y las comprobaciones visuales se registran por separado en `VERIFICATION_REPORT.md`.

## Chrome con datos reales

1. Ejecutar `flutter run -d chrome --web-port 8352`.
2. Abrir `http://localhost:8352` y comprobar catálogo, categorías, detalle e imágenes.
3. Agregar dos productos distintos. Confirmar el agregado, incrementar y disminuir cantidades, comprobar cada subtotal y la suma total.
4. Eliminar un producto y abrir el checkout. Debe explicar que no cobra ni crea pedidos.
5. Dejar un producto con cantidad 2, recargar y comprobar que el carrito se conserva.
6. Cerrar la ventana y reabrir la misma URL usando el mismo perfil, puerto y origen. Confirmar producto, cantidad y total.
7. Comprobar los mensajes de error y el botón Retry cuando falle la conexión; restablecer la conexión y reintentar.

La persistencia web pertenece al origen y al perfil del navegador. Cambiar el puerto o usar un perfil temporal nuevo no recupera los datos del perfil anterior. No borrar datos del sitio como parte de esta validación.

## Android con datos reales

Requisitos: dispositivo conectado o AVD con espacio suficiente, SDK y JDK compatibles. Identificar el destino mediante `flutter devices` y usar siempre su ID explícito si hay varios emuladores.

Si la instalación informa falta de espacio, revisar `adb -s <device-id> shell df -h /data`. Crear un AVD nuevo con almacenamiento suficiente en Android Studio es una alternativa que conserva el anterior; no usar Wipe Data, desinstalar aplicaciones ajenas ni borrar AVD existentes para esta prueba.

1. Ejecutar `flutter run -d <device-id>` con el destino preparado.
2. Comprobar catálogo real, categorías, detalle, imágenes y navegación.
3. Agregar dos productos; incrementar y disminuir, revisar subtotales y total; eliminar uno.
4. Abrir el checkout y confirmar que es una demostración. Dejar el otro producto con cantidad 2.
5. Cerrar completamente el proceso: `adb -s <device-id> shell am force-stop com.example.ecommerce_clean_app`.
6. Reabrir desde el icono o ejecutar `adb -s <device-id> shell am start -n com.example.ecommerce_clean_app/.MainActivity`.
7. Revisar que producto, cantidad y total sean iguales. No desinstalar ni limpiar datos entre el cierre y la reapertura.

En Windows, si adb no está en PATH, se puede ejecutar desde `$env:LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe`. La firma incluida es debug; estas instrucciones corresponden a la demostración de desarrollo.

## Integración Android controlada

```bash
flutter test integration_test/shopping_flow_test.dart -d <device-id> --no-uninstall
```

Comprueba el flujo de compra y reapertura de Hive dentro de un mismo proceso con HTTP simulado y directorio temporal. No requiere disponibilidad de Fake Store API.

Para comprobar persistencia entre dos procesos Android, ejecutar las dos fases con el mismo identificador único. Ejemplo en PowerShell:

```powershell
$validationRunId = [guid]::NewGuid().ToString('N')
$validationDevice = 'emulator-5556' # Sustituir por el ID de flutter devices.
flutter test integration_test/process_restart_test.dart -d $validationDevice --no-uninstall --dart-define=PERSISTENCE_RUN_ID=$validationRunId --dart-define=PERSISTENCE_PHASE=seed
if ($LASTEXITCODE -ne 0) { throw 'Falló la preparación del carrito' }
& "$env:LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe" -s $validationDevice shell am force-stop com.example.ecommerce_clean_app
flutter test integration_test/process_restart_test.dart -d $validationDevice --no-uninstall --dart-define=PERSISTENCE_RUN_ID=$validationRunId --dart-define=PERSISTENCE_PHASE=verify
if ($LASTEXITCODE -ne 0) { throw 'Falló la recuperación del carrito' }
```

La fase seed agrega un producto de 19.99 y aumenta la cantidad a 3. La fase verify, en otra ejecución de la aplicación, debe encontrar cantidad 3 y total 59.97. Ambas fases usan un subdirectorio de documentos exclusivo del identificador y no el carrito habitual del usuario. Conservar la aplicación instalada entre ambas fases; un identificador nuevo es obligatorio para repetir seed.

`process_restart_test.dart` requiere esas definiciones; no debe ejecutarse sin ellas ni confundirse con la validación manual del almacenamiento habitual y la API real. Las pruebas se invocan por archivo como muestran estos comandos.

## CI y fusión

El workflow verifica formato, análisis, pruebas unitarias/widgets y compilaciones web/APK. Las integraciones Android anteriores se ejecutan en un dispositivo por separado. Tras autorizar la publicación, comprobar los jobs del commit exacto del PR; no considerar un YAML o una ejecución antigua como evidencia del commit actual.

Solo después de autorizar la fusión, actualizar main y verificar la integración de cada rama antes de eliminarla. El merge 1838501 de mejoras no aporta un árbol distinto de su segundo padre; las dos ramas codex ya son antecesoras de main.
