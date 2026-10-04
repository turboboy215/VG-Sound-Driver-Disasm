QUICKTHUNDER MUSIC DRIVER INSTRUCTIONS
--------------------------------------

Include musicd.h and music.h
Link in musicd.o to your code - we are using GCC

Please speak to Hakkim if you are using the ARM linker ! 


Set up the two SoundIntDMA handlers in musicd.h 

EG..

  const IntrFuncp IntrTable[13] = {
    VBlankFunc,     	// V Blank interrupt
    dummy,      	// H Blank interrupt
    dummy,      	// V Counter interrupt
    dummy,      	// Timer 0 interrupt
    dummy,      	// Timer 1 interrupt
    dummy,      	// Timer 2 interrupt
    dummy,      	// Timer 3 interrupt
    dummy,      	// Serial communication interrupt
    dummy,      	// DMA 0 interrupt
    SoundIntDMA1Handler,// DMA 1 interrupt
    SoundIntDMA2Handler,// DMA 2 interrupt
    dummy,      	// DMA 3 interrupt
    dummy,      	// Key interrupt


Set their init flags with your other interupts

EG..
    *(vu16 *)REG_IME  = 1;                      // Set IME 
    *(vu16 *)REG_IE =	V_BLANK_INTR_FLAG 
			| DMA1_INTR_FLAG
		        | DMA2_INTR_FLAG;



To initialize the sound driver do the following (after you have set up the DMA's)..
musicinit(0);

Then you must call "musicd()" once every frame.

To start a tune :
musicinit(tune);  //see list of tunes in music.h

To start an SFX
SFX(sfxnum);


MUSIC DRIVER SPECS
------------------
0.8% processor useage
All hardware audio features supported
Great sound quality / High volume
Prioritized sfx routine
Support for both sample and gameboy compatible channels

