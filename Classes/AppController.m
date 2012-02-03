#import "AppController.h"
#import "global.h"
#import "CMOpenALSoundManager.h"
#import "Data.h"
#import "UKImage.h"



//CONSTANTS:


#define kPaletteHeight					30
#define kPaletteSize				    5
#define kAccelerometerFrequency			25 //Hz
#define kFilteringFactor				0.5
#define kMinEraseInterval				1
#define kEraseAccelerationThreshold		5.0

// Padding for margins
#define kLeftMargin				10.0
#define kTopMargin				10.0
#define kRightMargin			10.0




#define KURO	0
#define SHIRO	1




#define INK_FOR_ONE_DOT 26
// Maximum quantity of ink in stock
#define INK_MAX 1024
// Ratio between ink value and ink meter
#define INK_RATIO 32
// Maximum number of lines
#define NB_LINES_MAX 14
// Gravity
#define GRAVITY 4
// Music duration (frames)
#define MUSIC_DURATION 15000

// Sprite palette number
#define SPRITE_PALETTE_NB 0
// Sprite numbers on upper screen
#define SPRITE_NB_ARROW 10
#define SPRITE_NB_INK_BLACK 15
#define SPRITE_NB_INK_BLACK_BG 16
#define SPRITE_NB_INK_WHITE 17
// Sprite numbers on bottom screen
#define SPRITE_NB_CHUO_BLACK 10
#define SPRITE_NB_CHUO_WHITE 11
#define SPRITE_NB_FLAG_BLACK 20
#define SPRITE_NB_FLAG_WHITE 21

// Blob parameters
#define CHUO_ANIM_SPEED_IDLE 5
#define CHUO_V_MAX_SPEED 12
#define CHUO_LAND 12
// Hit box
#define CHUO_HITBOX_X_RIGHT 20
#define CHUO_HITBOX_X_LEFT 0
#define CHUO_HITBOX_X_MIDDLE 10
#define CHUO_HITBOX_Y_TOP 0
#define CHUO_HITBOX_Y_BOTTOM 20
#define CHUO_HITBOX_Y_MIDDLE 10

// Flag parameters
#define FLAG_ANIM_SPEED 10

//==============================================================================

// Color
typedef enum {
	COLORBLACK = 0,
	COLORWHITE = 1
} T_COLOR;

#define COLOR_BLACK_VALUE 1
#define COLOR_WHITE_VALUE 2

typedef enum
	{
		CHUO_STATE_STAND = 0,
		CHUO_STATE_FALL,
		CHUO_STATE_LAND,
		CHUO_STATE_DEAD
	}
	T_CHUO_STATE;



 
//FUNCTIONS:
/*
   HSL2RGB Converts hue, saturation, luminance values to the equivalent red, green and blue values.
   For details on this conversion, see Fundamentals of Interactive Computer Graphics by Foley and van Dam (1982, Addison and Wesley)
   You can also find HSL to RGB conversion algorithms by searching the Internet.
   See also http://en.wikipedia.org/wiki/HSV_color_space for a theoretical explanation
 */
static void HSL2RGB(float h, float s, float l, float* outR, float* outG, float* outB)
{
	float			temp1,
					temp2;
	float			temp[3];
	int				i;
	
	// Check for saturation. If there isn't any just return the luminance value for each, which results in gray.
	if(s == 0.0) {
		if(outR)
			*outR = l;
		if(outG)
			*outG = l;
		if(outB)
			*outB = l;
		return;
	}
	
	// Test for luminance and compute temporary values based on luminance and saturation 
	if(l < 0.5)
		temp2 = l * (1.0 + s);
	else
		temp2 = l + s - l * s;
		temp1 = 2.0 * l - temp2;
	
	// Compute intermediate values based on hue
	temp[0] = h + 1.0 / 3.0;
	temp[1] = h;
	temp[2] = h - 1.0 / 3.0;

	for(i = 0; i < 3; ++i) {
		
		// Adjust the range
		if(temp[i] < 0.0)
			temp[i] += 1.0;
		if(temp[i] > 1.0)
			temp[i] -= 1.0;
		
		
		if(6.0 * temp[i] < 1.0)
			temp[i] = temp1 + (temp2 - temp1) * 6.0 * temp[i];
		else {
			if(2.0 * temp[i] < 1.0)
				temp[i] = temp2;
			else {
				if(3.0 * temp[i] < 2.0)
					temp[i] = temp1 + (temp2 - temp1) * ((2.0 / 3.0) - temp[i]) * 6.0;
				else
					temp[i] = temp1;
			}
		}
	}
	
	// Assign temporary values to R, G, B
	if(outR)
		*outR = temp[0];
	if(outG)
		*outG = temp[1];
	if(outB)
		*outB = temp[2];
}

//CLASS IMPLEMENTATIONS:

@implementation AppController
@synthesize scorelevel;

- (NSString *)dataFilePath {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentDirectory = [paths objectAtIndex:0];
	return [documentDirectory stringByAppendingPathComponent:@"shirodata"];
}

-(void) applicationWillTerminate:(NSNotification *)notification {
	Data *savedata = [[Data alloc] init];
	savedata.scorelevel = @"Guardamos datos";
	
	NSMutableData *data = [[NSMutableData alloc] init];
	NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
	[archiver encodeObject:savedata forKey:@"shiroeselmejor"];
	[archiver finishEncoding];
	[data writeToFile:[self dataFilePath] atomically:YES];
	[savedata release];
	[archiver release];
	[data release];
	
}


#pragma mark -


- (void) applicationDidFinishLaunching:(UIApplication*)application
{
	CGRect					rect = [[UIScreen mainScreen] applicationFrame];
	CGFloat					components[3];
	
	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	[window setBackgroundColor:[UIColor blackColor]];
	drawingView = [[PaintingView alloc] initWithFrame:CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)]; // - kPaletteHeight 
	[window addSubview:drawingView];
	started = false;
	
	[NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(gameLoop) userInfo:nil repeats:YES];
	
	HSL2RGB((CGFloat) 2.0 / (CGFloat)kPaletteSize, kSaturation, kLuminosity,  &components[0], &components[1], &components[2]);
	glColor4f(255,255,255, kBrushOpacity);
	[window makeKeyAndVisible];	
	[application setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:NO];
	[application setStatusBarHidden:YES animated:YES];

	gameState = LOAD_SPLASH;
	
	NSString *filePath = [self dataFilePath];
	if([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
		NSData *data = [[NSMutableData alloc] initWithContentsOfFile:[self dataFilePath]];
		NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
		Data *savedata = [unarchiver decodeObjectForKey:@"shiroeselmejor"];
		[unarchiver finishDecoding];
		
		//DO STUFF 
		NSLog(@"SCORE : %d");
		
		[unarchiver release];
		[data release];
	};
	
	
	UIApplication *app = [UIApplication sharedApplication];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:app];
	
	
	gameLevel = 0;
	
	
	
}




