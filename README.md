# Traffic-Light-System-with-Crosswalk-Functionality
AVR assembly project for a traffic light system with crosswalk logic using Timer1 on ATMega328p

## features
- Red → Green → Yellow light sequencing
- Crosswalk buttons for North/South and East/West directions
- Pedestrian WALK and STOP LEDs
- Timer1 in CTC mode for timed delays
- Button debouncing and flag logic
- One button in pull up mode, one in high-impedance (floating) mode

# hardware
- **Microcontroller**:
  - ATMega328p
- **Breadboard**:
  - half-size is enough
- **LEDs**:
  - 2 red, 2 green, and 2 yellow leds for cars
  - 2 white leds for pedestrian walk signals
- **Push Buttons**:
  - 2 for crosswalk input
- **Resistors**:
  - 8 × 250 Ω (for leds)
  - 1 × 10kΩ (for one of the buttons)
- uses ports B and D (specific pin assignments in the code)
- **Wires**
  
## flash the .asm file
- Open the .asm file in Microchip Studio
- Make sure the target device is set to ATMega328p
- Build the project
- Go to Tools → Select your Arduino Uno (assuming it's already saved as a tool)

## circuit diagram
![Screenshot of setup](https://github.com/user-attachments/assets/f7146596-c1ff-4e57-a3c4-711b34a0ce86)

## notes
- This was part of a course project
- Created by Lillianmay Lancour, April 2025
