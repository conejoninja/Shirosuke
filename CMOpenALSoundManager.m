//
//  CMOpenALSoundManager.m
//
//  Created by Alex Restrepo on 5/19/09.
//  Copyright 2009 Colombiamug. All rights reserved.
//
//	Portions of this code are adapted from Apple's oalTouch example and
//	http://www.gehacktes.net/2009/03/iphone-programming-part-6-multiple-sounds-with-openal/
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.

#import "CMOpenALSoundManager.h"
#import "CMOpenALSound.h"
#import "SynthesizeSingleton.h"

@interface CMOpenALSoundManager()
@property (nonatomic, retain) NSMutableDictionary *soundDictionary;
@property (nonatomic, retain) CMOpenALSound *backgroundAudio;
@end

@interface CMOpenALSoundManager(private)
- (BOOL) initOpenAL;
- (void) cleanUpAudioChannel;
- (NSString *) keyForSoundID:(NSUInteger)soundID;
@end

@implementation CMOpenALSoundManager
@synthesize soundDictionary, soundFileNames, backgroundAudio, isiPodAudioPlaying;

#if USE_AS_SINGLETON
SYNTHESIZE_SINGLETON_FOR_CLASS(CMOpenALSoundManager);
#endif

#pragma mark -
#pragma mark init/dealloc
- (id) init
{
	self = [super init];		
	if (self != nil) 
	{
		//session info
		AudioSessionInitialize(NULL, NULL, NULL, NULL);	
		[self checkIfiPodIsPlaying];
		
		if(![self initOpenAL])
		{
			NSLog(@"OpenAL initialization failed!!");
			[self release];
			self = nil;
			return nil;
		}		
		
		self.soundDictionary = [NSMutableDictionary dictionary];
		self.soundEffectsVolume = 1.0;
		self.backgroundMusicVolume = 1.0;
	}
	return self;
}

// start up openAL
-(BOOL) initOpenAL
{
	ALCcontext	*context = NULL;
	ALCdevice	*device = NULL;

	// Initialization
	device = alcOpenDevice(NULL); // select the "preferred device"
	if(!device) return NO;
		
	// use the device to make a context
	context = alcCreateContext(device, NULL);
	if(!context) return NO;
	
	// set my context to the currently active one
	alcMakeContextCurrent(context);
	
	NSLog(@"oal inited ok");
	return YES;	
}

- (void) dealloc
{
	[self shutdownOpenAL];
	
	[backgroundAudio release];
	[soundFileNames release];
	[soundDictionary release];

	[super dealloc];
}

- (void) shutdownOpenAL
{
	self.backgroundAudio = nil;
	self.soundFileNames = nil;
	self.soundDictionary = nil;
	
	ALCcontext	*context = NULL;
    ALCdevice	*device = NULL;
	
	//Get active context (there can only be one)
    context = alcGetCurrentContext();
	
    //Get device for active context
    device = alcGetContextsDevice(context);
	
    //Release context
    alcDestroyContext(context);
	
    //Close device
    alcCloseDevice(device);
}

#pragma mark -
#pragma mark audio session mgmt

//code from: http://www.idevgames.com/forum/showthread.php?p=143030
//this will return YES if another audio source is active (iPod app)
- (void) checkIfiPodIsPlaying
{
	UInt32	propertySize, audioIsAlreadyPlaying;
	
	// do not open the track if the audio hardware is already in use (could be the iPod app playing music)
	propertySize = sizeof(UInt32);
	AudioSessionGetProperty(kAudioSessionProperty_OtherAudioIsPlaying, &propertySize, &audioIsAlreadyPlaying);	
	
	if (audioIsAlreadyPlaying != 0 && ![self isBackGroundMusicPlaying]) //audio could be ours...
	{
		isiPodAudioPlaying = YES;
		
		UInt32	sessionCategory = kAudioSessionCategory_AmbientSound;
		AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
		AudioSessionSetActive(YES);
	}
	else
	{
		[self cleanUpAudioChannel];
	}
}

- (void) cleanUpAudioChannel
{	
	isiPodAudioPlaying = NO;
	
	// since no other audio is *supposedly* playing, then we will make darn sure by changing the audio session category temporarily
	// to kick any system remnants out of hardware (iTunes (or the iPod App, or whatever you wanna call it) sticks around)
	UInt32	sessionCategory = kAudioSessionCategory_MediaPlayback;
	AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
	AudioSessionSetActive(YES);
	
	// now change back to ambient session category so our app honors the "silent switch"
	sessionCategory = kAudioSessionCategory_AmbientSound;
	AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
}

