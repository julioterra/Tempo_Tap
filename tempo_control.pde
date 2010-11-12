/**** DESIGN CONSIDERATIONS: *****
 * 
 * BPM Tap Sketch
 * created by Julio Terra
 * 
 * Simple sketch that takes input from a button to set the tempo of a blinking LED.
 * Developed to be incorporated into my Air Mash-up Project, being developed for 
 * the New Instruments for Musical Expressions class.
 * 
 *****/

#define timer_array_length       4
#define bpm_max                  240
#define bpm_min                  40
#define bpm_led_on_time          70

// variables that hold pin assignment
int tapPin = 2;
int blinkPin = 4;

unsigned long readTime;

// variables for calculating the bpm
unsigned long tapIntervals[timer_array_length];    // array of most recent tap counts */
unsigned long lastTapTime = 0;                     // time when the last tap happened */
int tapState = LOW;
int lastTapState = LOW;                            // the last tap button state */
float bpm = 0;                                     // holds current beats per minute
long avgTapInterval = 0;                          // average interval between beats (used to calculate bpm)
boolean newTap = false;                            // flag that identfies when new taps are received
boolean tapActive = false;                         // flag that identifies whether bpm is being set

// variable for controling bpm light
boolean lightOn = false;
unsigned long lightOnTime = 0;
unsigned long previousLightOnTime = lightOnTime;

void setup()
{
  pinMode(tapPin, INPUT);   /* tap button - press it to set the tempo */
  pinMode(blinkPin, OUTPUT);   /* tap button - press it to set the tempo */
  Serial.begin(9600);

  // re-initialize the array to make space for the new reading 
  for (int i = timer_array_length - 1; i >= 0; i--) tapIntervals[i] = 0;       
}


void loop() {
    catchTap();           
    setTempo();
    bpmBlink();
}



// ***** CAPTURE AND PROCESS TAPS ****** //
// function that captures each tap (or hand movement up and down) and saves time of tap into an array
void catchTap() {
readData();
//int tapState = digitalRead(tapPin);      // read tapState (in the future we will use the proximity readings rather than button)

    // if the tapState is LOW and the previous tap state was different then
    if(lastTapState == LOW && tapState != lastTapState) {       
        for (int i = timer_array_length - 1; i > 0; i--)    // re-initialize the array to make space for the new reading 
            tapIntervals[i] = tapIntervals[i-1];       
        tapIntervals[0] = millis() - lastTapTime;               // calculate current timer by subtracting time of previous tap (lastTapTime) from current time 
        lastTapTime = millis();                                 // set current time as time of previous tap (lastTapTimeTime)
        newTap = true;
        tapActive = true;
        lightOn = true;
        lightOnTime = millis();
    } else if (millis() - lastTapTime > avgTapInterval) {
        tapActive = false;
    }

    lastTapState = tapState;            // set lastTapTimeTimeState variable using current tapState
}

// function that calculates bpm based on taps (or hand movements up and down)
void setTempo() {
    if (newTap) {
        int tempoCounter = 0;      // variable is incremented for each valid reading
        float tempoSum = 0;        // variable that holds the sum of all valid readings    
    
        // loop through each element in the array 
        for (int i = timer_array_length - 1; i >= 0; i--) {    
            if (60000/tapIntervals[i] > bpm_min && 60000/tapIntervals[i] < bpm_max) {    // confirm if reading is valid
                tempoSum += tapIntervals[i];                                             // sum valid readings
                tempoCounter ++;                                                         // increment counter for each valid reading
            }
        }
    
        // if there were more than two valid readings in the array then calculate bpm
        if (tempoCounter >= 3) {
            avgTapInterval = tempoSum / tempoCounter;              // calculate the average time in milliseconds between each tap
            bpm = float(60000)/float(avgTapInterval);                                   // calculate the bpm based on the millisecond averages
        }
    
        Serial.println(bpm);       // print the bpm to the screen
        newTap = false;
    }
}

// function that reads data and debounces it
void readData() {
    if (millis() - readTime > 50) {
      tapState = digitalRead(tapPin);      // read tapState (in the future we will use the proximity readings rather than button)
      readTime = millis();
    }
}


// ***** MAKE LIGHTS BLINK ****** //
void bpmBlink() {

    // check if it is time to turn off the light by seeing if sufficient time has passed since light was turned on
    if (millis() > (lightOnTime + bpm_led_on_time)) {
        lightOnTime += avgTapInterval;
        lightOn = false;
    } 
    // if the button is not currently being used to set the tempo, and it is time to blink the LED, then turn it on
    else if(!tapActive && millis() > lightOnTime) lightOn = true;

    // control the actual blinking of the lights based on the state of the lightOn flag variable
    if (!lightOn) digitalWrite(blinkPin, LOW);
    else if(millis() > lightOnTime) digitalWrite(blinkPin, HIGH);

}



