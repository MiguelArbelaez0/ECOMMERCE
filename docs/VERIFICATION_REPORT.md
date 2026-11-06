# Informe técnico y de verificación — ECOMMERCE

Fecha: 5 de noviembre de 2026 (America/Bogota).

**Estado: validación local completada en Chrome y Android, con persistencia comprobada.** El usuario autorizó publicar improvement/flutter-ecommerce y crear el PR después de pasar Android. CI remoto se comprobará tras publicar. La fusión y la eliminación de ramas continúan pendientes de autorización explícita. Este informe distingue pruebas automatizadas, revisión manual y compilaciones.

## 1. Estado inicial de Git

- Raíz Flutter y Git: `C:/Users/USUARIO/Desktop/DESARROLLO/01_FLUTTER/ECOMMERCE`, con `pubspec.yaml` en la raíz.
- Árbol limpio; rama local `main` en `bb5e5df`. No había modificaciones locales que preservar antes del trabajo.
- Remoto: `https://github.com/MiguelArbelaez0/ECOMMERCE.git`.
- El seguimiento local indicaba 8 commits pendientes. Tras `git fetch origin --prune`, se comprobaron 12 commits entre `bb5e5df` y `8625801`.
- `main` se actualizó mediante fast-forward a `8625801`, igual a `origin/main` en esa consulta. Se creó `improvement/flutter-ecommerce` desde ese punto.
- Ramas remotas inspeccionadas: `main`, `mejoras`, `codex/generate-complete-flutter-e-commerce-app` y `codex/organize-app-by-product-categories-and-fix-errors`. Las dos ramas `codex/...` son antecesoras de `origin/main`; sus cambios ya están integrados.

## 2. Commit exclusivo de mejoras

`origin/main..origin/mejoras` contiene únicamente `1838501` (`Merge pull request #4 from MiguelArbelaez0/main`). Sus padres son `9350ccd` y `395facb`. El diff respecto de su segundo padre está vacío; el diff desde la base común hasta `origin/mejoras` también está vacío. Es un merge de historial sin mejoras de contenido pendientes de rescatar. No se hizo cherry-pick ni se modificó esa rama.

## 3. Problemas detectados

| Área | Problema | Consecuencia |
|---|---|---|
| Carrito | Eventos de diferentes tipos concurrentes y recargas independientes | Estados antiguos podían ocultar cambios nuevos |
| Hive | Lecturas y escrituras sin cola y búsqueda de duplicados sin validación | Riesgo de duplicados/incrementos perdidos y cantidades inválidas |
| Importes | Suma directa de doubles multiplicados por cantidad | Acumulación de errores de representación monetaria |
| Inicio | Fallo de apertura Hive sin interfaz recuperable; recuperación automática por defecto | Inicio fallido o truncado automático de un archivo dañado |
| BLoC | Listas de estados mutables | Un consumidor podía modificar un estado ya emitido |
| Catálogo | Solicitudes sin control de antigüedad | Una respuesta vieja podía sobrescribir la última solicitud |
| HTTP/JSON | Mensajes que podían incluir cuerpos del servidor y JSON sin validación de valores | Errores poco claros y datos numéricos inválidos |
| Detalle | Confirmación antes de persistir e imágenes sin alternativa | Mensaje de éxito falso ante fallo de escritura |
| Carrito UI | Imágenes sin alternativa, controles rígidos y checkout sin acción | Errores visuales y acción incompleta |
| Diseño | Cuadrícula de dos columnas para cualquier ancho y retardo artificial del filtro | Escalado deficiente y espera innecesaria |
| Android | INTERNET ausente del manifiesto principal | La variante release no declaraba el acceso necesario |
| Web | No existía carpeta web | No era posible compilar web |
| QA/docs | Solo 3 pruebas; README con estructura incorrecta y estado no demostrado | Evidencia insuficiente de funcionamiento |

## 4. Correcciones implementadas y decisiones