- (void) accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*)acceleration
{
	UIAccelerationValue				length,
									x,
									y,
									z;
	
	myAccelerometer[0] = acceleration.x * kFilteringFactor + myAccelerometer[0] * (1.0 - kFilteringFactor);
	myAccelerometer[1] = acceleration.y * kFilteringFactor + myAccelerometer[1] * (1.0 - kFilteringFactor);
	myAccelerometer[2] = acceleration.z * kFilteringFactor + myAccelerometer[2] * (1.0 - kFilteringFactor);
	x = acceleration.x - myAccelerometer[0];
	y = acceleration.y - myAccelerometer[0];
	z = acceleration.z - myAccelerometer[0];
	length = sqrt(x * x + y * y + z * z);
	if((length >= kEraseAccelerationThreshold) && (CFAbsoluteTimeGetCurrent() > lastTime + kMinEraseInterval)) {
		[erasingSound play];
		[drawingView erase];
		lastTime = CFAbsoluteTimeGetCurrent();
	}
}





- (BOOL) chuo_pointIsFree:(int) ctype px:(int) p_x py:(int)p_y {
	CGPoint p;
	p.x = p_x;
	p.y = p_y;
	if((p_x <= 480) && (p_x >= 0) && (p_y <= 320) && (p_y >= 0)) {
		CGPoint point;
		point.y = 480-p.x;
		point.x = 319-p.y;
		Byte pixelColor[4];
		glReadPixels(point.x, point.y, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE, &pixelColor[0]);
		BOOL blanco;
		if((int)pixelColor[0]==255 && (int)pixelColor[1]==255 && (int)pixelColor[2]==255) {
			blanco = TRUE;
		} else { 
			blanco = FALSE;
		}
		if((ctype==KURO && !blanco) || (ctype==SHIRO && blanco)) {
			return true;
		} else {
			return false;
		};
		return false;
	} else {
		return false;
	};
	
	return false;
}

//==============================================================================

-(void) chuo_goToState:(int) ctype :(T_CHUO_STATE) p_newState {
	int m_timer;
	switch(p_newState)
	{
		case CHUO_STATE_STAND:
			m_timer = 0;
			break;
		case CHUO_STATE_FALL:
			m_timer = 0;
			break;
		case CHUO_STATE_LAND:
			m_timer = CHUO_LAND;
			break;
		case CHUO_STATE_DEAD:
			m_timer = 0;
			break;
		default:
			break;
	}
	if(ctype==SHIRO) {
		shiroTimer = m_timer;
		shiroState = p_newState;
	} else {
		kuroTimer = m_timer;
		kuroState = p_newState;
	}
}

//==============================================================================

-(void) chuo_adjustPosition:(int) ctype {
	float m_x, m_y, m_vy = 0;
	if(ctype==SHIRO) {
		m_x = (float)shirop.x;
		m_y = (float)shirop.y;
		m_vy = (float)shirov.y;
	} else {
		m_x = (float)kurop.x;
		m_y = (float)kurop.y;
		m_vy = (float)kurov.y;
	}
	short def = 0;
	// BOTTOM COLLISION
	while((![self chuo_pointIsFree:ctype px:((m_x) + CHUO_HITBOX_X_MIDDLE) py:((m_y) + CHUO_HITBOX_Y_BOTTOM)]) &&
		  ([self chuo_pointIsFree:ctype px:((m_x) + CHUO_HITBOX_X_MIDDLE) py:((m_y) + CHUO_HITBOX_Y_TOP - 1)])) {
		m_y = (int)((m_y) - 1.0);
	}
	// TOP COLLISION
	while((![self chuo_pointIsFree:ctype px:((m_x) + CHUO_HITBOX_X_MIDDLE) py:((m_y) + CHUO_HITBOX_Y_TOP)]) &&
		  ([self chuo_pointIsFree:ctype px:((m_x) + CHUO_HITBOX_X_MIDDLE) py:((m_y) + CHUO_HITBOX_Y_BOTTOM + 1)])) {
		if (m_vy) m_vy = 0;
		m_y = (int)((m_y) + 1.0);
	}
	//LEFT COLLISION
	while(((![self chuo_pointIsFree:ctype px:((m_x) + CHUO_HITBOX_X_LEFT) py:((m_y) + CHUO_HITBOX_Y_MIDDLE)]) &&
		  ([self chuo_pointIsFree:ctype px:((m_x) + CHUO_HITBOX_X_RIGHT+1) py:((m_y) + CHUO_HITBOX_Y_MIDDLE)])) ||
		  ((![self chuo_pointIsFree:ctype px:((m_x) + CHUO_HITBOX_X_LEFT) py:((m_y) + CHUO_HITBOX_Y_MIDDLE+2)]) &&
		  ([self chuo_pointIsFree:ctype px:((m_x) + CHUO_HITBOX_X_RIGHT+1) py:((m_y) + CHUO_HITBOX_Y_MIDDLE+2)]))) {
		m_x = (int)((m_x) + 1.0);
		def = 1;
	}
	//RIGHT COLLISION
	while(((![self chuo_pointIsFree:ctype px:((m_x) + CHUO_HITBOX_X_RIGHT) py:((m_y) + CHUO_HITBOX_Y_MIDDLE)]) &&
		  ([self chuo_pointIsFree:ctype px:((m_x) + CHUO_HITBOX_X_LEFT-1) py:((m_y) + CHUO_HITBOX_Y_MIDDLE)])) ||
		  ((![self chuo_pointIsFree:ctype px:((m_x) + CHUO_HITBOX_X_RIGHT) py:((m_y) + CHUO_HITBOX_Y_MIDDLE+2)]) &&
		 ([self chuo_pointIsFree:ctype px:((m_x) + CHUO_HITBOX_X_LEFT-1) py:((m_y) + CHUO_HITBOX_Y_MIDDLE+2)]))){
		
		m_x = (int)((m_x) - 1.0);
		def = 2;
	}

	if(ctype==SHIRO) {
		shirop.x = (int)m_x;
		shirop.y = (int)m_y;
		shirov.y = (int)m_vy;
		shiroA = def;
	} else {
		kurop.x = (int)m_x;
		kurop.y = (int)m_y;
		kurov.y = (int)m_vy;
		kuroA = def;
	}
	
}

//==============================================================================

