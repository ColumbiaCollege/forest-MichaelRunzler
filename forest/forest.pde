import java.awt.Point;
import java.util.Random;

final color SKY_COLOR = color(96, 192, 255);
final color GROUND_COLOR = color(172, 96, 48);
final float SKY_PERCENTAGE = 0.33f;
final int TREE_COUNT =10;
final Tree[] trees = new Tree[TREE_COUNT];
Random rng;

color currentStroke = color(0);

void setup()
{
  rng = new Random(System.currentTimeMillis());
  size(800, 600);
  background(color(255));
  
  drawBackground();
  
  int maxSkyY = (int)(height * SKY_PERCENTAGE);
  for(int i = 0; i < TREE_COUNT; i++)
  {
    // Generate X and Y coordinates for this tree. Values are bounded to make sure
    // that the tree remains at least partially within the viewport on generation.
    int genX = rng.nextInt(width - Tree.DEFAULT_SIZE_X);
    int genY = rng.nextInt(height - (maxSkyY + Tree.DEFAULT_SIZE_Y));
    genY += (maxSkyY);
     
    // Calculate relative parallax factor based on Y coordinate to simulate distance.
    float vHeightScale = ((float)genY - (float)maxSkyY) / ((float)height - (float)maxSkyY);
    float parallax = 100.0f - ((vHeightScale / 2) * 100.0f);
    println(i + ":" + "" + vHeightScale + parallax);
    
    // Generate tree object and store it
    trees[i] = new Tree(genX, genY, 100.0f, parallax);
  }
}

void draw()
{
  drawBackground();
  
  for(Tree t : trees){
    if(t.currentX > width + t.correctedW){
      t.setXPos(-(t.correctedW * 2));
    }
    t.drawObject();
  }
}

void drawBackground()
{
  // Calculate sky proportions
  float skyMaxY = height * SKY_PERCENTAGE;
  // Cache previous stroke color and enable state
  color prevStroke = currentStroke;
  
  // Draw background sky and ground with proper proportions
  noStroke();
  fill(SKY_COLOR);
  rect(0, 0, width, skyMaxY);
  
  fill(GROUND_COLOR);
  rect(0, skyMaxY, width, height - skyMaxY);
  
  // Reset stroke type back to previous settings
  if(prevStroke == -1) noStroke();
  else stroke(prevStroke);
}

// Override of the superclass stroke() method that caches the
// set color locally before executing the change.
@Override
public void stroke(color c){
  super.stroke(c);
  this.currentStroke = c;
}

// Override of the superclass noStroke() method that updates the
// set color locally before executing the change.
@Override
public void noStroke()
{
  super.noStroke();
  this.currentStroke = -1;
}


class Tree
{
  // Default sizes for this object with 100.0 as the size modifier.
  // These sizes are not the exact size of the object, they can be visualized
  // as the size of the smallest rectangle required to completely cover this object.
  public static final int DEFAULT_SIZE_X = 60;
  public static final int DEFAULT_SIZE_Y = 100;
  
  // Amount the object moves in the X axis per frame drawn with parallax of 0.
  public static final float DELTA_X_PER_FRAME = 0.05;
  
  // Sizes for the trunk and canopy subelements, these are automatically defined from the overall size
  private final Point TRUNK_SIZE = new Point(DEFAULT_SIZE_X / 4, (int)(DEFAULT_SIZE_Y * 0.66));
  private final Point CANOPY_SIZE = new Point(DEFAULT_SIZE_X, (int)(DEFAULT_SIZE_Y * 0.33));
  
  // Fill colors
  private final color TRUNK_COLOR = color(140, 64, 24);
  private final color CANOPY_COLOR = color(96, 255, 96);
  
  // Private internal tracking variables
  public int x;
  public int y;
  private float deltaP;
  private float size;
  
  public float currentX;
  public float correctedW = DEFAULT_SIZE_X * size;
  public float correctedH = DEFAULT_SIZE_Y * size;
  
  /**
   * Represents a drawable "tree"-like object that can self-animate.
   * @param x the initial X coordinate of this object on the canvas
   * @param y the initial Y coordinate of this object on the canvas
   * @param size the percentage of the default size that this object should be.
   *        Negative values will be ignored. A value of 0 will disable rendering of
   *        the object entirely.
   * @param parallax the amout of parallaxing that should be applied when this object animates.
   *        Parallax values >0 will animate the object moving faster than the default speed,
   *        while values <0 will animate the object slower than the default. Parallax values
   *        are given in percent, with values bounded at -100 (stopped).
   */
  public Tree(int x, int y, float size, float parallax)
  {
    this.x = x;
    this.y = y;
    this.deltaP = parallax / 100.0f;
    this.size = (size / 100.0f);
    this.currentX = this.x;
  }
  
  /**
   * Draws this object and increments its position after drawing has completed.
   * Calling this method repeatedly in a loop will result in the object "animating".
   */
  public void drawObject()
  {
    fill(TRUNK_COLOR);
    rect(currentX + ((correctedW / 2) - (TRUNK_SIZE.x / 2)), y + correctedH, TRUNK_SIZE.x * size, TRUNK_SIZE.y * size);
    
    fill(CANOPY_COLOR);
    ellipse(currentX, y, CANOPY_SIZE.x * size, CANOPY_SIZE.y * size);
    
    currentX += (DELTA_X_PER_FRAME * deltaP);
  }
  
  /**
   * Sets this object's current draw position to the specified X position.
   * Any successive calls to drawObject will animate from this new position.
   */
  public void setXPos(float x){
    currentX = x;
  }
  
  /**
   * Resets this object's draw position to its initial coordinates, as if it was just initialized.
   */
  public void resetPosition(){
    currentX = x;
  }
}
