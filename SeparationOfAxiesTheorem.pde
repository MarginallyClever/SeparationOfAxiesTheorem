// Separation of axies theorem with boxes in 2D.
// 2020-02-18 Dan Royer (dan@marginallyclever.com)
//
// Special thanks to https://gamedevelopment.tutsplus.com/tutorials/collision-detection-using-the-separating-axis-theorem--gamedev-169


class Box {
  Point2D center;
  Point2D linearVelocity;
  
  float angle, angularVelocity;  // degrees

  float boxWidth, boxHeight;

  Point2D [] p;  // stores working values while doing intersection tests.
  boolean isDirty;

  Box() {
    center = new Point2D();
    linearVelocity = new Point2D();
    
    angle = angularVelocity = 0;

    p = new Point2D[4];
    for(int i=0;i<p.length;++i) p[i] = new Point2D();
    isDirty=false;
  }
  
  void updatePoints() {
    if(!isDirty ) return;
    isDirty=false;
    
    float w = boxWidth/2 + 1;
    float h = boxHeight/2 + 1;
    p[0].set(-w, -h);
    p[1].set( w, -h);
    p[2].set( w,  h);
    p[3].set(-w,  h);
    
    for (int i = 0; i < p.length; ++i) {
      float x = p[i].x;
      float y = p[i].y;
      float c = cos(radians(angle));
      float s = sin(radians(angle));
      // System.out.print("\t"+p[i]);
      p[i].x = c * x -s * y + center.x;
      p[i].y = s * x +c * y + center.y;
      // System.out.println(" >> "+p[i]);
    }
  }
  
  void render(float strokeBox,float strokeP) {
    // visible features in local space
    stroke(strokeBox);
    pushMatrix();
      translate(center.x,center.y);
      rotate(radians(angle));
      // edges
      rect( -boxWidth/2,
            -boxHeight/2,
            boxWidth,
            boxHeight );
    popMatrix();
            
    // center and normals
    pushMatrix();
      translate(center.x,center.y);
      float c = cos(radians(angle))*10;
      float s = sin(radians(angle))*10;
      stroke(255,0,0);  line(0,0,  c, s);
      stroke(0,255,0);  line(0,0, -s, c);
    popMatrix();
    
    // collision bounds in world space
    stroke(0,0,strokeP);
    beginShape();
    for( Point2D pN : p ) {
      vertex( pN.x, pN.y );
    }
    endShape(CLOSE);
  }
}

// globals

Box [] border = new Box[4];
ArrayList<Box> movingBoxes = new ArrayList<Box>();

long tLast;  // animation timing


// methods

void setup() {
  size(800,800);

  // setup border
  border[0] = new Box();
  border[0].center.x = width/2;
  border[0].center.y = 20;
  border[0].boxWidth=width;
  border[0].boxHeight=40;
  border[0].isDirty=true;
  border[0].updatePoints();

  border[1] = new Box();
  border[1].center.x = width/2;
  border[1].center.y = height-20;
  border[1].boxWidth=width;
  border[1].boxHeight=40;
  border[1].isDirty=true;
  border[1].updatePoints();

  border[2] = new Box();
  border[2].center.x = 20;
  border[2].center.y = height/2;
  border[2].boxWidth=40;
  border[2].boxHeight=height;
  border[2].isDirty=true;
  border[2].updatePoints();

  border[3] = new Box();
  border[3].center.x = width-20;
  border[3].center.y = height/2;
  border[3].boxWidth=40;
  border[3].boxHeight=height;
  border[3].isDirty=true;
  border[3].updatePoints();

  // setup moving boxes
  Box moving;
  boolean hit;
  
  for(int i=0;i<10;++i) {
    moving = new Box();
    moving.boxWidth = random(20,width/5);
    moving.boxHeight = random(20,height/5);
    
    do {
      moving.center.x = random( moving.boxWidth /2, width  - moving.boxWidth /2);
      moving.center.y = random( moving.boxHeight/2, height - moving.boxHeight/2);
      moving.isDirty=true;
      hit = false;
      for(int j=0;j<border.length;++j) {
        if(testBoxBox(moving,border[j])) {
          hit=true;
        }
      }
    } while(hit);
    
    moving.linearVelocity.x = random( -250, 250 );
    moving.linearVelocity.y = random( -250, 250 );
    moving.angle=random(0,360);
    moving.angularVelocity=random(-180,180);
    movingBoxes.add(moving);
  }
  tLast = 0;
}