#pragma mark -
#pragma mark cleanup
- (void) purgeSounds
{
	//call this if you get a memory warning, to unload all sounds from memory
	[self.soundDictionary removeAllObjects];	

	//if there's a background audio that's not playing, remove that too...
	if(![backgroundAudio isPlaying])
		self.backgroundAudio = nil;
}

#pragma mark -
#pragma mark background music playback
// plays a file as the background audio...
- (void) playBackgroundMusic:(NSString *)file
{
	[self playBackgroundMusic:file forcePlay:NO];
}

- (void) playBackgroundMusic:(NSString *)file forcePlay:(BOOL)forcePlay
{
	[backgroundAudio stop]; //if there's audio already playing...
		
	if(forcePlay)	//if we want to kill other audio sources, like the iPod...
		[self cleanUpAudioChannel];
	
	if(isiPodAudioPlaying) //if other background audio is playing bail out...
		return;
	
	CMOpenALSound *audio = [[CMOpenALSound alloc] initWithSoundFile:file doesLoop:YES];
	[audio play];
	audio.volume = self.backgroundMusicVolume;
	
	self.backgroundAudio = audio;
	[audio release];
}

- (void) stopBackgroundMusic
{
	[backgroundAudio stop];
}

- (void) pauseBackgroundMusic
{
	[backgroundAudio pause];
}

- (void) resumeBackgroundMusic
{
	[backgroundAudio play];
}

#pragma mark -
#pragma mark effects playback
// grab the filename (key) from the filenames array
- (NSString *) keyForSoundID:(NSUInteger)soundID
{
	if(soundID < 0 || soundID >= [soundFileNames count])
		return nil;
	
	return [[soundFileNames objectAtIndex:soundID] lastPathComponent];
}

- (void) playSoundWithID:(NSUInteger)soundID
{	
	//get sound key
	NSString *soundFile = [self keyForSoundID:soundID];
	if(!soundFile) return;
	
	CMOpenALSound *sound = [soundDictionary objectForKey:soundFile];
	
	if(!sound)
	{
		//create a new sound
		sound = [[CMOpenALSound alloc] initWithSoundFile:soundFile doesLoop:NO]; //this will return nil on failure
		
		if(!sound) //error
			return;
		
		[soundDictionary setObject:sound forKey:soundFile];
		[sound release];
	}
	
	[sound play];
	sound.volume = self.soundEffectsVolume;
}

- (void) stopSoundWithID:(NSUInteger)soundID
{
	NSString *soundFile = [self keyForSoundID:soundID];
	if(!soundFile) return;
	
	CMOpenALSound *sound = [soundDictionary objectForKey:soundFile];		
	[sound stop];
}

- (void) pauseSoundWithID:(NSUInteger)soundID
{
	NSString *soundFile = [self keyForSoundID:soundID];
	if(!soundFile) return;
	
	CMOpenALSound *sound = [soundDictionary objectForKey:soundFile];		
	[sound stop];
}

- (void) rewindSoundWithID:(NSUInteger)soundID
{
	NSString *soundFile = [self keyForSoundID:soundID];
	if(!soundFile) return;
	
	CMOpenALSound *sound = [soundDictionary objectForKey:soundFile];
	[sound rewind];
}

- (BOOL) isPlayingSoundWithID:(NSUInteger)soundID
{
	NSString *soundFile = [self keyForSoundID:soundID];
	if(!soundFile) return NO;
	
	CMOpenALSound *sound = [soundDictionary objectForKey:soundFile];		
	return [sound isAnyPlaying];
}

- (BOOL) isBackGroundMusicPlaying
{
	return [backgroundAudio isPlaying];
}

#pragma mark -
#pragma mark properties
- (float) backgroundMusicVolume
{	
	return backgroundMusicVolume;
}

- (void) setBackgroundMusicVolume:(float) newVolume
{	
	backgroundMusicVolume = newVolume;
	backgroundAudio.volume = newVolume;
}

- (float) soundEffectsVolume
{
	return soundEffectsVolume;
}

- (void) setSoundEffectsVolume:(float) newVolume
{
	soundEffectsVolume = newVolume;
	for(NSString *key in soundDictionary)
	{
		((CMOpenALSound *)[soundDictionary objectForKey:key]).volume = newVolume;
	}
}
@end
