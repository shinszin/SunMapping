int numRays = 24; // Number of rays around the circle
float maxRayLength = 300; // Maximum length of a ray
float minRayLength = 100; // Minimum length of a ray
color[] colorsLayer1;
color[] colorsLayer2;
color[] colors; // Array holding colors for each ray
PVector center; // Center of the sun icon
float handAngle = 0; // Current angle of the clock hand
float targetAngle = 0; // Target angle for the hand to move towards
float easing = 0.2; // Snappier easing factor for quicker movement
int[] temperatures; // Array holding temperature data for 24 hours
Table xy; // Table to store CSV data
float time = 0; // Used for ray animation

void setup() {
  size(900, 900);
  center = new PVector(width / 2, height / 2);
  
  // Load temperature data from CSV
  xy = loadTable("https://eif-research.feit.uts.edu.au/api/csv/?rFromDate=2024-09-16T11%3A54%3A19&rToDate=2024-09-17T11%3A54%3A19&rFamily=wasp&rSensor=ES_B_11_428_3EA4&rSubSensor=TCA", "csv");

  temperatures = new int[24]; // Array for 24 hours of temperature data
  colors = new color[24];
  colorsLayer1 = new color[numRays];
  colorsLayer2 = new color[numRays];

  // Read the temperature data from the CSV and initialize the temperatures and colors array
  for (int i = 0; i < 24; i++) {
    if (i < xy.getRowCount()) {
      // Read the temperature data from the 2nd column (index 1)
      int tempValue = xy.getInt(i, 1);
      temperatures[i] = tempValue; // Assign the value to the temperatures array

      // Map temperature to color from blue (cold) to red (hot)
      colors[i] = lerpColor(color(0, 0, 255), color(255, 0, 0), map(temperatures[i], 10, 30, 0, 1));
    } else {
      temperatures[i] = int(random(10, 30)); // Fallback in case there is less data
      colors[i] = lerpColor(color(0, 0, 255), color(255, 0, 0), map(temperatures[i], 10, 30, 0, 1));
    }

    // Initialize color palettes for two layers
    colorsLayer1[i] = lerpColor(color(255, 0, 0), color(255, 150, 0), map(i, 0, numRays, 0, 1)); // Red to orange
    colorsLayer2[i] = lerpColor(color(255, 200, 0), color(255, 255, 0), map(i, 0, numRays, 0, 1)); // Orange to yellow
  }
}

void draw() {
  background(20);
  noFill();
  
  // Increment time for animation
  time += 0.02; // Increment time to animate rays smoothly
  
  // Draw radial sun rays with two layers
  drawRadialLayer(1); // First radial layer (closer to the center)
  drawRadialLayer(2); // Second radial layer (farther from the center)
  
  // Automatically update and draw the clock hand
  updateClockHand(); 
  drawClockHand(); 
  
  // Draw center label or info
  drawCenterLabel();
}

void drawRadialLayer(int layer) {
  for (int i = 0; i < numRays; i++) {
    float angle = radians(map(i, 0, numRays, 0, 360));
    
    // Animate ray length with sine wave based on time
    float rayLength = map(temperatures[i], 10, 30, minRayLength, maxRayLength);
    rayLength += sin(time + i * 0.5) * 20; // Small variation for the sine-based animation

    // Define control points for each layer
    PVector control1, control2, end;
    if (layer == 1) {
      control1 = PVector.fromAngle(angle - radians(15)).mult(rayLength * 3.0).add(center);
      control2 = PVector.fromAngle(angle + radians(-15)).mult(rayLength * 3.0).add(center);
      end = PVector.fromAngle(angle).mult(rayLength).add(center);
      
      stroke(colorsLayer1[i]);
    } else {
      control1 = PVector.fromAngle(angle - radians(15)).mult(rayLength * 4.0).add(center);
      control2 = PVector.fromAngle(angle + radians(13)).mult(rayLength * -5.0).add(center);
      end = PVector.fromAngle(angle).mult(rayLength * -0.4).add(center);
      
      stroke(colorsLayer2[i]);
    }
    
    strokeWeight(2);
    bezier(center.x, center.y, control1.x, control1.y, control2.x, control2.y, end.x, end.y);
  }
}

void updateClockHand() {
  // Calculate the target angle based on mouse position
  float angleToMouse = atan2(mouseY - center.y, mouseX - center.x);

  // Convert negative angles to positive angles
  if (angleToMouse < 0) {
    angleToMouse += TWO_PI; // Make sure the angle is between 0 and TWO_PI (360 degrees)
  }

  // Map angle to nearest hour (each hour corresponds to 15 degrees or 1/24 of 360 degrees)
  float snappedAngle = radians(int(degrees(angleToMouse) / 15) * 15); // Snap angle to 15-degree increments (for hours)

  // Smoothly move the hand towards the snapped angle using a snappier easing factor
  handAngle += (snappedAngle - handAngle) * easing;

  // To make it snappier, "snap" to the exact hour when the difference is small
  if (abs(snappedAngle - handAngle) < radians(2)) {
    handAngle = snappedAngle; // Snap to the hour exactly
  }
}

void drawClockHand() {
  // Keep your clock hand parameters as before
  float handLength = maxRayLength + 40; // Adjusted length for a larger clock face
  PVector handEnd = PVector.fromAngle(handAngle).mult(handLength).add(center);
  
  stroke(255);
  strokeWeight(4); // Slightly thicker hand for visibility
  line(center.x, center.y, handEnd.x, handEnd.y);

  // Highlight corresponding ray and show temperature in tooltip
  int hour = (int)map(degrees(handAngle) + 360, 0, 360, 0, 24) % 24; // Ensure hour is within [0, 23]
  displayTooltip(hour);
}

void displayTooltip(int hour) {
  // Display temperature data for the highlighted ray
  fill(255);
  textSize(20); // Larger font size for a bigger clock
  text("Hour: " + hour + "\nTemp: " + temperatures[hour] + "°C", mouseX, mouseY - 20);
}

void drawCenterLabel() {
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(32);
  text("", center.x, center.y);
}