void draw() {
  // update
  long tNow = millis();
  //if( tNow - tLast >= 30 )
  {
    float dt = (tNow - tLast ) * 0.0001;
    tLast = tNow;
  
    // step through all objects
    for( Box moving : movingBoxes ) {
      moving.angle += moving.angularVelocity*dt;
      moving.center.x += moving.linearVelocity.x * dt;
      moving.center.y += moving.linearVelocity.y * dt;
      moving.isDirty=true;
      moving.updatePoints();
      
      for(int i=0;i<border.length;++i) {
        if(testBoxBox(moving,border[i])) {
          // back up so there is no collision
          moving.angle -= moving.angularVelocity*dt;
          moving.center.x -= moving.linearVelocity.x * dt;
          moving.center.y -= moving.linearVelocity.y * dt;
          moving.isDirty=true;
          moving.updatePoints();
          
          // very crude!  Does not adjust angular and linear velocities according to size/mass.
          // flip the angular velocity
          moving.angularVelocity *= -1;
          switch(i) {
            case 0:  // top
            case 1:  // bottom
              moving.linearVelocity.y *= -1;
              break;
            case 2:  // left
            case 3:  // right
              moving.linearVelocity.x *= -1;
              break;
            default:  // never called
              moving.linearVelocity.x = 0;
              moving.linearVelocity.y = 0;
              break;
          }
        }
      }
    }
  }
  
  // draw at max FPS
  
  background(192);
  
  noFill();
  for(int i=0;i<border.length;++i) {
    border[i].render(0,32);
  }
  
  noFill();
  for( Box moving : movingBoxes ) { 
    moving.render(255,200);
  }
}


// return true if boxes a and b overlap.
boolean testBoxBox(Box a,Box b) {
  // only does the second test if the first test succeeds.
  return testBoxBoxInternal(a,b) &&
         testBoxBoxInternal(b,a);
}


// do not call this one directly.  call testBoxBox instead!
boolean testBoxBoxInternal(Box a, Box b) {
  //final String axis = "xy";

  // get the normals for A
  Point2D[] n = new Point2D[2];
  float c = cos(radians(a.angle));
  float s = sin(radians(a.angle));
  n[0] = new Point2D(  c, s);
  n[1] = new Point2D( -s, c);
  
  a.updatePoints();
  b.updatePoints();

  for (int i = 0; i < n.length; ++i) {
    // SATTest the normals of A against the points of box A.
    // SATTest the normals of A against the points of box B.
    // points of each box are a combination of the box's top/bottom values.
    float[] aLim = SATTest(n[i], a.p);
    float[] bLim = SATTest(n[i], b.p);
    //System.out.println( axis.charAt(i)
    //  +" "+nf(n[i].x,3,2)+" "+nf(n[i].y,3,2)
    //  +" : "+nf(aLim[0],3,2)+","+nf(aLim[1],3,2)
    //  +" vs "+nf(bLim[0],3,2)+","+nf(bLim[1],3,2) );

    // if the two box projections do not overlap then there is no chance of a
    // collision.
    if (!overlaps(aLim[0], aLim[1], bLim[0], bLim[1])) {
      //println("Miss");
      return false;
    }
  }

  // intersect!
  //println("Hit");
  return true;
}
  
boolean isBetween(double val, double bottom, double top) {
  return bottom <= val && val <= top;
}

boolean overlaps(double a0, double a1, double b0, double b1) {
  return isBetween(b0, a0, a1) || isBetween(a0, b0, b1);
}

float[] SATTest(Point2D normal, Point2D [] corners) {
  float[] values = new float[2];
  values[0] = Float.MAX_VALUE; // min value
  values[1] = -Float.MAX_VALUE; // max value

  for (int i = 0; i < corners.length; ++i) {
    float dotProduct = corners[i].x * normal.x + corners[i].y * normal.y;
    if (values[0] > dotProduct) values[0] = dotProduct;
    if (values[1] < dotProduct) values[1] = dotProduct;
  }

  return values;
}
