# Informe técnico y de verificación — ECOMMERCE

Fecha: 5 de noviembre de 2026 (America/Bogota).

**Estado: correcciones y comprobaciones locales completadas; aceptación funcional pendiente.** No se declara el proyecto terminado. La revisión visual Chrome y la integración Android requieren completar las verificaciones indicadas abajo. No se ha realizado push, creado PR, fusionado ni eliminado ramas.

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

Android: **0 cuerpos de prueba de integración ejecutados**. El primer `flutter test integration_test/... -d emulator-5554` terminó con **1 error de carga** por instalación fallida. Un intento posterior con `flutter drive` y binario precompilado tampoco consiguió instalar; sus tres reintentos automáticos no son tres pruebas. No se contabilizan como pruebas aprobadas.

## 7. Análisis y formato

`flutter pub get`: correcto. No se hizo una actualización masiva de dependencias.

`dart format --output=none --set-exit-if-changed lib test`: correcto. También se verificaron `integration_test` y `test_driver`.

`flutter analyze`: **sin incidencias**. `git diff --check`: correcto.

Entorno observado: Flutter 3.47.5, Dart 3.13.4, Windows 11. La ruta del SDK se llama `C:/Flutter 3.38.7`, pero la versión informada por la herramienta es 3.47.5.

## 8. Compilación web

`flutter build web`: correcta; salida `build/web`. También se lanzó `flutter run -d chrome --release --web-port 8351`. El lanzamiento y la compilación no constituyen una comprobación funcional visual. Web usa Hive/IndexedDB; no se confirmó persistencia tras recargar Chrome.

## 9. Compilación Android

`flutter build apk --debug`: correcta; salida `build/app/outputs/flutter-apk/app-debug.apk`.

El primer intento falló porque Flutter eligió Java 25.0.3, incompatible con Gradle 8.14. Se usó el JDK 21.0.8 instalado mediante un archivo de configuración Flutter dentro de `%TEMP%/ecommerce-flutter-config`, cambiando `APPDATA` solo para los procesos de compilación. No se modificó la configuración global. No fue necesario descargar JDK ni actualizar Gradle/Kotlin/AGP.

Flutter doctor también informó ausencia de cmdline-tools y estado desconocido de licencias Android; las compilaciones debug pudieron completarse con el SDK instalado.

No se validó APK release. La firma release del proyecto sigue siendo debug y está documentada como pendiente para distribución. Flutter advierte que dejará de soportar las versiones actuales de las herramientas Android en una versión futura.

## 10. Pruebas funcionales realizadas

Automatizadas con dependencias controladas: catálogo, filtros, detalle, regreso conservando filtro, agregado confirmado, navegación al carrito, incremento/decremento, totales, eliminación, vacío y diálogo de checkout. Ejercitadas a 320×640, 800×900, 1440×900 y texto al 200 % en 320×740. Se comprobó ausencia de excepciones de renderizado en esos escenarios.

HTTP controlado: catálogo vacío, detalle, precios enteros, HTTP 400/404/429/500/503, errores de conexión, timeouts de conexión/envío/recepción, JSON malformado y reintentos. Se verificaron respuestas concurrentes fuera de orden entre catálogo y detalle.

API pública: consulta puntual a `https://fakestoreapi.com/products`, HTTP 200 y 20 productos. No se usa esa API como dependencia de las pruebas. No se afirma haber navegado visualmente por ese catálogo en Chrome o Android.

## 11. Persistencia Hive comprobada

Las pruebas ejecutadas usan archivos reales en directorios temporales propios:

- Agregar, quitar, cambiar cantidades y vaciar por operación explícita.
- 40 agregados concurrentes al mismo producto: una fila con cantidad 40.
- Cierre y reapertura de la caja con el mismo adaptador y clave entera antigua 42; cantidad preservada y siguiente agregado acumulado en esa misma clave.
- Datos inválidos y duplicados preservados, con operaciones bloqueadas en vez de borrado silencioso.
- Errores de acceso a caja cerrada traducidos a fallo de caché y posterior recuperación.
- Archivo físicamente dañado: apertura rechazada y bytes idénticos antes y después, sin truncado automático.

