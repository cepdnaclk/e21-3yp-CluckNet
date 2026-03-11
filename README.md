# CLUCKNET 
**University of Peradeniya - Computer Engineering 3rd Year Project (Goup 18)**

> **CURRENT STATUS: INITIAL DEVELOPMENT PHASE**  
> *The project is in the early stages of hardware and software integration. While the ESP32 sensor modules and automated control units are being physically constructed, the monitoring dashboard is actively being developed with simulated sensor data for testing and validation purposes.*

---

##  The Vision
> *To build a smart IoT-based chicken farm that continuously monitors environmental conditions, detects harmful gases, and automates climate control to ensure optimal poultry health and growth. By integrating sensors, ESP32 modules, and a real-time dashboard, farmers can make data-driven decisions efficiently. This system not only improves poultry welfare but also ensures the industry benefits economically through better productivity and reduced losses.*

### Our Solution
**Smart Chicken Farm Monitoring System** leverages IoT technology to provide **continuous environmental monitoring and automation** for poultry farms. Equipped with **ESP32-based sensor units**, it measures temperature, humidity, ammonia, and LPG levels in real-time, while a central dashboard allows farmers to track conditions remotely. Automated actuators respond instantly to unsafe conditions—activating fans, heaters, or gas valves—ensuring optimal chicken growth, minimizing losses, and enhancing economic efficiency for the farm.

---

##  Planned System Architecture

Our system is designed with a **three-tier architecture** to ensure reliable monitoring, automation, and remote accessibility:

1.  **Edge Layer (Coop Units):** ESP32 sensor modules equipped with **SHT30 temperature & humidity sensors, ammonia and LPG gas sensors**, and actuators (fans, heaters, gas valves). These units collect real-time environmental data and transmit it locally using **ESP-NOW** or WiFi.
2.  **Local Station (Farm Dashboard):** A central ESP32 receiver or local PC collects sensor data and displays it on a **Desktop Dashboard (React)** for real-time monitoring, alerts, and control of the farm environment.
3.  **Cloud Layer (Remote Monitoring):** Integration with **AWS IoT Core** allows data storage, historical analytics, and **mobile alerts via a React app**, enabling farmers to respond promptly to unsafe conditions even when off-site.


---

##  Repository Structure

```text
smart-chicken-farm/
├── farm-dashboard/        # (ACTIVE) React.js Desktop Dashboard for monitoring and control
├── esp32-firmware/        # (PLANNED) C/C++ firmware for ESP32 sensor & actuator units
├── mobile-app/            # (PLANNED) React app for remote alerts and monitoring
├── 3d-mechanics/          # (PLANNED) CAD/3D printing files for sensor housing and actuator mounts
└── docs/                  # Project documentation, diagrams, and notes

Running the Desktop Dashboard (Development Mode)
Since the ESP32 hardware is under assembly, the Desktop Dashboard uses a mockSensorService to simulate temperature, humidity, and gas readings for UI/UX testing.

Prerequisites
Node.js (v18+)
npm


Setup & Run
#Bash
# 1. Navigate to the dashboard directory
cd farm-dashboard

# 2. Install dependencies
npm install

# 3. Start the application
npm run dev