- Un solo manejador de eventos del carrito usa `asyncExpand` para mantener el orden entre tipos. Tras cada escritura se espera la lectura persistida antes de publicar éxito.
- Las variaciones de cantidad son relativas al último estado cargado, evitando perder pulsaciones rápidas que comparten la misma cantidad visible.
- El origen Hive serializa también sus operaciones. Valida cantidades, precios, identificadores, títulos y duplicados antes de modificar datos. Cero elimina; valores negativos o mayores de 9999 se rechazan.
- Totales y subtotales usan centavos enteros: se redondea el precio unitario una vez antes de multiplicar.
- Se conservan nombre de caja, adaptador, campos y claves originales. No hay migraciones destructivas, eliminación automática ni reparación silenciosa de datos.
- La apertura desactiva `crashRecovery` para impedir truncados automáticos. Un contenedor de zona, limitado a esa apertura, contiene el error asíncrono duplicado del futuro interno de Hive 2.2.3; el consumidor recibe un único fallo. Se añadió un inicio con reintento y mensaje de preservación.
- GetIt registra la caja abierta con disposición incluso si todavía no fue consumida; cierra también Dio al reiniciar dependencias. Los proveedores siguen siendo dueños de sus BLoC.
- Versionado de solicitudes en productos: solo la última solicitud vigente puede emitir su resultado; se verifica también `emit.isDone`.
- Estados con copias no modificables de listas. JSON rechaza valores inválidos; errores HTTP muestran estado y reintento sin exponer el cuerpo recibido. Límites HTTP de 15 segundos para conexión, envío y recepción.
- Confirmación de agregado después de persistir y cargar el carrito. Su snackbar tiene un mensajero local al detalle para que no tape acciones al volver a otra pantalla.
- Cuadrícula adaptable, filtros sin retraso artificial, recuperación del filtro si su categoría desaparece, etiquetas accesibles, imágenes alternativas, subtotales y checkout explícitamente demostrativo.
- Soporte web, permiso INTERNET en Android y reglas adicionales para excluir credenciales y resultados temporales. Se conservaron Gradle, AGP y Kotlin. Flutter añadió las opciones de compatibilidad `android.builtInKotlin=false` y `android.newDsl=false` durante la compilación.
- Workflow con permisos de solo lectura y acciones fijadas a SHA para formato, análisis, pruebas y compilaciones. No se ha ejecutado en GitHub.

## 5. Arquitectura final

Se mantiene la estructura por funcionalidad (`products`, `cart`) y capas `presentation`, `domain`, `data`. Dominio conserva entidades, contratos y casos de uso sin Flutter, Hive ni Dio. Datos convierte modelos externos y traduce excepciones a fallos mediante los repositorios. Presentación consume casos de uso mediante BLoC y muestra estados recuperables. `core` reúne utilidades, HTTP y apertura segura; `injection` compone dependencias.

No se añadieron capas, servicios de pago ni abstracciones de infraestructura que el proyecto no necesite. El detalle usa el producto ya cargado en el catálogo; la operación remota por ID sigue disponible y está probada por separado.

## 6. Pruebas: resultados exactos

Última ejecución de `flutter test`: **38 aprobadas, 0 fallidas, 0 omitidas**.

| Grupo | Cantidad |
|---|---:|
| Pruebas existentes de modelo/caso de uso | 3 |
| Carrito, repositorio, casos de uso, BLoC y Hive real en directorios temporales | 11 |
| HTTP/JSON, repositorio, casos de uso, BLoC y concurrencia de productos | 19 |
| Widgets, navegación y tamaños de pantalla | 5 |
| Total | 38 |

Se detectaron y corrigieron fallos durante las iteraciones de desarrollo: errores duplicados internos de Hive al abrir archivos dañados, dependencia del contexto asíncrono en fixtures de widgets, desplazamiento necesario para tocar chips fuera de pantalla y snackbar que bloqueaba el checkout tras navegar. Las ejecuciones finales afectadas se repitieron y pasaron.

Android, resultados actuales: **3 comprobaciones aprobadas, 0 fallidas en las ejecuciones finales**:

1. `shopping_flow_test.dart`: flujo de compra completo y reapertura de Hive en el mismo proceso, 1 aprobada.
2. `process_restart_test.dart`, fase seed: guarda producto con cantidad 3 y total 59.97, 1 aprobada.
3. `process_restart_test.dart`, fase verify: recupera esos valores en una nueva ejecución después de cierre completo, 1 aprobada.

