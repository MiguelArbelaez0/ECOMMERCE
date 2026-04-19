# E-Commerce Flutter App (Clean Architecture)

A production-ready Flutter e-commerce mobile app built with **Flutter 3.38.7** using Fake Store API.

## Features

- Browse products from API
- View detailed product info
- Add/remove/update items in cart
- Cart total calculation
- Local cart persistence with Hive
- Loading and error state handling

## Tech Stack

- Flutter 3.38.7
- Dart
- Clean Architecture
- flutter_bloc
- Dio
- Hive / hive_flutter
- Equatable
- get_it (DI)

## Architecture

The app is split by feature and layers:

- **Data layer**: API/local data sources, models, repository implementations
- **Domain layer**: entities, repository contracts, use cases
- **Presentation layer**: BLoCs, events/states, pages and reusable widgets

Core shared modules:

- `core/network` for Dio client
- `core/error` for failures/exceptions
- `core/utils` for DI and utility classes

## Project Structure

```text
lib/
  core/
    network/
    error/
    utils/
  features/
    products/
      data/
      domain/
      presentation/
    cart/
      data/
      domain/
      presentation/
  shared/
    widgets/
```

## Setup

1. Clone repository
2. Install dependencies:

```bash
flutter pub get
```

3. Run app:

```bash
flutter run
```

## API

- All products: `GET https://fakestoreapi.com/products`
- Single product: `GET https://fakestoreapi.com/products/{id}`

## Notes

- No `setState` for business logic
- Real API integration via Dio
- Local persistence via Hive box (`cart_box`)
