

#import "EAGLView.h"

//CONSTANTS:

#define kBrushOpacity		1
#define kBrushPixelStep		7
#define kBrushScale			0.01
#define kLuminosity			2
#define kSaturation			0

//CLASS INTERFACES:
 

@interface PaintingView : EAGLView
{
	CGPoint				location;
	CGPoint				previousLocation;
	Boolean				firstTouch;

	
}
@property(nonatomic, readwrite) CGPoint location;
@property(nonatomic, readwrite) Boolean firstTouch;
@property(nonatomic, readwrite) CGPoint previousLocation;

- (void) erase;
@end