La validación usa el AVD independiente `EcommerceValidation`, Android 16/API 36, ID `emulator-5556`, con 4.9 GB libres inicialmente. Se conservaron los datos del AVD original `emulator-5554`, que tiene 340 MB libres. Para la prueba entre procesos se usó el identificador `run20261105_docs_2b3f002`, `--no-uninstall` y un subdirectorio exclusivo de documentos. Después de `am force-stop`, no existía PID de la app; el archivo `app_flutter/ecommerce_restart_run20261105_docs_2b3f002/cart_box.hive` seguía presente con 288 bytes. La fase verify comprobó en la interfaz producto, cantidad y total.

Incidentes anteriores: la primera sesión no llegó a ejecutar la integración por falta de espacio del AVD original. En esta sesión, una primera versión del nuevo fixture guardaba en `Directory.systemTemp`, resuelto como `code_cache`; Android borró ese caché al instalar el segundo APK y falló la fase verify (1 prueba). Se corrigió el fixture para usar documentos mediante path_provider, se exigió que el archivo existiera antes de verify y se repitieron ambas fases satisfactoriamente. No se atribuye ese fallo del fixture al carrito habitual de la aplicación.

## 7. Análisis y formato

`flutter pub get`: correcto. No se hizo una actualización masiva de dependencias.

`dart format --output=none --set-exit-if-changed lib test`: correcto. También se verificaron `integration_test` y `test_driver`.

`flutter analyze`: **sin incidencias**. `git diff --check`: correcto.

Entorno observado: Flutter 3.47.5, Dart 3.13.4, Windows 11. La ruta del SDK se llama `C:/Flutter 3.38.7`, pero la versión informada por la herramienta es 3.47.5.

## 8. Compilación web y Chrome

`flutter build web`: correcta, repetida en esta sesión; salida `build/web`.

Se ejecutó `flutter run -d chrome --web-port 8352`. Computer Use no pudo identificar con confianza la URL y detuvo la inspección automatizada. Se entregó al usuario la URL `http://localhost:8352` y una secuencia para catálogo real, categoría, detalle, agregado, incremento/decremento, subtotales/total, checkout, recarga y cierre/reapertura conservando cantidad 2.

El usuario confirmó textualmente **“SIN NINGUN FALLO”** a esa secuencia. Se registra como **validación manual por el autor**, no como inspección visual independiente del agente. Incluye persistencia web al recargar y reabrir según la comprobación solicitada; no se deduce de una compilación.

## 9. Compilación Android

`flutter build apk --debug`: correcta; salida `build/app/outputs/flutter-apk/app-debug.apk`.

El primer intento falló porque Flutter eligió Java 25.0.3, incompatible con Gradle 8.14. Se usó el JDK 21.0.8 instalado mediante un archivo de configuración Flutter dentro de `%TEMP%/ecommerce-flutter-config`, cambiando `APPDATA` solo para los procesos de compilación. No se modificó la configuración global. No fue necesario descargar JDK ni actualizar Gradle/Kotlin/AGP.

Flutter doctor también informó ausencia de cmdline-tools y estado desconocido de licencias Android; las compilaciones debug pudieron completarse con el SDK instalado.

Se repitió además la compilación debug en esta sesión y se instalaron los APK de integración en el AVD temporal.

No se validó APK release. La firma release del proyecto sigue siendo debug y está documentada como pendiente para distribución. Flutter advierte que dejará de soportar las versiones actuales de las herramientas Android en una versión futura.

## 10. Pruebas funcionales realizadas

Automatizadas con dependencias controladas: catálogo, filtros, detalle, regreso conservando filtro, agregado confirmado, navegación al carrito, incremento/decremento, totales, eliminación, vacío y diálogo de checkout. Ejercitadas a 320×640, 800×900, 1440×900 y texto al 200 % en 320×740. Se comprobó ausencia de excepciones de renderizado en esos escenarios.

HTTP controlado: catálogo vacío, detalle, precios enteros, HTTP 400/404/429/500/503, errores de conexión, timeouts de conexión/envío/recepción, JSON malformado y reintentos. Se verificaron respuestas concurrentes fuera de orden entre catálogo y detalle.

