
boolean inWindowX(float x){
  return (0.0 <= x && x < width);
}
boolean inWindowY(float y){
  return (0.0 <= y && y < height);
}

boolean isHit(float x1, float y1, float x2, float y2, float r){
  return (sq(x1 - x2) + sq(y1 - y2) <= sq(r));
}

float angle(float x1, float y1, float x2, float y2){
  return -atan2(x2 - x1, y2 - y1) + PI / 2.0;
}

abstract class Material {
  public Material(MaterialType atype, float ax, float ay, int ahp, float ar){
    type = atype;
    
    mX = ax;
    mY = ay;
    mHP = ahp;
    mRadius = ar;
  }
  
  public void update(){
    mX += vx;
    mY += vy;
  }
  
  public void draw(){
    /*
    fill(255, 0, 0);
    ellipse(x(), y(), radius() * 2, radius() * 2);
    noFill();
    */
  }
  
  public float x(){
    return mX;
  }
  public float y(){
    return mY;
  }
  public int HP(){
    return mHP;
  }
  public float radius(){
    return mRadius;
  }
  
  public void damage(int val){
    mHP -= val;
    if(mHP <= 0){
      mHP = 0;
      delete();
    }
  }
  public void delete(){
    mIsDeleted = true;
  }
  public boolean isDeleted(){
    return mIsDeleted;
  }
  
  public boolean isHit(Material m){
    return (sq(mX - m.mX) + sq(mY - m.mY) <= sq(mRadius + m.mRadius));
  }
  
  public final MaterialType type;
  
  private float mX, mY;
  public float vx = 0.0, vy = 0.0;
  private int mHP = 0;
  private float mRadius;
  
  private boolean mIsDeleted = false;
}

class Bullet extends Material{
  public Bullet(float ax, float ay, int ahp, float ar, float arr, float avx, float avy, MaterialType aparentType){
    super(MaterialType.Bullet, ax, ay, ahp, ar);
    mRealRadius = arr;
    vx = avx;
    vy = avy;
    mParentType = aparentType;
  }
  
  @Override
  public void update(){
    super.update();
    if(!inWindowX(x()) || !inWindowY(y())) delete();
  }
  
  @Override
  public void draw(){
    ellipse(x(), y(), mRealRadius * 2, mRealRadius * 2);
    super.draw();
  }
  
  public MaterialType parentType(){
    return mParentType;
  }
  
  private MaterialType mParentType;
  
  private float mRealRadius;
}

class Fighter extends Material{
  public Fighter(float ax, float ay, int ahp, float ar){
    super(MaterialType.Fighter, ax, ay, ahp, ar);
  }
  
  @Override
  public void update(){
    double a = 1.0;
    if(mIsSlow) a = 0.3;
    vx *= a;
    vy *= a;
    if(!inWindowX(x() + vx)) vx = 0.0;
    if(!inWindowY(y() + vy)) vy = 0.0;
    super.update();
   
    if(mIsGMode){ 
      for(Material b : mats){
        if(b.type == MaterialType.Fighter) continue;
        //if(b.type == MaterialType.Bullet && ((Bullet)b).parentType() == type) continue;
        
        float t = angle(x(), y(), b.x(), b.y());
        float len = dist(0, 0, b.vx, b.vy);
        b.vx -= cos(t) * .4;
        b.vy -= sin(t) * .4;
        float len2 = dist(0, 0, b.vx, b.vy);
        b.vx = b.vx / len2 * len;
        b.vy = b.vy / len2 * len;
      }
      
      mG += 0.5;
    }
    else{
      mG -= 0.2;
      if(mG <= 0.0) mG = 0.0;
    }
    
    switch(mCM){
      case Inc:
        if(mCount >= 5.0){
          mCount = 5.0;
          mCM = CountMode.None;
          break;
        }
        mCount += 0.7;
        break;
      case Dec:
        if(mCount <= 0.0){
          mCount = 0.0;
          mCM = CountMode.None;
          break;
        }
        mCount -= 0.7;
        break;
    }
  }
  
