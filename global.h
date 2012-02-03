/*
 *  global.h
 *  GLPaint
 *
 *  Created by conejo on 4/18/09.
 *  Copyright 2009 notengo. All rights reserved.
 *
 */
GLuint			    brushTexture;
 
GLuint		textureId;
GLuint			    spriteTexture;
GLuint				drawingTexture;
GLuint				drawingFramebuffer;


int tilesLoadedi, tilesLoadedj;
bool shiroEnd;
bool kuroEnd;

short shiroA;
short kuroA;
short shiroFPS;
short kuroFPS;
int gameColor;
int gameTimer;
int gameState;
int gameLevel;
int gameState2;
BOOL started;
BOOL released;
BOOL touched;
CGPoint mouse;

CGPoint shirokop;
CGPoint kurokop;

CGPoint prevMouse;
CGImageRef		brushImage;
 
CGImageRef image;

CGContextRef	brushContext;
GLubyte			*brushData;
size_t			width, height;

UIImage *levelImg;


#define NEGRO		0
#define BLANCO		1


#define kFPS	3


#define LOAD_MENU		0
#define MENU_WAIT		1
#define LOAD_GAME		2
#define GAME_WAIT		3
#define MENU_UNLOAD		4
#define LOAD_MENU2		5
#define LOAD_SPLASH		6
#define SPLASH_WAIT		7
#define SPLASH_UNLOAD	8
#define GAME_PAUSE		9
#define LOAD_PAUSE		10
#define UNLOAD_PAUSE	11
#define LOAD_GAME_FINAL	12
#define LOADTILE0		13
#define LOADTILE1		14
#define LOADTILE2		15
#define LOADTILE3		16
#define LOADTILE4		17
#define LOAD_CREDITS		18
#define CREDITS_WAIT		19
#define CREDITS_UNLOAD	20
#define TUTORIAL_LOAD	21
#define TUTORIAL_WAIT	22
#define TUTORIAL_UNLOAD	23
#define LOAD_TITLE		24
#define TITLE_WAIT		25
#define TITLE_UNLOAD	26
#define CREDITS_WAIT2	27
#define LOAD_CREDITS2	28
#define SELECT_CHAPTER1	29
#define SELECT_CHAPTER2	30
#define LOAD_CHAPTER1	31
#define GAME_END		32



int gameMusic;
int speedUpDrawing;
int score;