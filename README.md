# Raksha – SafeHer

Raksha – SafeHer is a Flutter-based Android women safety application designed to provide immediate emergency assistance using real-time location tracking, SMS alerts, background monitoring, and sensor-based triggers.

The application ensures continuous safety support by integrating GPS tracking, background services, voice monitoring, and emergency communication features.

---

## 📱 Project Overview

Raksha – SafeHer is developed as an Android mobile application aimed at enhancing women's safety through technology. The system allows users to quickly notify emergency contacts, share live location, and activate safety features even when the application runs in the background.

The app combines communication services, device sensors, and background processing to ensure rapid response during emergency situations.

---

## 🚀 Core Features

### 🔴 SOS Emergency Alert
- One-tap emergency activation
- Sends SMS alerts to registered emergency contacts
- Shares real-time GPS location
- Can initiate direct phone calls

### 📍 Live Location Tracking
- Uses Geolocator for accurate GPS tracking
- Supports foreground and background location updates

### 🎙 Voice Monitoring & Recording
- Speech-to-text integration
- Background microphone monitoring
- Audio recording capability during emergencies

### 📳 Motion & Sensor Detection
- Uses device sensors for motion detection
- Can trigger alerts based on physical activity
- Provides vibration feedback

### 🔄 Background Service Support
- Runs using Flutter Background Service
- Continues monitoring even when minimized
- Supports Android foreground services

### 💾 Local Data Management
- Stores user data and emergency contacts using Sqflite
- Uses Shared Preferences for lightweight storage

### 🌐 Backend Communication
- HTTP-based communication with backend services

---

## 🛠️ Tech Stack

- Framework: Flutter
- Language: Dart
- Platform: Android
- State Management: Provider
- Database: Sqflite
- Location Services: Geolocator
- Permissions Handling: Permission Handler
- Background Services: Flutter Background Service
- Sensors: Sensors Plus
- Voice Processing: Speech to Text
- Networking: HTTP
- Version Control: Git & GitHub

---

## 🔐 Android Permissions Used

The application requires the following permissions:

- INTERNET  
- ACCESS_FINE_LOCATION  
- ACCESS_COARSE_LOCATION  
- SEND_SMS  
- RECEIVE_SMS  
- CALL_PHONE  
- READ_PHONE_STATE  
- RECORD_AUDIO  
- FOREGROUND_SERVICE  
- POST_NOTIFICATIONS  

These permissions are essential for emergency communication, live tracking, and background monitoring.

---

## 📂 Project Structure

```
raksha/
│
├── lib/                     → Main application source code
├── android/                 → Android platform configuration
├── ios/                     → iOS configuration files
├── web/                     → Web support files
├── windows/                 → Windows support files
├── pubspec.yaml             → Project dependencies
└── README.md                → Project documentation
```


## ⚙️ Installation & Setup

1. Clone the repository:

   git clone https://github.com/Samii2116/Raksha-Safeher.git

2. Navigate to the project directory:

   cd Raksha-Safeher

3. Install dependencies:

   flutter pub get

4. Run the application:

   flutter run

---

## 👥 Team Members

- Abhay Munjewar
- Vardhan Mali
- Maitry Santoshwar 
- Samiksha Chaudhari

---

## 🎯 Project Objective

The objective of Raksha – SafeHer is to develop a reliable mobile safety system that integrates real-time GPS tracking, emergency communication, sensor-based detection, and background services to provide immediate assistance during critical situations.

---

## 🔮 Future Enhancements

- AI-based distress sound detection  
- Cloud-based data synchronization  
- Guardian live tracking dashboard  
- Emergency video recording feature  
- Multi-language support  

---

## 📌 Project Status

Completed –  Group Project  
Functional Android Application  