  @Override
  public void draw(){
    triangle(x(), y() - 20, x() - 20, y() + 20, x() + 20, y() + 20);
    ellipse(x(), y(), radius() * 2, radius() * 2);
    fill(mG / 100.0 * 255);
    text(str(int(mG)), x(), y());
    noFill();
    super.draw();
  }
  
  public void shoot(){
    mats.add(new Bullet(x() - 10.0, y(), 1, 3.0, 3.0, -mCount, -30.0, MaterialType.Fighter));
    mats.add(new Bullet(x(), y(), 1, 3.0, 3.0, 0.0, -30.0, MaterialType.Fighter));
    mats.add(new Bullet(x() + 10.0, y(), 1, 3.0, 3.0, mCount, -30.0, MaterialType.Fighter));
  }
  
  public void setIsSlow(boolean b){
    if(b){
      mCM = CountMode.Dec;
    }
    else{
      mCM = CountMode.Inc;
    }
    mIsSlow = b;
  }
  
  public void setIsGMode(boolean b){
    mIsGMode = b;
  }
  public float G(){
    return mG;
  }
  
  private float mCount = 5.0;
  private CountMode mCM = CountMode.None;
  
  private boolean mIsSlow = false;
  
  private boolean mIsGMode = false;
  private float mG = 0.0;
}

class Enemy extends Material{
  public Enemy(float ax, float ay, int ahp, float ar){
    super(MaterialType.Enemy, ax, ay, ahp, ar);
  }
  
  @Override
  public void update(){
    super.update();
    
    if(mCount >= 60 / 10){
      mCount = 0;
      mats.add(new Bullet(x(), y(), 1, 2.0, 5.0, 0.0, 5.0, MaterialType.Enemy));
      /*
      float base = angle(x(), y(), hero.x(), hero.y());
      for(int i = 0;i < 36;i++){
        float a = base + i * 2.0 * PI / 36.0;
        float tvx = cos(a) * 5.0, tvy = sin(a) * 5.0;
        mats.add(new Bullet(x(), y(), 1, 2.0, 5.0, tvx, tvy, MaterialType.Enemy));
      }
      */
    }
    mCount++;
  }
  
  @Override
  public void draw(){
    rect(x() - radius(), y() - radius(), radius() * 2, radius() * 2);
    super.draw();
  }
  
  private int mCount = 0;
}

class PointItem extends Material{
  PointItem(float ax, float ay, float ar){
    super(MaterialType.PointItem, ax, ay, 1, ar);
  }
  
  @Override
  public void update(){
    float a = angle(x(), y(), hero.x(), hero.y());
    vx = cos(a) * 7.0;
    vy = sin(a) * 7.0;
    
    super.update();
  }
  
  @Override
  public void draw(){
    rect(x() - radius(), y() - radius(), radius() * 2, radius() * 2);
    super.draw();
  }
}

//int[] strongerThan = new int[MaterialType.size];

int alphaKeyCode(char c){
  return 65 + c - 'a';
}

/*
ArrayList<Material> filterType(ArrayList<Material> mats, MaterialType type){
  ArrayList<Material> ret = new ArrayList<Material>();
  for(Material m : mats){
    if(m.type == type) ret.add(m);
  }
  return ret;
}

ArrayList<Material> filterTypeNot(ArrayList<Material> mats, MaterialType type){
  ArrayList<Material> ret = new ArrayList<Material>();
  for(Material m : mats){
    if(m.type != type) ret.add(m);
  }
  return ret;
}
*/

boolean[] keys = new boolean[256];
boolean[] keysPrev = new boolean[256];

ArrayList<Material> mats = new ArrayList<Material>();
Fighter hero = null;
Fighter hero2 = null;

int point = 0;

void setup() {
  size(400, 600);
  
  frameRate(60);
  
  //noSmooth();
  
  for (int i = 0;i < keys.length;i++) {
    keys[i] = keysPrev[i] = false;
  }

  hero = new Fighter(width / 2, height / 3 * 2, 1, 4.0);
  mats.add(hero);
  
  hero2 = new Fighter(width / 2, height / 4 * 3, 1, 4.0);
  //mats.add(hero2);
  
  mats.add(new Enemy(width / 3, height / 3, 1, 50.0));
  mats.add(new Enemy(width / 3 * 2, height / 3, 100, 25.0));
}