Esto valida el origen local y su contrato en el host; no equivale a matar y reiniciar el proceso Android ni a recargar el navegador. Esas dos comprobaciones siguen pendientes.

## 12. Limitaciones pendientes y validación manual

1. Chrome: completar catálogo real, categorías, detalle, carrito, cantidades, total, reintento y recarga manteniendo el carrito. Computer Use se detuvo automáticamente porque no pudo identificar la URL del navegador con confianza suficiente para aplicar su política.
2. Android: liberar espacio por decisión del usuario o proporcionar un emulador/dispositivo con espacio. El existente tiene una partición de datos de 5.8 GB con 340 MB libres y rechazó el APK por falta de almacenamiento. No se borraron datos para conseguir espacio.
3. Un intento de emulador temporal falló por el límite de `partition-size` de esa versión. La ejecución de un intento corregido fue rechazada por la política automática (`blocked by policy`), sin motivo más específico. No se insistió en esa operación.
4. Ejecutar la integración incluida y comprobar además cierre forzado/reinicio Android con carrito persistido, y aspecto visual real en ambas plataformas.
5. CI remoto pendiente: el workflow solo existe localmente hasta autorizar push. No se afirma que sus jobs hayan pasado en GitHub.
6. Datos incompatibles o corruptos requieren recuperación explícita desde respaldo; se prioriza preservarlos. No se han supuesto formatos históricos no documentados.
7. Sin cobros, pedidos, backend propio, autenticación, inventario, impuestos, catálogo offline ni localización completa. Precios con símbolo `$`, sin conversión de moneda. El carrito no está cifrado y no guarda datos de pago.
8. La búsqueda por patrones no detectó claves privadas, AWS access keys, Google API keys o tokens GitHub en archivos versionados; tampoco hay archivos locales de firma/secretos versionados. Esta comprobación no sustituye un análisis especializado del historial ni prueba ausencia absoluta de secretos o vulnerabilidades de dependencias.

## 13. Archivos modificados o añadidos

- `.github/workflows/flutter.yml`
- `.gitignore`
- `README.md`
- `analysis_options.yaml`
- `android/app/src/main/AndroidManifest.xml`
- `android/gradle.properties`
- `docs/VERIFICATION_REPORT.md`
- `integration_test/shopping_flow_test.dart`
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

## 14. Commits creados

- `daaf30d` — `fix: serialize cart persistence and protect asynchronous state`
- `6b78c73` — `feat: improve responsive shopping flows and enable web builds`
- `18d9cb0` — `test: cover cart storage, request races and shopping flows`
- El commit de documentación que contiene este informe: `docs: document verified setup and remaining platform checks`. Su hash se obtiene con `git log --oneline origin/main..HEAD` y se entrega en el informe final del chat para no incluir una referencia circular al propio commit.

## 15. Estado final de la rama

Trabajo limitado a `improvement/flutter-ecommerce`, basada en `8625801`. `main` se dejó en el fast-forward sincronizado con el remoto consultado. No hay cambios en las ramas remotas, push, PR, merge ni eliminación de ramas. El cierre de entrega incluye comprobar que el árbol quede limpio después del commit de documentación.

## 16. Recomendación técnica

Los cambios están organizados para revisión de código y las comprobaciones locales de análisis, pruebas y compilación pasan. **No se recomienda marcar el proyecto terminado ni aprobar su fusión todavía.** Primero deben completarse las comprobaciones funcionales de Chrome y Android, incluyendo reinicio real y persistencia, y ejecutar CI en remoto cuando se autorice el push. Un PR puede servir para revisión cuando el usuario lo autorice, manteniendo visibles estas verificaciones pendientes.
