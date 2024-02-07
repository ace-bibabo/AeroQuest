# Hardware implementation of Drone simulation

## Intro
This project is focusing on developing a drone simulation system using the provided lab board to replicate the intricacies of controlling a drone during a search operation in mountainous terrains. The program simulates the navigation of a drone over a 2D matrix representing a mountain landscape. The simulation provides real-time updates of the drone as it navigates the terrain such as the drone states, speed, altitude, position on the map and whether the drone has identified the crash location or crashed. Users define the accident location, introducing variability to the simulation.

Input mechanisms include a reset button, push buttons for speed adjustment, a keypad for flight direction and state changes, and an LED bar indicating simulation status.
![](https://github.com/ace-lii/accident/blob/main/img/outline.png?raw=true)

## Design assumptions
1.	We are always given valid inputs, where required. E.g., we will not be provided an accident location outside of the map
2.	The drone automatically increases its altitude by 1 at each tick, unless a higher value is set whilst in hover mode during the prior one second interval.
3.	A crash event occurs when the difference between the drone’s altitude and the altitude at the current position is greater than 1.
4.	Going up and down will not cause a crash
5.	A drone will not move out of the grid. If a move like this is performed, it will remain at the border of the map.
6.	Search is only done in the direction that the drone is facing and Manhattan distance is used for visibility.
7.	Top speed is 9m/s.


## Execution Flow

 ![](https://github.com/ace-lii/accident/blob/main/img/flow.png?raw=true)

* Accident Input: The program starts with input of the x and y position for the accident. It will then automatically calculate the z position of the accident. 

* Main: Continuous looping of main until it polls for input or goes to timer interrupt every 1 microsecond.

* Check Input: Loops through checking of input of button press and keyboard. If no input detected then return to main. If detected then handle the relevant input separately

* Handle Push Button: If push button is pressed, Check whether states should be changed according to the button pushed (Cannot change speed for N,S,E,W when in hover mode, speed cannot go over 9, etc.)

* Button Debounce: Poll the push button until the counter is either 0 or 40. 0 meaning no button is being pressed and 40 meaning button is still pressed.

* Keypad debounce: Delay keypad input after keypad entry for 256ms.

* Timer interrupt: OVF2 interrupt rate depends on the speed of the drone. The OVF1 condition refreshes the LCD around every 100ms and OVF2 condition is achieved every 10 times OVF1 condition is achieved when the drone is moving at a speed of 1m/s, which is around once every second. The number of times OVF1 is achieved before OVF2 is inversely proportional to the speed. For example at the speed of 2, OVF2 will be achieved every 5 times OVF1 is achieved, which is around 500ms. This means that the handle speed state only increments the position by at most once and it has the effect of changing the state faster when speed is faster, which makes the drone seem like it’s flying faster..

* Handle Speed: Handles how the speed and direction changes the position of the drone. Only increment or decrement by 1 as mentioned previously.

* Crash Check: Check if the current altitude of the mountain is higher than the current position of the drone by 2. If only by one the drone automatically adjusts height. If not, the drone crashes.

* Crashed: Return a display on LCD that shows the drone has crashed and the location of crash is displayed

* Search: Search in the direction where the drone is heading only. Loop through each position ahead of the drone in the direction that it is facing. If visibility reaches 0 then the accident is not found and go to the next state. If the current loop’s altitude of the map is higher than the drone then the accident is not found and go to the next state. If the drone's position is above the ground by more than the visibility level then go to the next loop (This prevents early exiting when there is a huge pit one step ahead of the drone but accident on the next location level with the drone which should still be visible). If the accident location is found then go to the state of return. Next loop starts with the next position in the direction the drone is facing with 1 less visibility level (Since we are using Manhattan’s distance).

* Return: Return a display on LCD that shows the drone has returned and the location of the accident is displayed.

* Load state on LCD: Displays the states of the drone: the map in the direction the drone is facing, a cursor underneath the drone’s current position on the map, the state of the drone, the x,y,z coordinate of the drone, and the speed of the drone.

## Components
###Registers

| Name           | Register | Description                                                 |
|----------------|----------|-------------------------------------------------------------|
| flightDirection| R3       | Stores the flight direction of the drone                    |
| hfState        | R4       | Stores whether the drone is in hover or flight state        |
| pos_x          | R5       | Stores the drone's x position                               |
| pos_y          | R6       | Stores the drone's y position                               |
| pos_z          | R7       | Stores the drone's altitude                                 |
| counter_speed  | R8       | Used for determining timing intervals in the Timer interrupt|
| func_return    | R9       | Used to store return values from function calls             |
| func_return2   | R10      | Used to store return values from function calls             |
| acci_loc_x     | R11      | Stores the x coordinate of the accident location            |
| acci_loc_y     | R12      | Stores the y coordinate of the accident location            |
| acci_loc_z     | R13      | Stores the altitude of the accident location                |
| visibility     | R14      | Stores visibility level of the drone                         |
| row            | R16      | Used to store the current row when polling keypad input     |
| col            | R17      | Used to store the current column when polling keypad input  |
| rmask          | R18      | Mask used for determining the current row                   |
| cmask          | R19      | Mask used for determining the current column                |
| speed          | R20      | Stores the speed that the drone travels each second         |
| temp1          | R21      | Used as a working register                                   |
| temp2          | R22      | Used as a working register                                   |
| temp3          | R23      | Used as a working register                                   |
| iL             | R24      | Used for counting in the supporting functions               |
| iH             | R25      | Used for counting in the supporting functions               |



### Hardware


| Port Group  | Pin | Port Group | Pin |
|-------------|-----|------------|-----|
| PORT L      | PL7 | KEYPAD     | R0  |
| PORT L      | PL6 | KEYPAD     | R1  |
| PORT L      | PL5 | KEYPAD     | R2  |
| PORT L      | PL4 | KEYPAD     | R3  |
| PORT L      | PL3 | KEYPAD     | C0  |
| PORT L      | PL2 | KEYPAD     | C1  |
| PORT L      | PL1 | KEYPAD     | C2  |
| PORT L      | PL0 | KEYPAD     | C3  |
| PORT D      | RDX3| INPUTS     | PB1 |
| PORT D      | RDX4| INPUTS     | PB0 |
| PORT C      | PC0 | LED BAR    | LED2|
| PORT C      | PC1 | LED BAR    | LED3|
| PORT C      | PC2 | LED BAR    | LED4|
| PORT C      | PC3 | LED BAR    | LED5|
| PORT C      | PC4 | LED BAR    | LED6|
| PORT C      | PC5 | LED BAR    | LED7|
| PORT C      | PC6 | LED BAR    | LED8|
| PORT C      | PC7 | LED BAR    | LED9|
| PORT G      | PG2 | LED BAR    | LED0|
| PORT G      | PG3 | LED BAR    | LED1|
| PORT F      | PF0 | LCD DATA   | D0  |
| PORT F      | PF1 | LCD DATA   | D1  |
| PORT F      | PF2 | LCD DATA   | D2  |
| PORT F      | PF3 | LCD DATA   | D3  |
| PORT F      | PF4 | LCD DATA   | D4  |
| PORT F      | PF5 | LCD DATA   | D5  |
| PORT F      | PF6 | LCD DATA   | D6  |
| PORT F      | PF7 | LCD DATA   | D7  |
| PORT A      | PA4 | LCD CTRL   | BE  |
| PORT A      | PA5 | LCD CTRL   | RW  |
| PORT A      | PA6 | LCD CTRL   | E   |
| PORT D      | RDX4| INPUTS     | PB0 |
| PORT D      | RDX3| INPUTS     | PB1 |



