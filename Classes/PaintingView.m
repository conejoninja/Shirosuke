#import "PaintingView.h"
#import "AppController.h"
#import "CMOpenALSoundManager.h"
#import "global.h"


//CLASS IMPLEMENTATIONS:

@implementation PaintingView

@synthesize  location;
@synthesize  previousLocation;

- (id) initWithFrame:(CGRect)frame
{
	NSMutableArray*	recordedPaths;
	
	if((self = [super initWithFrame:frame pixelFormat:GL_RGB565_OES depthFormat:0 preserveBackbuffer:YES])) {
		[self setCurrentContext];
		brushImage = [UIImage imageNamed:@"brush.png"].CGImage;
		width = CGImageGetWidth(brushImage);
		height = CGImageGetHeight(brushImage);
		if(brushImage) {
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
		
		
		
		glDisable(GL_DITHER);
		glMatrixMode(GL_PROJECTION);
		glOrthof(0, frame.size.width, 0, frame.size.height, -1, 1);
		glMatrixMode(GL_MODELVIEW);
		glEnable(GL_TEXTURE_2D);
		glEnableClientState(GL_VERTEX_ARRAY);
		glEnable(GL_POINT_SPRITE_OES);
		glTexEnvf(GL_POINT_SPRITE_OES, GL_COORD_REPLACE_OES, GL_TRUE);
		glPointSize(width);
		[self erase];
		
	}

	
	
	
	
	
	return self;
}








// Releases resources when they are not longer needed.
- (void) dealloc
{
		
	glDeleteFramebuffersOES(1, &drawingFramebuffer);
	glDeleteTextures(1, &drawingTexture);

	
	[super dealloc];
}


- (void) erase
{
	glClear(GL_COLOR_BUFFER_BIT);
	[self swapBuffers];
}


- (void) renderLineFromPoint:(CGPoint)start toPoint:(CGPoint)end
{
	static GLfloat*		vertexBuffer = NULL;
	static NSUInteger	vertexMax = 64;
	NSUInteger			vertexCount = 0,
	count,
	i;

	if(vertexBuffer == NULL)
		vertexBuffer = malloc(vertexMax * 2 * sizeof(GLfloat));

	count = MIN(MAX(ceil( sqrt((end.x - start.x)*(end.x - start.x) + (end.y - start.y)*(end.y - start.y) ) / kBrushPixelStep), 1), 64);
	for(i = 0; i < count; ++i) {
		if(vertexCount == vertexMax) {
			vertexMax = 2 * vertexMax;
			vertexBuffer = realloc(vertexBuffer, vertexMax * 2 * sizeof(GLfloat));
		}
		
		vertexBuffer[2 * vertexCount + 0] = start.x + (end.x - start.x) * ((GLfloat)i / (GLfloat)count);
		vertexBuffer[2 * vertexCount + 1] = start.y + (end.y - start.y) * ((GLfloat)i / (GLfloat)count);
		vertexCount += 1;
	}
	
	glVertexPointer(2, GL_FLOAT, 0, vertexBuffer);
	glDrawArrays(GL_POINTS, 0, vertexCount);
	[self swapBuffers];
}


- (void) playback:(NSMutableArray*)recordedPaths
{
	NSData*				data = [recordedPaths objectAtIndex:0];
	CGPoint*			point = (CGPoint*)[data bytes];
	NSUInteger			count = [data length] / sizeof(CGPoint),
						i;
	
	for(i = 0; i < count - 1; ++i, ++point)
		[self renderLineFromPoint:*point toPoint:*(point + 1)];
	
	[recordedPaths removeObjectAtIndex:0];
	if([recordedPaths count])
		[self performSelector:@selector(playback:) withObject:recordedPaths afterDelay:0.01];
}



- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	
	CGRect				bounds = [self bounds];
	UITouch*	touch = [[event touchesForView:self] anyObject];
	firstTouch = YES;
	location = [touch locationInView:self];
	location.y = bounds.size.height - location.y;
	started = TRUE;
	touched = TRUE;
	mouse = location;
	speedUpDrawing = 0;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{  
	
	if(speedUpDrawing>=10) {
		speedUpDrawing = 0;
	} else {
		speedUpDrawing++;
	CGRect				bounds = [self bounds];
	UITouch*			touch = [[event touchesForView:self] anyObject];
		
	
	if (firstTouch) {
		firstTouch = NO;
		previousLocation = [touch previousLocationInView:self];
		previousLocation.y = bounds.size.height - previousLocation.y;
	} else {
		location = [touch locationInView:self];
	    location.y = bounds.size.height - location.y;
		previousLocation = [touch previousLocationInView:self];
		previousLocation.y = bounds.size.height - previousLocation.y;
	}
	mouse = location;
	prevMouse = previousLocation;
	if(gameState==GAME_WAIT){
		[self renderLineFromPoint:previousLocation toPoint:location];
	}
	}
	
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
		UITouch*			touch = [[event touchesForView:self] anyObject];
		if (firstTouch) {
			firstTouch = NO;
			previousLocation = [touch previousLocationInView:self];
		}
	
	prevMouse = previousLocation;
	touched = FALSE;
	released = TRUE;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	touched = FALSE;
}



@end
