/****************************************
 * Egg Timer a la Justy  ('functional' branch, where I refactor and simplify)
 * 
 * A simple boiled egg timer
 * 
 * This sketch was developed in tandem with Seeedstudio's brick system, however that system isn't needed- all that's required are the components used:
 * 
 * • LCD module
 * • Potentiometer
 * • Buzzer
 * • Pushbutton
 * • Thermistor (optional)
 * 
 * Have Fun and may your eggs be boiled to your specifications.
 * 
 * Justy
 * 
 *****************************************/

#include <LiquidCrystal.h> // include the library code:
#include <math.h>

#define PIN_Thermistor 5
#define PIN_Button 9
#define PIN_Buzzer 8
#define PIN_Pot 4

#define TIME_multiplier 250.0

enum e_tag{
  STATE_Init,
  STATE_SetTimer,
  STATE_CountingDown,
  STATE_Buzzing
}
var;

LiquidCrystal lcd(10,11,12,13,14,15,16); // initialize the library with the numbers of the interface pins

long timerValue = 0;
long timer = 0;

long lastMillis;

int animFrame = 0;

boolean blinkFlag;

int state = STATE_Init;  

void setup() {

  lcd.begin(16, 2); // set up the LCD's number of columns and rows: 

  blinkFlag = false;

  pinMode(PIN_Thermistor,INPUT);
  pinMode(PIN_Pot, INPUT);
  pinMode(PIN_Button, INPUT);
  pinMode(PIN_Buzzer, OUTPUT);

  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Welcome... ");
  beep();
  delay(500);
  lcd.setCursor(0,1);
  lcd.print("to Eggysoft");
  beep();
  beep();
  delay(1000);


}

// Run our state machine.  This is written so that as little code as possible appears here.
void loop() {
  switch (state) {
  case STATE_Init: 
    DO_Init(); 
    break;
  case STATE_SetTimer: 
    DO_SetTimer(); 
    break;
  case STATE_CountingDown: 
    DO_CountingDown();
    break;
  case STATE_Buzzing: 
    DO_Buzzing(); 
    break;
  }
  
}

/**********************
 * State Functions - one per state
 * 
 ***********************/

void DO_Init() {
  lcd.clear();
  delay(500);
  lcd.print("Timer:"); // Print a message to the LCD.
  state = STATE_SetTimer;
}

void DO_SetTimer() {
  // Give the blink some sanity
  delay(100);

  // Get the raw timer value
  int rawPot = analogRead(PIN_Pot);  // [0..1023]

  // Convert it to desired milliseconds (where a max of 4 minutes = 1023)
  timerValue = TIME_multiplier * rawPot;

  // Convert it to Human-friendly
  int mins = int(timerValue/60000.0);
  int secs = int(timerValue/1000) % 60;

  lcd.setCursor(7,0);
  if (blinkFlag) {
    //lcd.print(timerValue, DEC);
    lcd.print(mins, DEC);
    lcd.print("m ");
    lcd.print(secs, DEC);
    lcd.print("s");
    // pad out the end
    lcd.print(" ");
  } 
  else {
    lcd.print("         "); 
  }
  blinkFlag = !blinkFlag;

  // Display the temp
  displayTemp();

  // Time to time?
  if (!blinkFlag && digitalRead(PIN_Button) == HIGH) {
    timer = timerValue;
    state = STATE_CountingDown; 
    lastMillis = millis();
  }
}

void DO_CountingDown() {

  playAnim();

  delay(100);

  // Find out the *actual* delta t
  long diff = millis() - lastMillis;
  lastMillis = millis();
  timer -= diff;

  // Convert it to Human-friendly
  int mins = int(timer/60000.0);
  int secs = int(timer/1000) % 60;

  lcd.setCursor(7,1);
  if (blinkFlag || timer > 10000) {

    //lcd.print(timerValue, DEC);
    lcd.print(mins, DEC);
    lcd.print("m ");
    lcd.print(secs, DEC);
    lcd.print("s");
    // pad out the end
    lcd.print(" ");    
  } 
  else {
    lcd.print("         "); 
  }
  blinkFlag = !blinkFlag;

  displayTemp();

  // If within half a second
  if (timer < 500) {
    state = STATE_Buzzing;
    lcd.clear();
    lcd.print("Your Eggs are");
    lcd.setCursor(0,1);
    lcd.print("Ready!! :)");
  }
}