API pública: consulta puntual a `https://fakestoreapi.com/products`, HTTP 200 y 20 productos. No se usa esa API como dependencia de las pruebas. La navegación de Chrome con ese catálogo fue confirmada manualmente por el usuario. Android se ejercitó de forma automatizada con catálogo controlado y también mediante la aplicación normal con catálogo real. El usuario confirmó el flujo manual con “FUNCIONA CORECTAMETNE TODO”.

## 11. Persistencia Hive comprobada

Las pruebas ejecutadas usan archivos reales en directorios temporales propios:

- Agregar, quitar, cambiar cantidades y vaciar por operación explícita.
- 40 agregados concurrentes al mismo producto: una fila con cantidad 40.
- Cierre y reapertura de la caja con el mismo adaptador y clave entera antigua 42; cantidad preservada y siguiente agregado acumulado en esa misma clave.
- Datos inválidos y duplicados preservados, con operaciones bloqueadas en vez de borrado silencioso.
- Errores de acceso a caja cerrada traducidos a fallo de caché y posterior recuperación.
- Archivo físicamente dañado: apertura rechazada y bytes idénticos antes y después, sin truncado automático.

Además de las pruebas del host, se ejecutaron las dos fases Android descritas en la sección 6 con el mismo esquema de Hive y almacenamiento bajo documentos, en procesos separados. El directorio pertenece solo a la prueba y no al carrito habitual. La recarga/reapertura de Chrome fue confirmada por el usuario. También se comprobó el carrito habitual de la aplicación Android, sin sustituir datos ni usar la ruta del fixture: el usuario agregó un producto real. Se extrajeron copias de solo lectura de `app_flutter/cart_box.hive` y se decodificaron en memoria con el mismo adaptador. Antes y después de `am force-stop` y `am start` contenían producto ID 1, cantidad 1, subtotal y total 10995 centavos (109.95). El PID anterior era 4095, quedó ausente al cerrar y el nuevo proceso fue 4343. El usuario confirmó en pantalla: “EL CARRITO LO PERSISTE AHI SIGUE”. Las copias se conservaron fuera del repositorio; no se modificó el almacenamiento para realizar la comprobación.

Una primera consulta manual se hizo con carrito vacío; por eso no se contabilizó como evidencia de persistencia de productos y se repitió con datos.

## 12. Limitaciones pendientes y procedimiento

1. Chrome y Android: los flujos con datos reales fueron confirmados manualmente por el autor. El agente ejecutó las pruebas y comprobó el contenido persistido, pero no completó una inspección visual independiente mediante Computer Use. La evidencia manual se atribuye expresamente al usuario.
2. CI de GitHub pendiente de ejecución tras la publicación ya autorizada. El workflow tiene permisos de solo lectura, acciones fijadas a SHA, Flutter 3.47.5 y JDK 21. La etiqueta Flutter 3.47.5 existe en el repositorio oficial y coincide con el SDK local. No se afirma que el workflow haya pasado en remoto.
3. El AVD original conserva todos sus datos y sigue corto de espacio. Se creó un AVD temporal independiente copiando solo la configuración y usando imágenes nuevas; no se borró ningún AVD ni se desinstalaron apps del usuario para conseguir espacio.
4. Computer Use se detuvo por su control de identificación de URL; no se insistió con otra vía de interacción del navegador. El flujo Chrome se validó manualmente con el usuario.
5. Hay instrucciones reproducibles en `docs/PLATFORM_VALIDATION.md`, tanto para las comprobaciones manuales como para las dos fases de reinicio Android. Usar IDs de dispositivo explícitos y conservar instalada la aplicación entre seed y verify.
6. Se mantienen las limitaciones funcionales de la demo: sin pagos/pedidos reales, autenticación, inventario, impuestos, catálogo offline ni localización completa. El carrito no está cifrado y no guarda información de pago.
7. Datos corruptos/incompatibles se preservan y requieren recuperación explícita desde respaldo. No se han supuesto formatos históricos no documentados.
8. La búsqueda por patrones no detectó claves privadas, AWS access keys, Google API keys o tokens GitHub en archivos versionados; no hay archivos locales de firma/secretos versionados. No equivale a un análisis especializado del historial o de vulnerabilidades de dependencias.

## 13. Archivos modificados o añadidos