int prevShootFrame = 0;
void draw() {
  
  if(hero.isDeleted()) mats.add(hero = new Fighter(width / 2, height / 3 * 2, 1, 4.0));
  
  hero.setIsSlow(keys[SHIFT]);
  
  hero.vx = hero.vy = 0.0;
  if(keys[UP]) hero.vy = -5.0;
  if(keys[DOWN]) hero.vy = 5.0;
  if(keys[LEFT]) hero.vx = -5.0;
  if(keys[RIGHT]) hero.vx = 5.0;
  
  hero2.vx = hero.vx;
  hero2.vy = hero.vy;
  
  if(keys[alphaKeyCode('z')]){
    if(frameCount - prevShootFrame >= 2){
      hero.shoot();
      
      //hero2.shoot();
      
      prevShootFrame = frameCount;
    }
  }
  
  hero.setIsGMode(keys[alphaKeyCode('x')]);
  
  if(keys[alphaKeyCode('c')]){
    if(hero.G() >= 100.0){
      int size = mats.size();
      for(int i = 0;i < size;i++){
        Material b = mats.get(i);
        
        if(b.type != MaterialType.Bullet) continue;
        if(((Bullet)b).parentType() == MaterialType.Fighter) continue; //<>//
        mats.add(new PointItem(b.x(), b.y(), 7));
        b.delete();
      }
    }
  }
  
  int hitCount = 0;
  for(Material f : mats){
    if(f.type != MaterialType.Fighter) continue;
    for(Material m : mats){
      if(m.type == MaterialType.Fighter || m.type == MaterialType.PointItem) continue;
      if(isHit(f.x(), f.y(), m.x(), m.y(), 100)){
        hitCount++;
      }
    }
  }
  if(hitCount > 20) frameRate(max(20, 60 - hitCount));
  else frameRate(60);

  int size = mats.size();
  for(int i = 0;i < size;i++) mats.get(i).update();
  
  //Bullet->~Bullet
  for(Material b : mats){
    if(b.type != MaterialType.Bullet) continue;
    
    for(Material m : mats){
      if(m.type == MaterialType.Bullet || m.type == MaterialType.PointItem) continue;
      
      if(((Bullet)b).parentType() != m.type && b.isHit(m)){
        b.damage(1);
        m.damage(1);
      }
    }
  }
  
  //Enemy->Fighter
  for(Material e : mats){
    if(e.type != MaterialType.Enemy) continue;
    for(Material f : mats){
      if(f.type != MaterialType.Fighter) continue;
      if(e.isHit(f)){
        f.damage(1);
        e.damage(1);
      }
    }
  }
  
  //ItemPoint->Fighter
  for(Material p : mats){
    if(p.type != MaterialType.PointItem) continue;
    for(Material f : mats){
      if(f.type != MaterialType.Fighter) continue;
      if(p.isHit(f)){
        point++;
        p.delete();
      }
    }
  }
  
  for(int i = 0;i < mats.size();i++){
    if(mats.get(i).isDeleted()){
      mats.remove(i);
    }
  }
  
  background((100.0 - hero.G()) / 100.0 * 255);
  stroke(hero.G() / 100.0 * 255);
  
  for(Material m : mats) m.draw();
  
  fill(hero.G() / 100.0 * 255);
  text("Point:" + str(int(point)), 0, 10);
  noFill();
}

void keyPressed() {
  for (int i = 0;i < keys.length;i++) {
    keysPrev[i] = keys[i];
    if (i == keyCode) {
      keys[i] = true;
      break;
    }
  }
}

void keyReleased() {
  for (int i = 0;i < keys.length;i++) {
    keysPrev[i] = keys[i];
    if (i == keyCode) {
      keys[i] = false;
      break;
    }
  }
}
