# Poussette Intelligente (Smart Stroller) 👶🛒

![Status](https://img.shields.io/badge/Status-Completed-success)
![Microcontroller](https://img.shields.io/badge/Microcontroller-PIC16F887-blue)
![Simulation](https://img.shields.io/badge/Simulation-Proteus_ISIS-orange)
![Language](https://img.shields.io/badge/Language-Assembly-lightgrey)

## 📌 Project Overview
**Poussette Intelligente** is an academic embedded systems project developed at the **Faculté Des Sciences Et Techniques Al Hoceima (FSTH)** for the academic year 2025-2026. 

This project aims to solve the physical constraints of conventional strollers by introducing an autonomous, intelligent stroller. Driven by a **PIC16F887 microcontroller**, the system is capable of automatically following the parent, detecting and avoiding obstacles, and dynamically adjusting its motor speed based on the terrain's slope using PWM control.

## ✨ Key Features
* **👤 Auto-Follow System:** Uses IR sensors (KY-005/KY-022) to detect the parent's presence automatically.
* **🛑 Obstacle Avoidance:** Utilizes an HC-SR04 ultrasonic sensor to measure distance and automatically stop the stroller and trigger a buzzer alarm if an obstacle is too close.
* **⛰️ Dynamic Slope Adaptation (MPU6050):** Integrates an accelerometer/gyroscope via I2C to detect uphill or downhill slopes. The microcontroller dynamically adjusts the PWM duty cycle to increase power on climbs and reduce speed on descents.
* **⚠️ Safety Timeout System:** If the parent's IR signal is lost for more than 5 seconds, the stroller automatically locks the motors and flashes a red LED to prevent uncontrolled movement.
* **🎮 Remote Control via Radio:** Includes a wireless remote control powered by an Arduino Uno and HC-12 433MHz radio modules communicating via UART, allowing manual left/right steering and emergency stops.

## 🛠️ Hardware Architecture
* **Microcontroller:** PIC16F887 (Main control) & Arduino Uno (Remote control)
* **Motor Driver:** L293D Shield
* **Inertial Sensor:** MPU6050 (Accelerometer & Gyroscope)
* **Sensors:** * HC-SR04 (Ultrasonic)
  * KY-005 (IR Emitter) & KY-022 (IR Receiver)
* **Communication:** HC-12 Radio Transceiver (UART)
* **Power Supply:** LM2596 3A Adjustable Step-down, 3.7V 18650 Li-ion Batteries
* **Actuators & Alerts:** DC Motors, Buzzer, LEDs

## 💻 Software & Tools
* **IDE:** MPLAB X IDE (Programmed in Assembly / ASM)
* **Simulation:** Proteus ISIS Design Suite
* **Communication Protocols Used:**
 * **I2C:** For MPU6050 to PIC16F887 communication.
  * **UART:** For HC-12 wireless radio communication.
* **PWM:** For precise motor speed control via the L293D.

## 🚀 How to Run the Simulation
1. Install **Proteus ISIS Design Suite** (Version 8.1 or higher recommended).
2. Clone this repository
3. Open the `Simulation/SIMULATION_POUSSETTE.pdsprj` file in Proteus.
4. Get the .hex file from the Assembly file in repository
5. Double-click on the PIC16F887 component in the schematic and load the corresponding `.hex` file from the `Code` folder.
6. Run the simulation using the play button at the bottom left of the Proteus workspace.

## 👨‍🎓 Team Members
Master's in Embedded Systems and Robotics (Systèmes Embarqués et Robotiques)
* **Bouzakoura Oussama**
* **Fattachi Imane**
* **Hassan Abdoulaye Acyl**
* **Hamza Ait Taleb**
  
**Institution:** Université Abdelmalek Essaadi - FST Al Hoceima