void DO_Buzzing() {
  beep();
  beep();
  delay(500);
  if (digitalRead(PIN_Button) == HIGH) {
    timer = timerValue;
    state = STATE_Init; 
  }
}




/**********************/

void displayTimer() {

}

void playAnim() {

  animFrame++;
  if (animFrame > 3) animFrame = 0;

  delay(100);
  switch(animFrame) {

  case 0: 
    lcd.setCursor(14,0); 
    lcd.print("*"); 
    lcd.setCursor(14,1); 
    lcd.print("."); 
    lcd.setCursor(15,1); 
    lcd.print("."); 
    lcd.setCursor(15,0); 
    lcd.print(" "); 
    break;

  case 1:
    lcd.setCursor(15,0); 
    lcd.print("*"); 
    lcd.setCursor(14,0); 
    lcd.print(".");     
    lcd.setCursor(14,1); 
    lcd.print("."); 
    lcd.setCursor(15,1); 
    lcd.print(" "); 
    break;

  case 2:
    lcd.setCursor(15,1); 
    lcd.print("*"); 
    lcd.setCursor(15,0); 
    lcd.print("."); 
    lcd.setCursor(14,0); 
    lcd.print("."); 
    lcd.setCursor(14,1); 
    lcd.print(" "); 
    break;

  case 3:
    lcd.setCursor(14,1); 
    lcd.print("*"); 
    lcd.setCursor(15,1); 
    lcd.print("."); 
    lcd.setCursor(15,0); 
    lcd.print("."); 
    lcd.setCursor(14,0); 
    lcd.print(" "); 
    break;

  }

}

void displayTemp() {

  lcd.setCursor(0, 1);
  // print the number of seconds since reset:
  int temp = analogRead(PIN_Thermistor);
  float tt = temperature(temp);
  printFloat(tt, 1);
  lcd.print("C");

}

// arduino.cc/playground/ComponentLib/Thermistor2
double temperature(int rawADC) {
  return 0.1*((double)rawADC-248);
}


// printFloat prints out the float 'value' rounded to 'places' places after the decimal point
void printFloat(float value, int places) {

  // this is used to cast digits 
  int digit;
  float tens = 0.1;
  int tenscount = 0;
  int i;
  float tempfloat = value;

  // make sure we round properly. this could use pow from <math.h>, but doesn't seem worth the import
  // if this rounding step isn't here, the value  54.321 prints as 54.3209

  // calculate rounding term d:   0.5/pow(10,places)  
  float d = 0.5;
  if (value < 0)
    d *= -1.0;
  // divide by ten for each decimal place
  for (i = 0; i < places; i++)
    d/= 10.0;    
  // this small addition, combined with truncation will round our values properly 
  tempfloat +=  d;

  // first get value tens to be the large power of ten less than value
  // tenscount isn't necessary but it would be useful if you wanted to know after this how many chars the number will take

  if (value < 0)
    tempfloat *= -1.0;
  while ((tens * 10.0) <= tempfloat) {
    tens *= 10.0;
    tenscount += 1;
  }


  // write out the negative if needed
  if (value < 0)
    lcd.print('-');

  if (tenscount == 0)
    lcd.print(0, DEC);

  for (i=0; i< tenscount; i++) {
    digit = (int) (tempfloat/tens);
    lcd.print(digit, DEC);
    tempfloat = tempfloat - ((float)digit * tens);
    tens /= 10.0;
  }

  // if no places after decimal, stop now and return
  if (places <= 0)
    return;

  // otherwise, write the point and continue on
  lcd.print('.');  

  // now write out each decimal place by shifting digits one by one into the ones place and writing the truncated value
  for (i = 0; i < places; i++) {
    tempfloat *= 10.0; 
    digit = (int) tempfloat;
    lcd.print(digit,DEC);  
    // once written, subtract off that digit
    tempfloat = tempfloat - (float) digit; 
  }
}


void beep() {

  for (int i=0; i<5; i++) {
    digitalWrite(PIN_Buzzer, HIGH);
    delay(5);
    digitalWrite(PIN_Buzzer, LOW);
    delay(10);
  }

}








