#ifndef __MUSICD_H
#define __MUSICD_H

#ifndef WIN32

extern "C" void musicd(void);
extern "C" void musicinit(int song);
extern "C" void SFX(int sfx);
extern "C" void SoundIntDMA1Handler(void);
extern "C" void SoundIntDMA2Handler(void);

#else

#	define	musicinit(x)
#	define	SFX(x)
#	define	musicd()

#endif

#define	SETMUSIC(x)	\
	{	\
			musicinit(x);	\
	}

#define SETSFX(x)	\
	{	\
			SFX(x);	\
	}

#define PLAYMUSIC()	\
	{	\
			musicd();	\
	}

#endif
