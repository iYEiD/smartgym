# Smart Gym AI - Admin App

This is the admin side of the Smart Gym Occupancy Monitoring application. It connects to sensor data via MQTT and manages gym users and occupancy using a Postgres database.

## Features

- **Analytics Dashboard**: Real-time monitoring of gym occupancy, environmental sensors, and parking availability
- **User Management**: Registration of new users via RFID cards, user profile management
- **Activity Log**: Tracking of gym check-ins and checkouts with detailed reporting
- **Settings**: Configuration for MQTT, database, and application parameters

## Prerequisites

- Flutter SDK (^3.7.2)
- Docker and Docker Compose for the Postgres database
- MQTT broker (HiveMQ or similar)

## Getting Started

### 1. Set up the Database

```bash
# Start the database container
docker-compose up -d
```

This will start a Postgres database container with the necessary schema for the application.

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Run the Application

```bash
flutter run
```

## MQTT Configuration

The application connects to the following MQTT topics:

- `/ua/edu/lb/iot2025/sensordata` - Sensor data (light, temperature, humidity, motion, parking)
- `/ua/edu/lb/iot2025/rfidregister` - RFID card registration
- `/ua/edu/lb/iot2025/occupancy` - Gym occupancy data

## Project Structure

- `lib/core/` - Application core, config, constants, and theme
- `lib/data/` - Data layer (models, repositories, services)
- `lib/domain/` - Domain layer (entities, repositories interfaces)
- `lib/presentation/` - UI components (screens, widgets, state management)

## Database Schema

The Docker setup includes a Postgres database with the following schema:

- `users` - User profiles with RFID card IDs
- `check_in_logs` - User check-in and checkout activity
- `occupancy_records` - Gym occupancy data
- `sensor_data` - Environmental sensor readings

## License

This project is licensed under the MIT License.
