# E-Commerce Flutter

Aplicación móvil de comercio electrónico desarrollada con Flutter y Dart, utilizando BLoC, Dio, Hive y GetIt, e integrando la API de Fake Store para los productos y persistencia local del carrito.

## 📱 Descripción general

ECOMMERCE es una aplicación Flutter que demuestra una experiencia de compra móvil con catálogo de productos, detalles, carrito y persistencia local.

El proyecto se enfoca en desarrollo práctico con Flutter, gestión reactiva de estado, integración con APIs REST, inyección de dependencias y persistencia local.

## 🚀 Funcionalidades

- Catálogo de productos.
- Información y detalles de productos.
- Productos obtenidos desde Fake Store API.
- Carrito de compras.
- Agregar y eliminar productos.
- Persistencia del carrito.
- Gestión de estado con BLoC.
- Integración con API REST.
- Inyección de dependencias.
- Organización por capas.
- Interfaz adaptable.

## 🏗️ Arquitectura

Flujo principal:

```text
Presentación
     ↓
BLoC
     ↓
Repositorio
     ↓
Dio
     ↓
Fake Store API
```

Persistencia del carrito:

```text
Estado del carrito
    ↓
Hive
    ↓
Almacenamiento local
```

## 🧩 Tecnologías

| Tecnología | Uso |
|---|---|
| Flutter | Desarrollo de la aplicación |
| Dart | Lenguaje de programación |
| flutter_bloc | Gestión de estado |
| BLoC | Estado de la aplicación |
| Dio | Cliente HTTP |
| Hive | Persistencia local |
| GetIt | Inyección de dependencias |
| Fake Store API | Datos de productos |

## 🛍️ Catálogo

La aplicación obtiene los productos desde Fake Store API y los presenta mediante la interfaz Flutter.

Los datos se obtienen a través de la capa de datos, evitando acoplar la interfaz directamente a las solicitudes HTTP.

## 🛒 Carrito de compras

Permite:

- Agregar productos.
- Eliminar productos.
- Revisar productos seleccionados.
- Mantener el estado del carrito.
- Conservar el carrito entre sesiones.

Hive se utiliza para la persistencia local.

## 💾 Persistencia local

El carrito se almacena localmente para conservar la información después de cerrar y abrir la aplicación.

El proyecto se concentra en la experiencia de comercio electrónico del lado del cliente; no implementa pagos reales ni procesamiento de pedidos de producción.

## ⚡ Gestión de estado

BLoC administra el estado y coordina los cambios entre la interfaz y la lógica de la aplicación.

## 💉 Inyección de dependencias

`GetIt` centraliza el registro y resolución de dependencias, reduciendo el acoplamiento entre componentes.

## 🌐 Integración con la API

`Dio` se utiliza como cliente HTTP para comunicarse con Fake Store API.

La API proporciona el catálogo de productos consumido por la aplicación.

## 📂 Estructura

```text
lib/
├── core/
├── data/
├── domain/
└── presentation/
```

### Presentación
Pantallas, widgets y gestión de estado.

### Dominio
Entidades, lógica de aplicación y abstracciones de repositorio.

### Datos
Comunicación con la API, modelos e implementaciones de repositorios.

### Core
Funcionalidades compartidas y utilidades.

## ⚙️ Instalación

### 1. Clonar el repositorio

```bash
git clone https://github.com/MiguelArbelaez0/ECOMMERCE.git
cd ECOMMERCE
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Ejecutar

```bash
flutter run
```

## 🎯 Qué demuestra este proyecto

- Flutter y Dart.
- Gestión de estado con BLoC.
- Integración con APIs REST.
- Dio.
- Persistencia local con Hive.
- Inyección de dependencias con GetIt.
- Gestión de carrito.
- Interfaces de catálogo.
- Arquitectura por capas.
- Separación de responsabilidades.
- Desarrollo de interfaces adaptables.

## 📌 Estado del proyecto

**Proyecto de portafolio terminado.**

Desarrollado para demostrar desarrollo móvil con Flutter, consumo de APIs REST, gestión de estado con BLoC, inyección de dependencias, persistencia local y flujo de comercio electrónico del lado del cliente.

El flujo de pago es únicamente parte de la interfaz y no procesa pagos ni pedidos reales.

## 👨‍💻 Autor

**Miguel Arbeláez Vallejo**

Desarrollador de Software | Flutter y Dart | Desarrollo integral | Servidor | IA y Datos
