# E-Commerce Flutter

Aplicación de demostración con catálogo REST, filtros por categoría y carrito persistente. Construida con Flutter, Dart, BLoC, Dio, Hive y GetIt. El checkout explica el alcance de la demo: no procesa pagos ni crea pedidos.

## Funcionalidades

- Catálogo de Fake Store API con título, precio, imagen, descripción y categoría.
- Filtros locales por categoría y navegación al detalle sin perder el filtro.
- Estados de carga, catálogo vacío, errores de conexión/HTTP y reintento manual.
- Protección frente a respuestas HTTP antiguas que llegan fuera de orden.
- Carrito con agregados acumulativos, eliminación, cantidades y subtotales.
- Totales calculados en centavos; cantidades entre 1 y 9999. Al disminuir a cero se elimina el producto.
- Persistencia Hive entre sesiones y mensajes de error con reintento.
- Cuadrícula adaptable, alternativas para imágenes fallidas y etiquetas accesibles en acciones.

## Arquitectura

La aplicación se organiza por funcionalidad y capas. Presentación usa BLoC y casos de uso; dominio define entidades y contratos de repositorio sin depender de Flutter, Dio o Hive. Datos implementa esos contratos y convierte modelos externos a entidades. GetIt compone las dependencias; los proveedores de Flutter cierran los BLoC que crean.

```text
lib/
├── core/                       # Errores, Either, cliente HTTP y apertura Hive
├── features/
│   ├── products/
│   │   ├── data/               # Dio, JSON e implementación del repositorio
│   │   ├── domain/             # Product, contratos y casos de uso
│   │   └── presentation/       # BLoC, catálogo, detalle y tarjetas
│   └── cart/
│       ├── data/               # Hive, adaptador y repositorio
│       ├── domain/             # CartItem, contratos y casos de uso
│       └── presentation/       # BLoC, carrito y controles
├── injection/                  # Registro de dependencias
└── main.dart                   # Inicio recuperable y aplicación
test/                           # Pruebas unitarias y de widgets
integration_test/               # Flujo Android con HTTP controlado
web/                            # Configuración de Flutter web
android/                        # Proyecto Android
```

Los eventos del carrito se procesan en orden y el origen local también serializa sus operaciones. El esquema original de Hive (`cart_box`, adaptador 0, campos 0–4) se mantiene. Una fila inválida o duplicada bloquea las modificaciones para preservar los datos. Si el archivo está corrupto, la aplicación informa el fallo; no lo elimina ni ejecuta una reparación destructiva.

## Requisitos y ejecución

Entorno de referencia: Flutter 3.47.5 y Dart 3.13.4. Para Android: SDK Android y JDK 21 compatible con Gradle 8.14, AGP 8.11.1 y Kotlin 2.2.20. Chrome permite ejecutar la versión web. La configuración Android incluida es de desarrollo, con identificador `com.example.ecommerce_clean_app` y firma debug; una publicación requiere identidad y firma propias.

```bash
git clone https://github.com/MiguelArbelaez0/ECOMMERCE.git
cd ECOMMERCE
flutter pub get
flutter run -d chrome
# Con un emulador o dispositivo Android conectado:
flutter devices
flutter run -d <device-id>
```

El catálogo requiere acceso a Internet. Dio utiliza HTTPS y límites de 15 segundos para conexión, envío y recepción. Las categorías se derivan del catálogo cargado. No se necesita una clave API ni un archivo de secretos.

## Pruebas y compilación

```bash
dart format --output=none --set-exit-if-changed lib test integration_test test_driver
flutter analyze
flutter test
flutter build web
flutter build apk --debug
# En un dispositivo Android disponible:
flutter test integration_test/shopping_flow_test.dart -d <device-id>
```

Las pruebas unitarias y de widgets utilizan respuestas y repositorios controlados. Las pruebas de archivos Hive usan directorios temporales; no modifican el carrito del usuario. La integración Android utiliza un catálogo HTTP simulado y almacenamiento temporal exclusivo, y comprueba el carrito después de cerrar y reabrir sus dependencias. Una segunda prueba ejecuta guardado y lectura en procesos Android separados, con almacenamiento exclusivo dentro de documentos; el procedimiento está en [Validación de plataformas](docs/PLATFORM_VALIDATION.md).

## Resultados verificados

Validación local del 5 de noviembre de 2026:

| Comprobación | Resultado |
|---|---|
| Resolución de dependencias | Correcta |
| Formato y análisis estático | Correctos, sin incidencias |
| Pruebas unitarias y de widgets | 38 aprobadas, 0 fallidas |
| Compilación web | Correcta |
| Compilación APK debug | Correcta con JDK 21 aislado |
| GitHub Actions | [Ejecución aprobada para 49110cd](https://github.com/MiguelArbelaez0/ECOMMERCE/actions/runs/42139013381) |
| Persistencia Hive en archivos temporales | Reapertura, claves antiguas, concurrencia y corrupción verificadas |
| API pública, comprobación puntual | HTTP 200 y 20 productos |
| Chrome funcional y persistencia al recargar/reabrir | Validación manual confirmada por el autor, sin fallos |
| Integración Android | 3 comprobaciones aprobadas en Android 16/API 36: flujo, guardado y lectura en otro proceso |
| Persistencia Android entre procesos | Cantidad 3 y total 59.97 conservados en documentos después de cierre completo |
| Android con catálogo real y revisión visual | Flujo confirmado manualmente por el autor, sin fallos |
| Carrito habitual Android tras cierre completo | Producto ID 1, cantidad 1 y total 109.95 conservados; archivo e interfaz comprobados |

Los widgets se ejercitaron a 320×640, 800×900 y 1440×900, además de texto al 200 % a 320×740. Las pruebas Android usan HTTP controlado; la revisión manual de Chrome usa el catálogo real. La integración usa un subdirectorio exclusivo de documentos. Además se comprobó el carrito habitual Android después de cerrar completamente el proceso: su contenido se conservó y el autor lo confirmó en pantalla. GitHub Actions ejecutó satisfactoriamente formato, análisis, las 38 pruebas y ambas compilaciones para el commit `49110cd`. Los controles del último commit se consultan en el [PR #5](https://github.com/MiguelArbelaez0/ECOMMERCE/pull/5/checks).

## Limitaciones

- Fake Store API es un servicio externo de demostración; su disponibilidad y las restricciones del navegador pueden afectar el catálogo. No hay catálogo sin conexión.
- Los precios se muestran con `$` y dos decimales; no hay conversión de monedas, impuestos, inventario ni validación de precios por un servidor propio.
- No hay autenticación, pedidos reales ni procesamiento de pagos. El carrito local no almacena credenciales ni información de pago y no está cifrado.
- La recuperación de archivos físicamente corruptos o registros incompatibles requiere revisar o restaurar una copia del almacenamiento; la aplicación no los descarta automáticamente.
- El esquema existente acepta los tipos originales. No se ha inventado una migración para formatos históricos no documentados.
- La interfaz conserva los textos principalmente en inglés y las categorías originales de la API; no implementa localización completa.
- Android y web cuentan con configuración de compilación. iOS y escritorio no están configurados ni validados.
- Flutter advierte sobre el futuro fin de soporte de las versiones actuales de Gradle, AGP y Kotlin; no se han actualizado como parte de estas correcciones.

## Autor

**Miguel Arbeláez Vallejo** — Flutter y Dart · Desarrollo móvil

[Perfil de GitHub](https://github.com/MiguelArbelaez0) · [Código del proyecto](https://github.com/MiguelArbelaez0/ECOMMERCE)