-(void) chuo_update:(int) ctype {
	
	if((ctype==SHIRO && shiroA!=3) || (ctype==KURO &&kuroA!=3)) {
		
		
	int m_state = kuroState;
	float m_vy = kurov.y;
	float m_vx = kurov.x;
	float m_y = kurop.y;
	float m_x = kurop.x;
	int m_timer = kuroTimer;
	if(ctype==SHIRO) {
		m_state = shiroState;
		m_vy = shirov.y;
		m_vx = shirov.x;
		m_y = shirop.y;
		m_x = shirop.x;
		m_timer = shiroTimer;
	};

	if (m_state == CHUO_STATE_FALL)
	{
		m_vy += GRAVITY;
		if (m_vy > CHUO_V_MAX_SPEED) { m_vy = CHUO_V_MAX_SPEED; };
		m_y += m_vy;
	}
	
	if(ctype==SHIRO) {
		shirov.y = m_vy;
		shirov.x = m_vx;
		shirop.y = m_y;
		shirop.x = m_x;
		shiroTimer = m_timer;
	} else {
		kurov.y = m_vy;
		kurov.x = m_vx;
		kurop.y = m_y;
		kurop.x = m_x;
		kuroTimer = m_timer;
	}
	//------------------------------------------------------------------------------
	// Adjust position
	[self chuo_adjustPosition:ctype];
	//------------------------------------------------------------------------------
	if(ctype==SHIRO) {
		m_state = shiroState;
		m_vy = shirov.y;
		m_vx = shirov.x;
		m_y = shirop.y;
		m_x = shirop.x;
		m_timer = shiroTimer;
	} else if(ctype==KURO) {
		m_state = kuroState;
		m_vy = kurov.y;
		m_vx = kurov.x;
		m_y = kurop.y;
		m_x = kurop.x;
		m_timer = kuroTimer;
	};
	switch (m_state)
	{
		case CHUO_STATE_STAND:
			// If the blob is the air
			if ([self chuo_pointIsFree:ctype px:((m_x) + CHUO_HITBOX_X_MIDDLE) py:((m_y) + CHUO_HITBOX_Y_BOTTOM + 1)]) {
				[self chuo_goToState:ctype :CHUO_STATE_FALL];
			}
			break;
		case CHUO_STATE_FALL:
			// If the chuo is on the ground
			if (![self chuo_pointIsFree:ctype px:(int)((int)(m_x) + CHUO_HITBOX_X_MIDDLE) py:(int)((int)(m_y) + CHUO_HITBOX_Y_BOTTOM + 1)]) {
				if(m_vy == CHUO_V_MAX_SPEED) {
					[self chuo_goToState:ctype :CHUO_STATE_STAND];
				} else {
					[self chuo_goToState:ctype :CHUO_STATE_LAND];
				}
			}
			break;
		case CHUO_STATE_LAND:
			if (m_timer) {--m_timer;};
			if (!m_timer)  { 
				[self chuo_goToState:ctype :CHUO_STATE_STAND];
			}
			break;
		case CHUO_STATE_DEAD:
			//if (this->health() >= 4) goToState(CHUO_STATE_FALL);
			break;
		default: 
			m_state = CHUO_STATE_FALL;
			break;
	};
	if(ctype==SHIRO) {
		shirov.y = m_vy;
		shirov.x = m_vx;
		shirop.y = m_y;
		shirop.x = m_x;
		shiroTimer = m_timer;
	} else {
		kurov.y = m_vy;
		kurov.x = m_vx;
		kurop.y = m_y;
		kurop.x = m_x;
		kuroTimer = m_timer;
	}
	}
	
}



-(CGPoint) chuo_getCoordinates:(int) ctype {
	CGPoint p;
	if(ctype==SHIRO) {
		p.x = shirop.x;
		p.y = shirop.y;
	} else {
		p.x = kurop.x;
		p.y = kurop.y;
	}
	return p;
}


-(int) chuo_health:(int) ctype {
	
    return 4;//this->pointIsFree((m_x) + CHUO_HITBOX_X_MIDDLE, (m_y) + CHUO_HITBOX_Y_BOTTOM) +
	//this->pointIsFree((m_x) + CHUO_HITBOX_X_MIDDLE, (m_y) + CHUO_HITBOX_Y_TOP) +
	//this->pointIsFree((m_x) + CHUO_HITBOX_X_LEFT, (m_y) + CHUO_HITBOX_Y_MIDDLE) +
	//this->pointIsFree((m_x) + CHUO_HITBOX_X_RIGHT, (m_y) + CHUO_HITBOX_Y_MIDDLE);
}


- (void) doStuff {
	
	width = 64;
	height = 64;

	brushData = (GLubyte *) malloc(width * height * 4);
	brushContext = CGBitmapContextCreate(brushData, width, width, 8, width * 4, CGImageGetColorSpace(brushImage), kCGImageAlphaPremultipliedLast);
	CGContextDrawImage(brushContext, CGRectMake(0.0, 0.0, (CGFloat)width, (CGFloat)height), brushImage);
	CGContextRelease(brushContext);
	glGenTextures(1, &brushTexture);
	glBindTexture(GL_TEXTURE_2D, brushTexture);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, brushData);
	free(brushData);		
	
	
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glEnable(GL_TEXTURE_2D);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE);
	glEnable(GL_BLEND);
	
	
	
}


-(CGPoint) calculateP:(int) x snd:(int) y {
	
	CGPoint p;
	p.x = 32+64*x;
	p.y = 480-32-64*y;
	if(y==7) { p.y = 0; };
	
	return p;
	
	
}

-(CGPoint) calculateQ:(int) x snd:(int) y {
	
	CGPoint p;
	p.x = 32+64*x+2;
	p.y = 480-32-64*y;
	if(y==7) { p.y = 0; };
	
	return p;
	
	
}








- (float) distance:(CGPoint) p b:(CGPoint) q {
	return sqrt(((p.x-q.x)*(p.x-q.x))+((p.y-q.y)*(p.y-q.y)));
	
}