- `.github/workflows/flutter.yml`
- `.gitignore`
- `README.md`
- `analysis_options.yaml`
- `android/app/src/main/AndroidManifest.xml`
- `android/gradle.properties`
- `docs/VERIFICATION_REPORT.md`
- `docs/PLATFORM_VALIDATION.md`
- `integration_test/shopping_flow_test.dart`
- `integration_test/process_restart_test.dart`
- `lib/core/network/api_client.dart`
- `lib/core/storage/open_box.dart`
- `lib/features/cart/data/datasources/cart_local_data_source.dart`
- `lib/features/cart/domain/entities/cart_item.dart`
- `lib/features/cart/presentation/bloc/cart_bloc.dart`
- `lib/features/cart/presentation/bloc/cart_event.dart`
- `lib/features/cart/presentation/bloc/cart_state.dart`
- `lib/features/cart/presentation/pages/cart_page.dart`
- `lib/features/cart/presentation/widgets/cart_item_tile.dart`
- `lib/features/products/data/datasources/product_remote_data_source.dart`
- `lib/features/products/data/models/product_model.dart`
- `lib/features/products/presentation/bloc/product_bloc.dart`
- `lib/features/products/presentation/bloc/product_state.dart`
- `lib/features/products/presentation/pages/product_detail_page.dart`
- `lib/features/products/presentation/pages/products_page.dart`
- `lib/features/products/presentation/widgets/product_card.dart`
- `lib/injection/injection_container.dart`
- `lib/main.dart`
- `pubspec.lock`
- `pubspec.yaml`
- `test/cart_test.dart`
- `test/products_test.dart`
- `test/support/fixtures.dart`
- `test/widgets_test.dart`
- `test_driver/integration_test.dart`
- `web/favicon.png`
- `web/icons/Icon-192.png`
- `web/icons/Icon-512.png`
- `web/icons/Icon-maskable-192.png`
- `web/icons/Icon-maskable-512.png`
- `web/index.html`
- `web/manifest.json`

## 14. Commits y cambios de seguimiento

Commits originales: `daaf30d` (persistencia y estados), `6b78c73` (interfaz/web), `18d9cb0` (pruebas/CI), `ee76d80` (documentación).

El seguimiento añade una prueba de persistencia entre procesos Android, declara path_provider como dependencia directa de desarrollo sin cambiar su versión resuelta, y actualiza resultados y procedimientos. Los hashes definitivos se consultan con `git log --oneline main..improvement/flutter-ecommerce` antes de la fusión.

Nuevo commit de pruebas: `d73aba8` — `test: verify Hive persistence across Android processes`.

No se introdujeron cambios adicionales de lógica de producción en esta revisión: la nueva evidencia procede de ejecutar las rutas existentes en Android y validar Chrome con el usuario.

## 15. Revisión de ramas y condiciones de integración

Base de entrega: `8625801`. La rama de trabajo es `improvement/flutter-ecommerce`; main y origin/main continúan sincronizadas con esa base en la última consulta.

`git ls-remote --heads origin` y el conector GitHub confirman cuatro ramas remotas: main, mejoras y las dos codex. Ambas codex son antecesoras de main. `1838501` de mejoras es el único nodo exclusivo: `git diff origin/main...origin/mejoras` y el diff respecto de su segundo padre están vacíos; es descartable por contenido, no una mejora perdida.

El usuario autorizó publicar la rama y crear el PR después de pasar Android. La secuencia es publicar, crear/revisar el PR, comprobar CI del commit propuesto y solicitar autorización explícita para fusionar. La eliminación de ramas requiere autorización y comprobación posterior a la fusión. No se ha efectuado ninguna de esas mutaciones remotas en este punto. El resultado Git definitivo se comprueba mediante status, log, branch -a y listado de GitHub, no se presupone en el informe.

## 16. Recomendación técnica

Formato, análisis, 38 pruebas unitarias/widgets y compilaciones web/APK pasan. El flujo de Chrome fue confirmado sin fallos por el usuario y las 3 comprobaciones Android controladas pasan, incluida persistencia entre procesos.

Android con datos reales y persistencia habitual ya fueron confirmados. La rama está preparada para publicación y PR con autorización concedida. Antes de fusionar deben pasar los controles de CI del commit propuesto y obtenerse autorización explícita; la limpieza también requiere autorización. No se declara aún alcanzado el estado final de una sola rama main.
