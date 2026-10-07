# E-Commerce Flutter

A Flutter e-commerce application built with Dart, BLoC, Dio, Hive, and GetIt, integrating the Fake Store API for product data and local persistence for the shopping cart.

## 📱 Overview

ECOMMERCE is a Flutter application that demonstrates the implementation of a mobile shopping experience with product discovery, product details, cart management, and persistent local cart data.

The project focuses on practical Flutter development, reactive state management, REST API integration, dependency injection, and local-first cart persistence.

## 🚀 Features

- Product catalog
- Product information and details
- Product data from the Fake Store API
- Shopping cart
- Add and remove products from the cart
- Persistent cart data
- Reactive state management with BLoC
- REST API integration
- Dependency injection
- Layered application structure
- Responsive Flutter interface

## 🏗️ Architecture

The application separates presentation, application logic, and external data access.

The main flow can be represented as:

```text
Presentation
     ↓
BLoC
     ↓
Repository
     ↓
Dio
     ↓
Fake Store API
```

Cart persistence is handled locally:

```text
Cart State
    ↓
Hive
    ↓
Local Storage
```

## 🧩 Technologies

| Technology | Usage |
|---|---|
| Flutter | Application framework |
| Dart | Programming language |
| flutter_bloc | State management |
| BLoC | Application state |
| Dio | HTTP client |
| Hive | Local persistence |
| GetIt | Dependency injection |
| Fake Store API | Product data |

## 🛍️ Product Catalog

The application retrieves product information from the Fake Store API and presents it through the Flutter interface.

Product data is obtained through the data layer instead of coupling UI components directly to HTTP requests.

## 🛒 Shopping Cart

The cart allows users to:

- Add products
- Remove products
- Review selected products
- Maintain cart state
- Persist cart information locally

Hive is used to preserve cart data between application sessions.

## 💾 Local Persistence

Hive provides local storage for the shopping cart.

This allows cart information to remain available after closing and reopening the application without requiring a remote order or payment backend.

## ⚡ State Management

BLoC is used to manage application state and coordinate changes between the interface and application logic.

This keeps UI components focused on presentation while state transitions and operations remain in dedicated logic components.

## 💉 Dependency Injection

`GetIt` is used for dependency registration and resolution.

This centralizes dependency configuration and reduces direct coupling between application components.

## 🌐 API Integration

The application uses `Dio` as its HTTP client to communicate with the Fake Store API.

The API provides the product catalog consumed by the application.

The project is focused on the client-side e-commerce experience; it does not implement real payment processing or production order fulfillment.

## 📂 Project Structure

The project uses a layered organization to separate responsibilities:

```text
lib/
├── core/
├── data/
├── domain/
└── presentation/
```

### Presentation

Contains screens, widgets, and BLoC state management.

### Domain

Contains application entities, business logic, and repository abstractions.

### Data

Contains API communication, models, and repository implementations.

### Core

Contains shared application functionality and utilities.

## ⚙️ Installation

### 1. Clone the repository

```bash
git clone https://github.com/MiguelArbelaez0/ECOMMERCE.git
cd ECOMMERCE
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run the application

```bash
flutter run
```

Make sure Flutter and Dart are correctly installed and configured on your development environment.

## 🎯 What This Project Demonstrates

This project demonstrates practical experience with:

- Flutter and Dart
- BLoC state management
- REST API integration
- Dio
- Hive local persistence
- Dependency injection with GetIt
- Shopping cart management
- Product catalog interfaces
- Layered application architecture
- Separation of concerns
- Responsive UI development

## 📌 Project Status

**Completed portfolio project.**

The project was developed to demonstrate Flutter application development, REST API consumption, BLoC state management, dependency injection, local persistence, and client-side e-commerce workflows.

The checkout flow is part of the application interface and does not process real payments or orders.

## 👨‍💻 Author

**Miguel Arbeláez Vallejo**

Software Developer | Flutter & Dart | Full-Stack | Backend | AI/Data

- GitHub: https://github.com/MiguelArbelaez0
- LinkedIn: https://www.linkedin.com/in/miguel-arbelaez-v-57719542b/