- (void) gameLoop {
	
	CGRect					rect = [[UIScreen mainScreen] applicationFrame];
	CGRect fmat;
	GLfloat d;
	CGPoint p,q,qq;
	UIImage *img2;
	
	UIImage *img;

	NSString *tilesString;
		NSString *levelName;
	CGRect labelFrame = CGRectMake(0,0,100,20);
	UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];

	
	
	
	switch(gameState) {
			
		case LOAD_MENU2 :
			break;
			
		case LOAD_MENU:
			[menuView release];
			[[CMOpenALSoundManager sharedCMOpenALSoundManager] stopBackgroundMusic];
			qq.x = qq.y = -100;
			shiroView. center = qq;
			img = [[UIImage imageNamed:@"menu.png"] retain];
			menuView = [[UIImageView alloc] initWithImage:img];
			[window addSubview:menuView];
			gameState = MENU_WAIT;
			break;
		case MENU_WAIT:
			if(released) {
				int mx = (int)mouse.x;
				mouse.x = 480-mouse.y;
				mouse.y = 319-mx;
				NSLog(@"%f - %f", mouse.x, mouse.y);
				if(mouse.x>230 && mouse.y>35 && mouse.x<385 && mouse.y<80) {
					gameLevel = -2;
					gameState2 = LOAD_CHAPTER1;
					gameState = MENU_UNLOAD;
				} else if(mouse.x>300 && mouse.y>120 && mouse.x<450 && mouse.y<150) {
					gameState2 = LOAD_CREDITS;
					gameState = MENU_UNLOAD;
				} else if(mouse.x>280 && mouse.y>190 && mouse.x<440 && mouse.y<230) {
					gameState2 = LOAD_CREDITS;
					gameState = MENU_UNLOAD;
				} else if(mouse.x>200 && mouse.y>260 && mouse.x<330 && mouse.y<300) {
					gameState2 = LOAD_CREDITS;
					gameState = MENU_UNLOAD;
				}	
			}
			break;
			
		case MENU_UNLOAD:
			
			[menuView removeFromSuperview];
			gameState = gameState2;
			break;
		case LOAD_SPLASH:
			[menuView release];
			qq.x = qq.y = -100;
			shiroView. center = qq;
			img = [[UIImage imageNamed:@"laorg.png"] retain];
			menuView = [[UIImageView alloc] initWithImage:img];
			[window addSubview:menuView];
			gameTimer = 0;
			gameState = SPLASH_WAIT;
			break;
		case SPLASH_WAIT:
			gameTimer++;
			if(gameTimer>1){//150) {
				gameState = SPLASH_UNLOAD;
			}
			break;
			
		case SPLASH_UNLOAD:
			
			[menuView removeFromSuperview];
			gameState = LOAD_TITLE;
			break;
			
		case LOAD_TITLE:
			[menuView release];
			qq.x = qq.y = -100;
			shiroView. center = qq;
			img = [[UIImage imageNamed:@"titulo.png"] retain];
			menuView = [[UIImageView alloc] initWithImage:img];
			[window addSubview:menuView];
			gameTimer = 0;
			gameState = TITLE_WAIT;
			break;
		case TITLE_WAIT:
			if(released) {// && mouse.x>220 && mouse.y>120 && mouse.x<250 && mouse.y<210) {
				gameState = TITLE_UNLOAD;
			}
			break;
			
		case TITLE_UNLOAD:
			
			[menuView removeFromSuperview];
			gameState = LOAD_MENU;
			break;
			
			
			
		case LOAD_CREDITS:
			[menuView release];

			img = [[UIImage imageNamed:@"background_credits.png"] retain];
			menuView = [[UIImageView alloc] initWithImage:img];
			[window addSubview:menuView];

			
			img2 = [[UIImage imageNamed:@"cred1.png"] retain];
			datosa = [[UIImageView alloc] initWithImage:img2];
			[window addSubview:datosa];
			datosa.contentMode = UIViewContentModeScaleToFill;
			fmat = datosa.frame;
			fmat.size.width = 32;
			fmat.size.height = (int)(384*0.5);
			datosa.frame = fmat;
			qq.x = 320-64;
			qq.y = 240;
			datosa.center = qq;
			
			img2 = [[UIImage imageNamed:@"cred2.png"] retain];
			datosb = [[UIImageView alloc] initWithImage:img2];
			[window addSubview:datosb];
			datosb.contentMode = UIViewContentModeScaleToFill;
			fmat = datosb.frame;
			fmat.size.width = 32;
			fmat.size.height = (int)(384*0.5);
			datosb.frame = fmat;
			qq.x = 320-128;
			qq.y = 240;
			datosb.center = qq;
			
			img2 = [[UIImage imageNamed:@"cred3.png"] retain];
			datosc = [[UIImageView alloc] initWithImage:img2];
			[window addSubview:datosc];
			datosc.contentMode = UIViewContentModeScaleToFill;
			fmat = datosc.frame;
			fmat.size.width = 32;
			fmat.size.height = (int)(384*0.5);
			datosc.frame = fmat;
			qq.x = 320-192;
			qq.y = 240;
			datosc.center = qq;
			
			img2 = [[UIImage imageNamed:@"cred4.png"] retain];
			datosd = [[UIImageView alloc] initWithImage:img2];
			[window addSubview:datosd];
			datosd.contentMode = UIViewContentModeScaleToFill;
			fmat = datosd.frame;
			fmat.size.width = 32;
			fmat.size.height = (int)(384*0.5);
			datosd.frame = fmat;
			qq.x = 320-256;
			qq.y = 240;
			datosd.center = qq;
			
			gameState = CREDITS_WAIT;
			break;
		case CREDITS_WAIT:
			
			
		
			if(released && mouse.x>240 && mouse.y>80 && mouse.x<272 && mouse.y<400) {
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.theninjabunny.com/"]];	
			} else if(released && mouse.x>176 && mouse.y>80 && mouse.x<208 && mouse.y<400) {
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.linkita.net"]];
			} else if(released && mouse.x>112 && mouse.y>80 && mouse.x<142 && mouse.y<400) {
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.jonathanrodas.com"]];
			} else if(released && mouse.x>48 && mouse.y>80 && mouse.x<80 && mouse.y<400) {
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.purevolume.com/sentimientoconscripto"]];
			} if(released && mouse.x<40 && mouse.y<60) {
				gameState = LOAD_CREDITS2;
			};
			
			d =  1-((((datosa.center.x-mouse.x)*(datosa.center.x-mouse.x))/(300*300)));
			if(d<0.5) { d = 0.5; };
			if(d>1) { d = 1; };
			fmat = datosa.frame;
			fmat.size.width = (int)(64*d);
			fmat.size.height = (int)(384*d);
			datosa.frame = fmat;
			qq.x = 320-64;
			qq.y = 240;
			datosa.center = qq;
			
			d =  1-((((datosb.center.x-mouse.x)*(datosb.center.x-mouse.x))/(300*300)));
			if(d<0.5) { d = 0.5; };
			if(d>1) { d = 1; };
			fmat = datosa.frame;
			fmat.size.width = (int)(64*d);
			fmat.size.height = (int)(384*d);
			datosb.frame = fmat;
			qq.x = 320-128;
			qq.y = 240;
			datosb.center = qq;
			
			d =  1-((((datosc.center.x-mouse.x)*(datosc.center.x-mouse.x))/(300*300)));
			if(d<0.5) { d = 0.5; };
			if(d>1) { d = 1; };
			fmat = datosc.frame;
			fmat.size.width = (int)(64*d);
			fmat.size.height = (int)(384*d);
			datosc.frame = fmat;
			qq.x = 320-192;
			qq.y = 240;
			datosc.center = qq;
			
			d =  1-((((datosd.center.x-mouse.x)*(datosd.center.x-mouse.x))/(300*300)));
			if(d<0.5) { d = 0.5; };
			if(d>1) { d = 1; };
			fmat = datosd.frame;
			fmat.size.width = (int)(64*d);
			fmat.size.height = (int)(384*d);
			datosd.frame = fmat;
			qq.x = 320-256;
			qq.y = 240;
			datosd.center = qq;
			
			

			
			
			
			break;
			
		case LOAD_CREDITS2:
			
			//[menuView removeFromSuperview];
			[datosa removeFromSuperview];
			[datosa release];
			[datosb removeFromSuperview];
			[datosb release];
			[datosc removeFromSuperview];
			[datosc release];
			[datosd removeFromSuperview];
			[datosd release];
			
			[menuView release];
			
			img = [[UIImage imageNamed:@"credits2.png"] retain];
			menuView = [[UIImageView alloc] initWithImage:img];
			[window addSubview:menuView];

			
			gameState = CREDITS_WAIT2;
			break;
			
		case CREDITS_WAIT2: 
			if(released && mouse.x<40 && mouse.y<60) {
				[menuView release];
				gameState = LOAD_MENU;
			};
			break;
			

			
			
		case LOAD_GAME:
			
			[drawingView removeFromSuperview];
			[drawingView release];
			drawingView = [[PaintingView alloc] initWithFrame:CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)];
			[window addSubview:drawingView];
			
			
			img = [[UIImage imageNamed:@"loading.png"] retain];
			menuView = [[UIImageView alloc] initWithImage:img];
			[window addSubview:menuView];
			kuroA = shiroA = 0;
			tilesLoadedi = tilesLoadedj = 0;
			gameState = LOADTILE0;
				
			
			break;
			
			

			
		case LOADTILE1:
			gameColor = BLANCO;
			
			[menuView removeFromSuperview];
			[menuView release];
			
			
			[kuroView removeFromSuperview];
			[kuroView release];
			[shiroView removeFromSuperview];
			[shiroView release];

			
			img = [[UIImage imageNamed:@"personaje1_blanco.png"] retain];
			shiroView = [[UIImageView alloc] initWithImage:img];
			
			shiroView.animationImages = [NSArray arrayWithObjects: [UIImage imageNamed:@"personaje1_blanco.png"],
										 [UIImage imageNamed:@"personaje2_blanco.png"],
										 [UIImage imageNamed:@"personaje3_blanco.png"],
										 [UIImage imageNamed:@"personaje4_blanco.png"],
										 [UIImage imageNamed:@"personaje5_blanco.png"],
										 [UIImage imageNamed:@"personaje4_blanco.png"],
										 [UIImage imageNamed:@"personaje3_blanco.png"],
										 [UIImage imageNamed:@"personaje2_blanco.png"], nil];
			
			shiroView.animationDuration = 1.0;			
			
			
			
			shiroDefLeft = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"puntitos_blanco1.png"] retain]];
			shiroDefLeft.animationImages = [NSArray arrayWithObjects: [UIImage imageNamed:@"puntitos_blanco1.png"],
											[UIImage imageNamed:@"puntitos_blanco2.png"],
											[UIImage imageNamed:@"puntitos_blanco3.png"],
											[UIImage imageNamed:@"puntitos_blanco4.png"], nil];
			shiroDefLeft.animationDuration = 0.8;
			
			
			shiroDefRight = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"puntitos_blanco1r.png"] retain]];
			shiroDefRight.animationImages = [NSArray arrayWithObjects: [UIImage imageNamed:@"puntitos_blanco1r.png"],
											 [UIImage imageNamed:@"puntitos_blanco2r.png"],
											 [UIImage imageNamed:@"puntitos_blanco3r.png"],
											 [UIImage imageNamed:@"puntitos_blanco4r.png"], nil];
			shiroDefRight.animationDuration = 0.8;
			
			
			kuroLove = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"corazones_blanco_1.png"] retain]];
			kuroLove.animationImages = [NSArray arrayWithObjects: [UIImage imageNamed:@"corazones_blanco_1.png"],
										 [UIImage imageNamed:@"corazones_blanco_2.png"], nil];
			kuroLove.animationDuration = 0.8;
			
			
			shiroLove = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"corazones_negro_1.png"] retain]];
			shiroLove.animationImages = [NSArray arrayWithObjects: [UIImage imageNamed:@"corazones_negro_1.png"],
										 [UIImage imageNamed:@"corazones_negro_2.png"], nil];
			shiroLove.animationDuration = 0.8;
			
			
			
			
			
			
			img = [[UIImage imageNamed:@"personaje1_negro.png"] retain];
			kuroView = [[UIImageView alloc] initWithImage:img];
			
			kuroView.animationImages = [NSArray arrayWithObjects: [UIImage imageNamed:@"personaje1_negro.png"],
										 [UIImage imageNamed:@"personaje2_negro.png"],
										 [UIImage imageNamed:@"personaje3_negro.png"],
										 [UIImage imageNamed:@"personaje4_negro.png"],
										 [UIImage imageNamed:@"personaje5_negro.png"],
										 [UIImage imageNamed:@"personaje4_negro.png"],
										 [UIImage imageNamed:@"personaje3_negro.png"],
										 [UIImage imageNamed:@"personaje2_negro.png"], nil];
			
			kuroView.animationDuration = 1.0;			
			
			
			
			kuroDefLeft = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"puntitos_negro1.png"] retain]];
			kuroDefLeft.animationImages = [NSArray arrayWithObjects: [UIImage imageNamed:@"puntitos_negro1.png"],
											[UIImage imageNamed:@"puntitos_negro2.png"],
											[UIImage imageNamed:@"puntitos_negro3.png"],
											[UIImage imageNamed:@"puntitos_negro4.png"], nil];
			kuroDefLeft.animationDuration = 0.8;
			
			
			kuroDefRight = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"puntitos_negro1r.png"] retain]];
			kuroDefRight.animationImages = [NSArray arrayWithObjects: [UIImage imageNamed:@"puntitos_negro1r.png"],
											 [UIImage imageNamed:@"puntitos_negro2r.png"],
											 [UIImage imageNamed:@"puntitos_negro3r.png"],
											 [UIImage imageNamed:@"puntitos_negro4r.png"], nil];
			kuroDefRight.animationDuration = 0.8;
			
			
			
			
			shiroko = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"princesa1_blanco.png"] retain]];
			shiroko.animationImages = [NSArray arrayWithObjects: [UIImage imageNamed:@"princesa1_blanco.png"],
									   [UIImage imageNamed:@"princesa2_blanco.png"],
									   [UIImage imageNamed:@"princesa3_blanco.png"],
									   [UIImage imageNamed:@"princesa4_blanco.png"],
									   [UIImage imageNamed:@"princesa3_blanco.png"],
									   [UIImage imageNamed:@"princesa2_blanco.png"], nil];
			shiroko.animationDuration = 0.8;
			
			kuroko = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"princesa1_negro.png"] retain]];
			kuroko.animationImages = [NSArray arrayWithObjects: [UIImage imageNamed:@"princesa1_negro.png"],
									  [UIImage imageNamed:@"princesa2_negro.png"],
									  [UIImage imageNamed:@"princesa3_negro.png"],
									  [UIImage imageNamed:@"princesa4_negro.png"],
 									  [UIImage imageNamed:@"princesa3_negro.png"],
									  [UIImage imageNamed:@"princesa2_negro.png"], nil];
			kuroko.animationDuration = 0.8;
			
			shirokoLove = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"corazones_she_negro.png"] retain]];
			kurokoLove = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"corazones_she_blanco.png"] retain]];

			
			
			// *******************************************************
			// *******************************************************
			// ACTIVATE IN THE RELEASE
			// *******************************************************
			// *******************************************************
