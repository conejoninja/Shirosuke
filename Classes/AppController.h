

#import "PaintingView.h"
#import "SoundEffect.h"
#import "Data.h"
#import "UKImage.h"

@class CMOpenALSoundManager;
//CLASS INTERFACES:

@interface AppController : NSObject <UIAccelerometerDelegate> 
{
	UIWindow			*window;
	PaintingView		*drawingView;

	UIAccelerationValue	myAccelerometer[3];
	SoundEffect			*erasingSound;
	SoundEffect			*selectSound;
	CFTimeInterval		lastTime;


	IBOutlet GLuint scorelevel;
	
	
	CGPoint lastPoint;
	CGPoint currentPoint;

	BOOL mouseSwiped;	
	int mouseMoved;
	CGRect pantalla;
	CGImageRef kuroImg;
	IBOutlet UIImageView *kuroView;
	IBOutlet UIImageView *kuroLove;
	IBOutlet UIImageView *kuroDefLeft;
	IBOutlet UIImageView *kuroDefRight;
	CGPoint kurop;
	CGImageRef shiroImg;
	IBOutlet UIImageView *shiroView;
	IBOutlet UIImageView *shiroLove;
	IBOutlet UIImageView *shiroDefLeft;
	IBOutlet UIImageView *shiroDefRight;
	
	IBOutlet UIImageView *shiroko;
	IBOutlet UIImageView *kuroko;
	IBOutlet UIImageView *shirokoLove;
	IBOutlet UIImageView *kurokoLove;
	
	IBOutlet UIImageView *menuView;
	IBOutlet UIImageView *manoView;
	
	IBOutlet UIImageView *handkuro;
	IBOutlet UIImageView *handshiro;
	
	IBOutlet UIImageView *datosa;
	IBOutlet UIImageView *datosb;
	IBOutlet UIImageView *datosc;
	IBOutlet UIImageView *datosd;
	
	IBOutlet UIImageView *chapa;
	IBOutlet UIImageView *chapb;
	IBOutlet UIImageView *chapc;
	IBOutlet UIImageView *chapd;
	IBOutlet UIImageView *chape;
	IBOutlet UIImageView *chapf;
	IBOutlet UIImageView *chapg;
	IBOutlet UIImageView *chaph;
	IBOutlet UIImageView *chapi;
	IBOutlet UIImageView *chapj;

	
	CGPoint shirop;
	CGPoint shirov;
	CGPoint kurov;
	int shiroState;
	int shiroTimer;
	int kuroState;
	int kuroTimer;
	
	


}
@property (nonatomic) GLuint scorelevel;
- (NSString *)dataFilePath;
- (void)ApplicationWillTerminate:(NSNotification *)notification;

@end
