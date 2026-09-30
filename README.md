# E-Commerce Flutter App

Aplicación de comercio electrónico organizada por feature y capas, con Fake Store API para productos y Hive para persistir el carrito localmente.

## Stack

- Flutter 3.47.5 y Dart 3.13.4 (versiones objetivo)
- `flutter_bloc` y `equatable` para presentación y estados
- `dio` para HTTP
- `hive` / `hive_flutter` para persistencia local
- `get_it` para inyección de dependencias

El constraint Dart de `pubspec.yaml` expresa la compatibilidad mínima del SDK. Usa las versiones objetivo anteriores para validar la configuración.

## Arquitectura

```text
Presentation (Pages, Widgets, BLoCs)
        ↓
Domain (Use Cases, Repository contracts, Entities)
        ↑
Data (Repository implementations, Data Sources, Models)
        ↓
External sources (Fake Store API / Hive)
```

Domain define las operaciones y contratos; Data implementa esos contratos y contiene las integraciones Dio/Hive. Las páginas y BLoCs dependen de casos de uso. `lib/injection/injection_container.dart` configura Data Sources, repositorios, casos de uso y BLoCs.

## Estructura

```text
lib/
  core/
    error/                 # Exceptions y Failures compartidos
    network/               # Cliente Dio centralizado
    utils/                 # Either
  features/
    products/
      data/                # API, modelo JSON, implementación de repositorio
      domain/              # Product, contrato y casos de uso
      presentation/        # BLoC, páginas y widgets
    cart/
      data/                # Data Source Hive, modelo y repositorio
      domain/              # CartItem, contrato y casos de uso
      presentation/        # BLoC, página y widgets
  injection/
    injection_container.dart
  main.dart
test/                      # Pruebas organizadas por feature/capa
```

## Funcionalidad implementada

- Lista y detalle de productos desde Fake Store API.
- Filtro de productos por categoría en la interfaz.
- Agregar, quitar, cambiar cantidad, vaciar y restaurar el carrito persistido.
- Cálculo del total del carrito a partir de sus artículos.
- Estados de carga y error en BLoCs.

El checkout es solo una acción visual; no procesa pagos ni crea pedidos.

## API

- `GET https://fakestoreapi.com/products`
- `GET https://fakestoreapi.com/products/{id}`

## Comandos

```bash
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run
```