/*			
			[[CMOpenALSoundManager sharedCMOpenALSoundManager] stopBackgroundMusic];
			
			switch(gameLevel) {
				case 1:
				case 5:
				case 9:
				case 13:
				case 17:
				case 21:
				default:
					[[CMOpenALSoundManager sharedCMOpenALSoundManager] playBackgroundMusic:@"music1.caf" forcePlay:YES];
					gameMusic = 1;
					break;
					
				case 2:
				case 6:
				case 10:
				case 14:
				case 18:
				case 22:
					[[CMOpenALSoundManager sharedCMOpenALSoundManager] playBackgroundMusic:@"music2.caf" forcePlay:YES];
					gameMusic = 2;
					break;
					
				case 3:
				case 7:
				case 11:
				case 15:
				case 19:
				case 23:
					[[CMOpenALSoundManager sharedCMOpenALSoundManager] playBackgroundMusic:@"music3.caf" forcePlay:YES];
					gameMusic = 3;
					break;
					
				case 4:
				case 8:
				case 12:
				case 16:
				case 20:
				case 24:
					[[CMOpenALSoundManager sharedCMOpenALSoundManager] playBackgroundMusic:@"music4.caf" forcePlay:YES];
					gameMusic = 4;
					break;
					
			};
*/			
			
			gameState = LOAD_GAME_FINAL;
			
			break;
			
		case LOADTILE0:
			
			if(gameLevel<0) {
				levelName = @"tutorial";
			} else {
				levelName = [NSString stringWithFormat:@"%@%d", @"level", gameLevel];
			}
			tilesString = [NSString stringWithFormat:@"%@%d%d%@", levelName,tilesLoadedi,tilesLoadedj,@".png"];
			brushImage = [UIImage imageNamed:tilesString].CGImage;
			[self doStuff];
			p = [self calculateP:tilesLoadedi snd:tilesLoadedj];
			q = [self calculateQ:tilesLoadedi snd:tilesLoadedj];
			[drawingView renderLineFromPoint:p toPoint:q];
			
			
			tilesLoadedj++;
			if(tilesLoadedj>7) {
				tilesLoadedi++;
				tilesLoadedj = 0;
			}			
			if(tilesLoadedi>=5) {
				gameState = LOADTILE1;
			}
			break;
			
		case LOAD_GAME_FINAL:
			
			shiroEnd = kuroEnd = FALSE;
			gameColor = BLANCO;
			brushImage = [UIImage imageNamed:@"brush.png"].CGImage;
			[self doStuff];
			glBlendFunc(GL_SRC_ALPHA, GL_ONE);			
			
			[window addSubview:kuroView];
			[window addSubview:kuroDefRight];
			[window addSubview:kuroDefLeft];
			[window addSubview:shiroDefRight];
			[window addSubview:shiroDefLeft];
			[window addSubview:shiroView];
			[shiroView startAnimating];
			[shiroDefRight startAnimating];
			[shiroDefLeft startAnimating];
			[kuroView startAnimating];
			[kuroDefRight startAnimating];
			[kuroDefLeft startAnimating];
			[window addSubview:shiroko];
			[window addSubview:kuroko];
			[window addSubview:shirokoLove];
			[window addSubview:kurokoLove];
			[shiroko startAnimating];
			[kuroko startAnimating];
			[window addSubview:shiroLove];
			[window addSubview:kuroLove];
			[shiroLove startAnimating];
			[kuroLove startAnimating];
			
			handkuro = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"mano_negra.png"] retain]];
			handshiro = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"mano_blanca.png"] retain]];
			
			[window addSubview:handkuro];
			[window addSubview:handshiro];
			
			qq.x = 15;
			qq.y = 480-12;
			handshiro.center = qq;
			

			
			label.frame = labelFrame;
			label.text = @"Score: ";
			[window addSubview:label];
			
			qq.x = qq.y = -100;
			shiroLove.center = kuroLove.center = shirokoLove.center = kurokoLove.center = handkuro.center = kuroView.center = shiroView.center = shiroDefLeft.center = shiroDefRight.center =  kuroDefLeft.center = kuroDefRight.center = qq;
			/*shirokop.x = qq.x = 100;
			shirokop.y = qq.y = 300;
			shiroko.center = qq;
			
			qq.x = 300;
			kuroko.center = qq;*/
			
			switch(gameLevel) {
			
				case -2:
					
					shirop.x = 360;
					shirop.y = 120;
					kurop.x = 120;
					kurop.y = 120;
					break;
					
				case 1:
					shirop.x = 24;
					shirop.y = 295;
					kurop.x = 64;
					kurop.y = 175;
					shirokop.x = 440;
					shirokop.y = 290;
					kurokop.x = 400;
					kurokop.y = 160;
					break;
					
				case 2:
					shirop.x = 61;
					shirop.y = 290;
					kurop.x = 90;
					kurop.y = 105;
					shirokop.x = 390;
					shirokop.y = 25;
					kurokop.x = 425;
					kurokop.y = 37;
					break;
					
				case 3:
					shirop.x = 30;
					shirop.y = 250;
					kurop.x = 30;
					kurop.y = 50;
					shirokop.x = 340;
					shirokop.y = 150;
					kurokop.x = 407;
					kurokop.y = 210;
					break;
					
				case 4:
					shirop.x = 100;
					shirop.y = 190;
					kurop.x = 70;
					kurop.y = 140;
					shirokop.x = 365;
					shirokop.y = 230;
					kurokop.x = 380;
					kurokop.y = 270;
					break;
					
				case 5:
					shirop.x = 32;
					shirop.y = 200;
					kurop.x = 23;
					kurop.y = 160;
					shirokop.x = 400;
					shirokop.y = 135;
					kurokop.x = 460;
					kurokop.y = 100;
					break;
					
				case 6:
					shirop.x = 90;
					shirop.y = 250;
					kurop.x = 35;
					kurop.y = 275;
					shirokop.x = 415;
					shirokop.y = 240;
					kurokop.x = 300;
					kurokop.y = 60;
					break;
					
				case 7:
					shirop.x = 70;
					shirop.y = 160;
					kurop.x = 60;
					kurop.y = 105;
					shirokop.x = 430;
					shirokop.y = 200;
					kurokop.x = 340;
					kurokop.y = 280;
					break;
					
				case 8:
					shirop.x = 50;
					shirop.y = 250;
					kurop.x = 60;
					kurop.y = 160;
					shirokop.x = 390;
					shirokop.y = 210;
					kurokop.x = 460;
					kurokop.y = 170;
					break;
					
				case 9:
					shirop.x = 470;
					shirop.y = 135;
					kurop.x = 420;
					kurop.y = 195;
					shirokop.x = 45;
					shirokop.y = 300;
					kurokop.x = 45;
					kurokop.y = 275;
					break;
					
				case 10:
					shirop.x = 60;
					shirop.y = 280;
					kurop.x = 65;
					kurop.y = 150;
					shirokop.x = 350;
					shirokop.y = 130;
					kurokop.x = 460;
					kurokop.y = 270;
					break;
					
				case 11:
					shirop.x = 40;
					shirop.y = 260;
					kurop.x = 185;
					kurop.y = 35;
					shirokop.x = 450;
					shirokop.y = 300;
					kurokop.x = 415;
					kurokop.y = 185;
					break;
					
				case 12:
					shirop.x = 35;
					shirop.y = 20;
					kurop.x = 30;
					kurop.y = 170;
					shirokop.x = 375;
					shirokop.y = 275;
					kurokop.x = 340;
					kurokop.y = 235;
					break;
					
				case 13:
					shirop.x = 55;
					shirop.y = 140;
					kurop.x = 30;
					kurop.y = 90;
					shirokop.x = 350;
					shirokop.y = 50;
					kurokop.x = 250;
					kurokop.y = 20;
					break;
					
				case 14:
					shirop.x = 45;
					shirop.y = 180;
					kurop.x = 45;
					kurop.y = 120;
					shirokop.x = 460;
					shirokop.y = 10;
					kurokop.x = 420;
					kurokop.y = 90;
					break;
					
				case 15:
					shirop.x = 50;
					shirop.y = 265;
					kurop.x = 20;
					kurop.y = 240;
					shirokop.x = 435;
					shirokop.y = 30;
					kurokop.x = 435;
					kurokop.y = 240;
					break;
					
				case 16:
					shirop.x = 70;
					shirop.y = 275;
					kurop.x = 25;
					kurop.y = 230;
					shirokop.x = 390;
					shirokop.y = 65;
					kurokop.x = 450;
					kurokop.y = 290;
					break;
					
				case 17:
					shirop.x = 45;
					shirop.y = 290;
					kurop.x = 40;
					kurop.y = 90;
					shirokop.x = 430;
					shirokop.y = 70;
					kurokop.x = 430;
					kurokop.y = 205;
					break;
					
				case 18:
					shirop.x = 30;
					shirop.y = 45;
					kurop.x = 30;
					kurop.y = 90;
					shirokop.x = 435;
					shirokop.y = 210;
					kurokop.x = 450;
					kurokop.y = 250;
					break;
					
				case 19:
					shirop.x = 30;
					shirop.y = 200;
					kurop.x = 85;
					kurop.y = 115;
					shirokop.x = 410;
					shirokop.y = 145;
					kurokop.x = 360;
					kurokop.y = 125;
					break;
					
				case 20:
					shirop.x = 30;
					shirop.y = 150;
					kurop.x = 50;
					kurop.y = 75;
					shirokop.x = 380;
					shirokop.y = 95;
					kurokop.x = 440;
					kurokop.y = 300;
					break;
					
				default :
					shirop.x = 320;
					shirop.y = 120;
					break;
					
					
			}
			
			qq.y = shirokop.x;
			qq.x = 319-shirokop.y;
			shiroko.center = qq;
			qq.y = kurokop.x;
			qq.x = 319-kurokop.y;
			kuroko.center = qq;
			
			
			mouseMoved = 0;
			
			score = 0;
			
			
			gameState = GAME_WAIT;
			
			break;
			
		case GAME_WAIT:
			
			score++;
			label.text = [NSString stringWithFormat:@"%@%d", @"Beris: ", score];
			
			if(released && mouse.x<30 && mouse.y<30) {
				if(gameColor==NEGRO) {
					gameColor = BLANCO;
					brushImage = [UIImage imageNamed:@"brush.png"].CGImage;
					[self doStuff];
					glBlendFunc(GL_SRC_ALPHA, GL_ONE);
					qq.x = 15;
					qq.y = 480-12;
					handshiro.center = qq;
					qq.x = -100;
					qq.y = -100;
					handkuro.center = qq;
					
				} else {
					gameColor = NEGRO;
					brushImage = [UIImage imageNamed:@"brush2.png"].CGImage;
					[self doStuff];
					glBlendFunc(GL_DST_COLOR, GL_ONE_MINUS_SRC_ALPHA);
					qq.x = 15;
					qq.y = 480-12;
					handkuro.center = qq;
					qq.x = -100;
					qq.y = -100;
					handshiro.center = qq;
					
				}
			} else if(released && mouse.x>290 && mouse.y<30) {
				gameState = LOAD_PAUSE;
			}
			
			
			
			
			
			if(!shiroEnd) {
				qq.x = qq.y = -100;
				shiroLove.center = shirokoLove.center = shiroView.center = shiroDefLeft.center = shiroDefRight.center = qq;
				
				[self chuo_update:SHIRO];
				qq.y = shirop.x+(22/2);
				qq.x = 319-shirop.y-(20/2);
				switch(shiroA) {
					default :
					case 0:
						shiroView.center = qq;
						break;
						
					case 1:
						shiroDefLeft.center = qq;
						break;
						
					case 2:
						shiroDefRight.center = qq;
						break;
						
					case 3:
						shiroLove.center = qq;
						break;
						
				}
				
				if([self distance:shirop b:shirokop]<20) {
					qq.x = qq.y = -100;
					shiroLove.center = shirokoLove.center = shiroView.center = shiroDefLeft.center = shiroDefRight.center = qq;
					shiroA = 3;
					shiroEnd = TRUE;
					qq.y = shirop.x+(22/2);
					qq.x = 319-shirop.y-(20/2);
					shiroLove.center = qq;
					shirokoLove.center = shiroko.center;
					qq.x = qq.y = -100;
					shiroko.center = qq;
				}
				
			}
			if(!kuroEnd) {
				qq.x = qq.y = -100;
				kuroLove.center = kurokoLove.center = kuroView.center = kuroDefLeft.center = kuroDefRight.center = qq;

				[self chuo_update:KURO];
				qq.y = kurop.x+(22/2);
				qq.x = 319-kurop.y-(20/2);
				switch(kuroA) {
					default :
					case 0:
						kuroView.center = qq;
						break;
						
					case 1:
						kuroDefLeft.center = qq;
						break;
						
					case 2:
						kuroDefRight.center = qq;
						break;
						
					case 3:
						kuroLove.center = qq;
						break;
						
						
				}
				
				if([self distance:kurop b:kurokop]<20) {
					qq.x = qq.y = -100;
					kuroLove.center = kurokoLove.center = kuroView.center = kuroDefLeft.center = kuroDefRight.center = qq;
					kuroA = 3;
					kuroEnd = TRUE;
					qq.y = kurop.x+(22/2);
					qq.x = 319-kurop.y-(20/2);
					kuroLove.center = qq;
					kurokoLove.center = kuroko.center;
					qq.x = qq.y = -100;
					kuroko.center = qq;
				}
			}

			
			
			if(shiroEnd && kuroEnd) {
				gameState = GAME_END;
			};
			
			
			
			/*
			if(![[CMOpenALSoundManager sharedCMOpenALSoundManager] isBackGroundMusicPlaying]) {
				switch(gameMusic) {
					case 1:
					default:
						break;
						
					case 2:
						break:
						
					case 3:
						break;
						
					case 4:
						break;
				//[[CMOpenALSoundManager sharedCMOpenALSoundManager] stopBackgroundMusic];
				//[[CMOpenALSoundManager sharedCMOpenALSoundManager] purgeSounds];
			};*/
			
			
			
			break;
			
			
		case LOAD_PAUSE:
			[menuView release];
			qq.x = qq.y = -100;
			shiroView. center = qq;
			img = [[UIImage imageNamed:@"pause.png"] retain];
			menuView = [[UIImageView alloc] initWithImage:img];
			[window addSubview:menuView];
			gameTimer = 0;
			gameState = GAME_PAUSE;
			break;
			//>
			//><
		case GAME_PAUSE:
			if(released){//150) {
				gameState = UNLOAD_PAUSE;
			}
			break;
			
		case UNLOAD_PAUSE:
			
			[menuView removeFromSuperview];
			gameState = GAME_WAIT;
			break;
			
			
			
			
		case GAME_END:
			if(gameLevel<20) {
				gameLevel++;
				gameState = LOAD_GAME;
			} else {
				LOAD_MENU;
			};
			break;
			
		case TUTORIAL_LOAD:
			[menuView release];
			qq.x = qq.y = -100;
			shiroView. center = qq;
			img = [[UIImage imageNamed:@"laorg.png"] retain];
			menuView = [[UIImageView alloc] initWithImage:img];
			[window addSubview:menuView];
			gameTimer = 0;
			gameState = TUTORIAL_WAIT;
			
			break;
			
		case TUTORIAL_WAIT:
			break;
			
		case TUTORIAL_UNLOAD:
			break;
			
		case LOAD_CHAPTER1:
			[menuView release];
			img = [[UIImage imageNamed:@"niveles.png"] retain];
			menuView = [[UIImageView alloc] initWithImage:img];
			[window addSubview:menuView];

			img = [[UIImage imageNamed:@"chap1.png"] retain];
			chapa = [[UIImageView alloc] initWithImage:img];
			[window addSubview:chapa];
			img = [[UIImage imageNamed:@"chap1.png"] retain];
			chapb = [[UIImageView alloc] initWithImage:img];
			[window addSubview:chapb];
			img = [[UIImage imageNamed:@"chap1.png"] retain];
			chapc = [[UIImageView alloc] initWithImage:img];
			[window addSubview:chapc];
			img = [[UIImage imageNamed:@"chap1.png"] retain];
			chapd = [[UIImageView alloc] initWithImage:img];
			[window addSubview:chapd];
			img = [[UIImage imageNamed:@"chap1.png"] retain];
			chape = [[UIImageView alloc] initWithImage:img];
			[window addSubview:chape];
			img = [[UIImage imageNamed:@"chap1.png"] retain];
			chapf = [[UIImageView alloc] initWithImage:img];
			[window addSubview:chapf];
			img = [[UIImage imageNamed:@"chap1.png"] retain];
			chapg = [[UIImageView alloc] initWithImage:img];
			[window addSubview:chapg];
			img = [[UIImage imageNamed:@"chap1.png"] retain];
			chaph = [[UIImageView alloc] initWithImage:img];
			[window addSubview:chaph];
			img = [[UIImage imageNamed:@"chap1.png"] retain];
			chapi = [[UIImageView alloc] initWithImage:img];
			[window addSubview:chapi];
			img = [[UIImage imageNamed:@"chap1.png"] retain];
			chapj = [[UIImageView alloc] initWithImage:img];
			[window addSubview:chapj];
			
			qq.x = 221;
			qq.y = 52;
			chapa.center = qq;
			qq.x = 221;
			qq.y = 145;
			chapb.center = qq;
			qq.x = 221;
			qq.y = 238;
			chapc.center = qq;
			qq.x = 221;
			qq.y = 331;
			chapd.center = qq;
			qq.x = 221;
			qq.y = 424;
			chape.center = qq;
			qq.x = 84;
			qq.y = 52;
			chapf.center = qq;
			qq.x = 84;
			qq.y = 145;
			chapg.center = qq;
			qq.x = 84;
			qq.y = 238;
			chaph.center = qq;
			qq.x = 84;
			qq.y = 331;
			chapi.center = qq;
			qq.x = 84;
			qq.y = 424;
			chapj.center = qq;
			
			gameState = SELECT_CHAPTER1;
			break;
			
		case SELECT_CHAPTER1:
			
			if(released) {
				int cpx = -100;
				int cpy = -100;
				if(mouse.x>52 && mouse.x<116) {
					cpx = 5;
				} else if(mouse.x>189 && mouse.x<253) {
					cpx = 0;
				};
				if(mouse.y>20 && mouse.y<94) {
					cpy = 4;
				} else if(mouse.y>113 && mouse.y<187) {
					cpy = 3;
				} else if(mouse.y>206 && mouse.y<280) {
					cpy = 2;
				} else if(mouse.y>299 && mouse.y<373) {
					cpy = 1;
				} else if(mouse.y>392 && mouse.y<466) {
					cpy = 0;
				};
				
				if((cpx+cpy)>=0) {
					gameLevel = cpx+cpy+1;
					[chapa release];
					[chapb release];
					[chapc release];
					[chapd release];
					[chape release];
					[chapf release];
					[chapg release];
					[chaph release];
					[chapi release];
					[chapj release];
					[menuView release];
					gameState = LOAD_GAME;
				};
			};
			
			
			if(released && mouse.x<40 && mouse.y<60) {
				[chapa release];
				[chapb release];
				[chapc release];
				[chapd release];
				[chape release];
				[chapf release];
				[chapg release];
				[chaph release];
				[chapi release];
				[chapj release];
				
				
				img = [[UIImage imageNamed:@"chap1.png"] retain];
				chapa = [[UIImageView alloc] initWithImage:img];
				[window addSubview:chapa];
				img = [[UIImage imageNamed:@"chap1.png"] retain];
				chapb = [[UIImageView alloc] initWithImage:img];
				[window addSubview:chapb];
				img = [[UIImage imageNamed:@"chap1.png"] retain];
				chapc = [[UIImageView alloc] initWithImage:img];
				[window addSubview:chapc];
				img = [[UIImage imageNamed:@"chap1.png"] retain];
				chapd = [[UIImageView alloc] initWithImage:img];
				[window addSubview:chapd];
				img = [[UIImage imageNamed:@"chap1.png"] retain];
				chape = [[UIImageView alloc] initWithImage:img];
				[window addSubview:chape];
				img = [[UIImage imageNamed:@"chap1.png"] retain];
				chapf = [[UIImageView alloc] initWithImage:img];
				[window addSubview:chapf];
				img = [[UIImage imageNamed:@"chap1.png"] retain];
				chapg = [[UIImageView alloc] initWithImage:img];
				[window addSubview:chapg];
				img = [[UIImage imageNamed:@"chap1.png"] retain];
				chaph = [[UIImageView alloc] initWithImage:img];
				[window addSubview:chaph];
				img = [[UIImage imageNamed:@"chap1.png"] retain];
				chapi = [[UIImageView alloc] initWithImage:img];
				[window addSubview:chapi];
				img = [[UIImage imageNamed:@"chap1.png"] retain];
				chapj = [[UIImageView alloc] initWithImage:img];
				[window addSubview:chapj];
				
				qq.x = 221;
				qq.y = 52;
				chapa.center = qq;
				qq.x = 221;
				qq.y = 145;
				chapb.center = qq;
				qq.x = 221;
				qq.y = 238;
				chapc.center = qq;
				qq.x = 221;
				qq.y = 331;
				chapd.center = qq;
				qq.x = 221;
				qq.y = 424;
				chape.center = qq;
				qq.x = 84;
				qq.y = 52;
				chapf.center = qq;
				qq.x = 84;
				qq.y = 145;
				chapg.center = qq;
				qq.x = 84;
				qq.y = 238;
				chaph.center = qq;
				qq.x = 84;
				qq.y = 331;
				chapi.center = qq;
				qq.x = 84;
				qq.y = 424;
				chapj.center = qq;
				
				gameState = SELECT_CHAPTER2;
			};

			break;
			
		case SELECT_CHAPTER2:
			
			if(released) {
				int cpx = -100;
				int cpy = -100;
				if(mouse.x>52 && mouse.x<116) {
					cpx = 5;
				} else if(mouse.x>189 && mouse.x<253) {
					cpx = 0;
				};
				if(mouse.y>20 && mouse.y<94) {
					cpy = 4;
				} else if(mouse.y>113 && mouse.y<187) {
					cpy = 3;
				} else if(mouse.y>206 && mouse.y<280) {
					cpy = 2;
				} else if(mouse.y>299 && mouse.y<373) {
					cpy = 1;
				} else if(mouse.y>392 && mouse.y<466) {
					cpy = 0;
				};
				
				if((cpx+cpy)>=0) {
					gameLevel = cpx+cpy+11;
					[chapa release];
					[chapb release];
					[chapc release];
					[chapd release];
					[chape release];
					[chapf release];
					[chapg release];
					[chaph release];
					[chapi release];
					[chapj release];
					[menuView release];
					gameState = LOAD_GAME;
				};
			};
			
			
			if(released && mouse.x<40 && mouse.y<60) {
				gameState = LOAD_MENU;
			};

			break;
			
			
			
			
	}
	
	
	released = FALSE;
	
	
}









// Release resources when they are no longer needed,
- (void) dealloc
{
	[selectSound release];
	[erasingSound release];
	[drawingView release];
	[shiroView release];
	[kuroView release];
	[menuView release];
	[shiroDefLeft release];
	[shiroDefRight release];
	[kuroDefLeft release];
	[kuroDefRight release];
	[shiroko release];
	[kuroko release];
	[shirokoLove release];
	[kurokoLove release];
	[shiroLove release];
	[kuroLove release];
	[datosa release];
	[datosb release];
	[datosc release];
	[datosd release];
	[window release];	
	[[CMOpenALSoundManager sharedCMOpenALSoundManager] stopBackgroundMusic];
	[[CMOpenALSoundManager sharedCMOpenALSoundManager] purgeSounds];
	[super dealloc];
}











@end



