import java.awt.Point;
import java.util.Random;

final color SKY_COLOR = color(96, 192, 255);
final color GROUND_COLOR = color(172, 96, 48);
final float SKY_PERCENTAGE = 0.33f; // How much of the scene is sky
final int TREE_COUNT = 15; // Max number of trees in the scene
final float PARALLAX_FACTOR = 1.5f; // Modifier for how much parallaxing is applied, 0.0 is off

// Instance storage
Tree[] trees = new Tree[TREE_COUNT];
Random rng;

// Don't worry about this, it's an "optimization" ;)
color currentStroke = color(0);

void setup()
{
  // Set size, initialize and seed RNG, set background color (not that it matters)
  rng = new Random(System.currentTimeMillis());
  size(800, 600);
  background(color(255));
  
  // The maximum Y coordinate of the sky relative to the ground
  float maxSkyY = height * SKY_PERCENTAGE;
  
  // Generate the row Y-coordinates for the trees
  int[] rows = new int[(int)((height - maxSkyY) / Tree.DEFAULT_SIZE_Y)];
  int counter = (int)maxSkyY;
  for(int i = 0; i < rows.length; i++){
    rows[i] = counter;
    counter += Tree.DEFAULT_SIZE_Y;
  }
  
  // Generate the row X-coordinates for the trees
  int[] columns = new int[(int)(width / Tree.DEFAULT_SIZE_X)];
  counter = 0;
  for(int i = 0; i < columns.length; i++){
    columns[i] = counter;
    counter += Tree.DEFAULT_SIZE_X;
  }
  
  // Generate tree objects and store them
  for(int i = 0; i < TREE_COUNT; i++)
  {
    // Generate X and Y coordinates for this tree. Values are bounded to make sure
    // that the tree remains at least partially within the viewport on generation.
    int genX = columns[rng.nextInt(columns.length)];
    int genY = rows[rng.nextInt(rows.length)];
     
    // Calculate relative parallax factor based on Y coordinate to simulate distance
    float vHeightScale = ((float)genY - (float)maxSkyY) / ((float)height - (float)maxSkyY);
    float parallax = vHeightScale * 100.0f;
    
    // Generate tree object and store it
    trees[i] = new Tree(genX, genY, 100.0f, 100.0f + (parallax * PARALLAX_FACTOR));
  }
}

void draw()
{
  // Redraw background
  drawBackground();
  
  // Wrap around if the tree has gone off of the canvas. Due to how Processing deals with offscreen
  // draw coordinates, the tree can't smoothly re-enter the frame (since rect() doesn't like negative coordinates),
  // so we just set it to 0.
  for(Tree t : trees){
    if(t.currentX > width)t.setXPos(-100);
    t.drawObject();
  }
}

/**
 * Draw (or re-draw) the sky and ground.
 */
void drawBackground()
{
  // Calculate sky proportions
  float maxSkyY = height * SKY_PERCENTAGE;
  // Cache previous stroke color and enable state
  color prevStroke = currentStroke;
  
  // Draw background sky and ground with proper proportions
  noStroke();
  
  fill(GROUND_COLOR);
  rect(0, maxSkyY, width, height - maxSkyY);
  
  fill(SKY_COLOR);
  rect(0, 0, width, maxSkyY);
  
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
public void noStroke(){
  super.noStroke();
  this.currentStroke = -1;
}


/** 
 * Contains animation and instance variable state storage code for each tree on the canvas.
 */
class Tree
{
  // Default sizes for this object with 100.0 as the size modifier.
  // These sizes are not the exact size of the object; they can be visualized
  // as the size of the smallest rectangle required to completely cover this object.
  public static final int DEFAULT_SIZE_X = 60;
  public static final int DEFAULT_SIZE_Y = 100;
  
  // Amount the object moves in the X axis per frame drawn with parallax of 100.
  public static final float DELTA_X_PER_FRAME = 2.0f;
  
  // Sizes for the trunk and canopy subelements, these are automatically defined from the overall size
  private final Point TRUNK_SIZE = new Point((int)(DEFAULT_SIZE_X / 4), (int)(DEFAULT_SIZE_Y * 0.66));
  private final Point CANOPY_SIZE = new Point(DEFAULT_SIZE_X, (int)(DEFAULT_SIZE_Y * 0.33));
  
  // Fill colors
  private final color TRUNK_COLOR = color(140, 64, 24);
  private final color CANOPY_COLOR = color(96, 255, 96);
  
  // Private internal tracking variables
  private int x;
  private int y;
  private float deltaP;
  private float size;
  
  public float currentX;
  public float correctedW;
  public float correctedH;
  
  /**
   * Represents a drawable "tree"-like object that can self-animate.
   * @param x the initial X coordinate of this object on the canvas
   * @param y the initial Y coordinate of this object on the canvas
   * @param size the percentage of the default size that this object should be.
   *        Negative values will be ignored. A value of 0 will disable rendering of
   *        the object entirely.
   * @param parallax the amout of parallaxing that should be applied when this object animates.
   *        Parallax values >100 will animate the object moving faster than the default speed,
   *        while values <100 will animate the object slower than the default. Parallax values
   *        are given in percent, with values bounded at -100 (stopped).
   */
  public Tree(int x, int y, float size, float parallax)
  {
    this.x = x;
    this.y = y;
    
    // Bound parallaxing and size at -100
    parallax = parallax < -100.0f ? -100.0f : parallax;
    size = size < -100.0f ? -100.0f : size;
    
    // Set instance variables
    this.deltaP = parallax / 100.0f;
    this.size = (size / 100.0f);
    this.currentX = this.x;
    this.correctedW = DEFAULT_SIZE_X * this.size;
    this.correctedH = DEFAULT_SIZE_Y * this.size;
  }
  
  /**
   * Draws this object and increments its position after drawing has completed.
   * Calling this method repeatedly in a loop will result in the object "animating".
   */
  public void drawObject()
  {
    // Draw trunk
    fill(TRUNK_COLOR);
    rect(currentX + ((correctedW / 2) - ((TRUNK_SIZE.x * size) / 2)), y + CANOPY_SIZE.y, TRUNK_SIZE.x * size, TRUNK_SIZE.y * size);
    
    // Draw canopy
    ellipseMode(CORNER);
    fill(CANOPY_COLOR);
    ellipse(currentX, y, CANOPY_SIZE.x * size, CANOPY_SIZE.y * size);
    ellipseMode(CENTER);
    
    // Increment X-coordinate counter for animation stage
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
