/**
 * REALLY simple processing sketch for using webcam input
 * This sends 100 input values to port 6448 using message /wek/inputs
 **/

import processing.video.*;
import oscP5.*;
import netP5.*;

int numPixelsOrig;
int numPixels;
boolean first = true;

int boxWidth = 64;
int boxHeight = 48;

int numHoriz = 640/boxWidth;
int numVert = 480/boxHeight;

color[] downPix = new color[numHoriz * numVert];


Capture video;

OscP5 oscP5;
NetAddress dest;

void setup() {
  // colorMode(HSB);
  size(640, 480, P2D);

  String[] cameras = Capture.list();

  if (cameras == null) {
    println("Failed to retrieve the list of available cameras, will try the default...");
    video = new Capture(this, 640, 480);
  } 
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    /* println("Available cameras:");
     for (int i = 0; i < cameras.length; i++) {
     println(cameras[i]);
     } */

    video = new Capture(this, 640, 480);

    // Start capturing the images from the camera
    video.start();

    numPixelsOrig = video.width * video.height;
    loadPixels();
    noStroke();
  }

  /* start oscP5, listening for incoming messages at port 12000 */
  oscP5 = new OscP5(this, 12000);
  dest = new NetAddress("127.0.0.1", 6448);
}

void draw() {

  if (video.available() == true) {
    video.read();

    video.loadPixels(); // Make the pixels of video available

    int boxNum = 0;
    int tot = boxWidth*boxHeight;
    for (int x = 0; x < 640; x += boxWidth) {
      for (int y = 0; y < 480; y += boxHeight) {
        float red = 0, green = 0, blue = 0;

        for (int i = 0; i < boxWidth; i++) {
          for (int j = 0; j < boxHeight; j++) {
            int index = (x + i) + (y + j) * 640;
            red += red(video.pixels[index]);
            green += green(video.pixels[index]);
            blue += blue(video.pixels[index]);
          }
        }
        downPix[boxNum] = color(red/tot, green/tot, blue/tot);
        fill(downPix[boxNum]);

        if (boxNum/10 < round(cropLeft*5)) {
          fill(0);
        }

        if (boxNum/10 > 9-round(cropRight*5)) {
          fill(0);
        }

        int index = x + 640*y;
        red += red(video.pixels[index]);
        green += green(video.pixels[index]);
        blue += blue(video.pixels[index]);
        rect(width - boxWidth - x, y, boxWidth, boxHeight);
        
        fill(184, 40, 50);
        textAlign(CENTER);
        text(boxNum+1, width - (x + boxWidth / 2), y + boxHeight / 2);

        boxNum++;
      }
    }

    if (frameCount % 2 == 0) {
      sendOsc(downPix);
    }

    fill(0);
    text("Sending 100 inputs to port 6448 using message /wek/inputs", 10, 10);
  }
}


float cropRight = 0;
float cropLeft = 0;

void oscEvent(OscMessage theOscMessage) {
  cropLeft = theOscMessage.get(0).floatValue();
  cropRight = theOscMessage.get(1).floatValue();
}

float diff(int p, int off) {
  if (p + off < 0 || p + off >= numPixels)
    return 0;
  return red(video.pixels[p+off]) - red(video.pixels[p]) +
    green(video.pixels[p+off]) - green(video.pixels[p]) +
    blue(video.pixels[p+off]) - blue(video.pixels[p]);
}

void sendOsc(int[] px) {
  OscMessage msg = new OscMessage("/wek/inputs");
  // msg.add(px);
  for (int i = 0; i < px.length; i++) {
    msg.add(float(px[i]));
  }
  oscP5.send(msg, dest);
}
