const int MAX_PLAYERS = 4;
const int buttonPins[MAX_PLAYERS] = {2, 3, 4, 5};

bool registered[MAX_PLAYERS] = {false, false, false, false};
int numRegistered = 0;

// 8 sec to join, tweak as needed
const unsigned long REGISTRATION_WINDOW = 8000;
unsigned long registrationStart;

bool gameReady = false;
bool locked = false;

void setup()
{
    Serial.begin(9600);
    for (int i = 0; i < MAX_PLAYERS; i++)
    {
        pinMode(buttonPins[i], INPUT_PULLUP);
    }
    Serial.println("Press your button to join! You have 8 seconds...");
    registrationStart = millis();
}

void loop()
{
    if (!gameReady)
    {
        runRegistration();
    }
    else
    {
        runGame();
    }
}

void runRegistration()
{
    // check each button for a first-time press
    for (int i = 0; i < MAX_PLAYERS; i++)
    {
        if (!registered[i] && digitalRead(buttonPins[i]) == LOW)
        {
            delay(20); // debounce
            if (digitalRead(buttonPins[i]) == LOW)
            {
                registered[i] = true;
                numRegistered++;
                Serial.print("Player ");
                Serial.print(i + 1);
                Serial.println(" joined!");
            }
        }
    }

    bool timeUp = (millis() - registrationStart) >= REGISTRATION_WINDOW;

    if (timeUp || numRegistered == MAX_PLAYERS)
    {
        if (numRegistered >= 2)
        {
            gameReady = true;
            Serial.print(numRegistered);
            Serial.println(" players registered. Game starting!");
        }
        else
        {
            // not enough players yet - extend the window and keep waiting
            Serial.println("Need at least 2 players. Waiting for more...");
            registrationStart = millis(); // reset the timer, keep registering
        }
    }
}

void runGame()
{
    if (!locked)
    {
        for (int i = 0; i < MAX_PLAYERS; i++)
        {
            if (registered[i] && digitalRead(buttonPins[i]) == LOW)
            {
                delay(20);
                if (digitalRead(buttonPins[i]) == LOW)
                {
                    Serial.print("Player ");
                    Serial.print(i + 1);
                    Serial.println(" buzzed in first!");
                    locked = true;
                    break;
                }
            }
        }
    }
    else
    {
        // hold any registered button ~1.5s to reset the round
        bool anyHeld = false;
        for (int i = 0; i < MAX_PLAYERS; i++)
        {
            if (registered[i] && digitalRead(buttonPins[i]) == LOW)
                anyHeld = true;
        }
        if (anyHeld)
        {
            delay(1500);
            locked = false;
            Serial.println("Round reset. Ready!");
        }
    }
}