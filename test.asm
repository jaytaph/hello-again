.var music = LoadSid("Desert_Decision.sid")
BasicUpstart2(Start)

*=$c000  "starting address of the program"

.const BORDER = $d020
.const SCREEN = $d021

.var xpos = 160
.var ypos = 100

.const SP0X	= $D000
.const SP0Y	= $D001
.const MSBX	= $D010

.const CLRSCR = $E544
.const SCNKEY = $FF9F

// Start the title logo at which line 
.const TITLE_OFFSET = 40 * 4


Start:
    jsr SetupSid
    jsr SetupScreen

    jsr DisplayIntro

    jsr CLRSCR       // Clear screen
    jsr SetupSprites
MainLoop:
    jsr SCNKEY      // Scan key
    lda $00CB

    cmp #9          // Compare keys and act accordingly
    beq up
    cmp #13
    beq down
    cmp #10
    beq left
    cmp #18
    beq right

    jmp MainLoop
 
 
 up:
    ldy SP0Y
    cpy #$32
    beq MainLoop
    dey
    sty SP0Y
    jmp MainLoop
down:
    ldy SP0Y
    cpy #$E4
    beq MainLoop
    iny
    sty SP0Y
    jmp MainLoop
left:
    ldx SP0X
    dex
    stx SP0X
    cpx #255
    lda #0
    sta MSBX
    jmp MainLoop
right:
    ldx SP0X
    inx
    stx SP0X
    cpx #255
    bne MainLoop
    lda #1
    sta MSBX
    jmp MainLoop


// ----------------------------------------------------------------
SetupScreen:
    lda #0          // Set bg/fg to black
    sta SCREEN
    sta BORDER

    jsr CLRSCR
    rts

// ----------------------------------------------------------------
SetupSprites:
    ldx #$0
CopyLoop:
    lda balloon, x
    sta $2000, x
    inx
    cpx #63
    bne CopyLoop

    ldx #160        // add sprite to screen
    ldy #100
    stx SP0X
    sty SP0Y

    lda #%00000001  // Enable sprite 1
    sta $d015

    lda #$80        // Point to $2000 in the vic, where we just copied the sprite to
    sta $07F8 

    rts

// ----------------------------------------------------------------
// Copies the into to screen, together with the colors
DisplayIntro:
    ldx #0
CopyLoop1:
    lda line1, x
    sta $0400 + 0 + TITLE_OFFSET, x
    lda line2, x
    sta $0400 + 40 + TITLE_OFFSET, x
    lda line3, x
    sta $0400 + 80 + TITLE_OFFSET, x
    lda line3, x
    sta $0400 + 120 + TITLE_OFFSET, x
    lda line3, x
    sta $0400 + 160 + TITLE_OFFSET, x
    lda line3, x
    sta $0400 + 200 + TITLE_OFFSET, x
    lda line3, x
    sta $0400 + 240 + TITLE_OFFSET, x
    lda line2, x
    sta $0400 + 280 + TITLE_OFFSET, x
    lda line1, x
    sta $0400 + 320 + TITLE_OFFSET, x

    lda colorlines + 0
    sta $d800 +  0 + TITLE_OFFSET, x
    lda colorlines + 1
    sta $d800 + 40 + TITLE_OFFSET, x
    lda colorlines + 2
    sta $d800 + 80 + TITLE_OFFSET, x
    lda colorlines + 3
    sta $d800 + 120 + TITLE_OFFSET, x
    lda colorlines + 4
    sta $d800 + 160 + TITLE_OFFSET, x
    lda colorlines + 5
    sta $d800 + 200 + TITLE_OFFSET, x
    lda colorlines + 6
    sta $d800 + 240 + TITLE_OFFSET, x
    lda colorlines + 7
    sta $d800 + 280 + TITLE_OFFSET, x
    lda colorlines + 8
    sta $d800 + 320 + TITLE_OFFSET, x

    inx
    cpx #$28
    bne CopyLoop1
        
IntroLoop:
    jsr DisplayText

    jsr $FFE4           // get key
    beq IntroLoop
    cmp #$20            // check for space pressed
    bne IntroLoop    

    rts

// ----------------------------------------------------------------
// Increase the highlight variable until and wrap around 35 chars
RotateColor:
    inc highlight

    lda highlight
    cmp #35
    bne skip
    lda #0
skip:
    sta highlight 

    rts
    
// ----------------------------------------------------------------
// Print text on starting from scrollpos. This will be updated after each
// 7 smooth scrolls in the IRQ, so all seems like a smooth scrolling
ScrollText:    
    ldx #0    
    ldy scrollpos
Scroll:    
    lda presskey_txt, y
    bne nowrap
    ldy #0        // wrap to 0 after the next incy
    jmp Scroll
nowrap:    
    iny
    sta $0400 + (20 * 40), x
    inx
    cpx #40         // do 40 chars
    bne Scroll

    ldy scrollpos
    iny
    lda presskey_txt, y
    bne nowrap2
    ldy #0
nowrap2:
    sty scrollpos       // Store new scroll pos
    rts




// ----------------------------------------------------------------
// Display the title text with the given highlight color 
DisplayText:
    // We don't need to do this on each runs    
    ldx #0
 TextLoop1:
    lda title_txt, x
    beq TextLoop1Done   
    sta TITLE_OFFSET + 1184 + 7, x

    // This could be more efficient: use an old-hightlight-idx and new-highlight-idx. We only have to set these two colors.

    lda #06     // Use this as color
    cpx highlight
    bne nohighlight
    lda #01         // If we are highlighted, we use this color instead
nohighlight:
    sta TITLE_OFFSET + (40 * 4) + $d800 + 7, x      // Store color in color ram
    inx
    jmp TextLoop1
TextLoop1Done:
    rts


// ----------------------------------------------------------------
SetupSid:
    ldx #0
    ldy #0
    lda #music.startSong-1
    jsr music.init

    sei
    lda #<irq1
    sta $0314
    lda #>irq1
    sta $0315
    
    lda #$7f
    sta $dc0d

    lda #$01
    sta $d01a

    lda #$30
    sta $d012
    lda $d011
    and #$7f       
    sta $d011

    lda $dc0d
    lda $dd0d
    asl $d019
    
    cli    
    rts

// ----------------------------------------------------------------
// smooth scrolls decreases a counter between 7 and 0 and pan 1 left on wrap 
SmoothScroll:
    lda scrollx         // Decrease smooth scroll var
    clc
    sbc #1
    cmp #$ff            // wraps around 0?
    bne nopush
    lda #$07            // if so, set back to 7
    sta scrollx
    jsr ScrollText      // and scroll text one character
    rts
nopush:
    and #$07            // no wrapping, just store first 3 bits
    sta scrollx
    rts

// ----------------------------------------------------------------
irq1:
    asl $d019           // ack
    
    lda $D012           // Check if we are on the low or high irq
    cmp #$80
    bcc low_irq
    jmp high_irq

low_irq:
    jsr music.play      // Low IRQ plays music
    jsr SmoothScroll    // increases smooth scroll
    jsr RotateColor     // rotates highlight color

    lda $D016           // Low IRQ means we don't want smooth scrolling at this point
    and #$F8
    sta $D016

    // set next irq trigger on high raster line 
    lda #$c0
    sta $d012

    lda #$f1        // somethingsomething
    sta $d01a

    jmp done

high_irq:
    lda $d016           // High IRQ sets smooth scrolling. THis way, only the lower part of the screen is smooth-scrolling 
    and #$F8
    clc
    adc scrollx
    sta $d016

    // set next irq trigger on low raster line
    lda #$00
    sta $d012

    lda #$f1        // something something again
    sta $d01a

    jmp done

done:
    jmp $ea81           // jump to old ISR

// ----------------------------------------------------------------
balloon:
	.byte   0, 127,   0
	.byte   1, 255, 192
	.byte   3, 255, 224
	.byte   3, 227, 224
	.byte   7, 217, 240
	.byte   7, 223, 240
	.byte   7, 217, 240
	.byte   3, 231, 224
	.byte   3, 255, 224
	.byte   3, 255, 224
	.byte   2, 255, 160
	.byte   1, 127,  64
	.byte   1,  62,  64
	.byte   0, 156, 128
	.byte   0, 156, 128
	.byte   0,  73,   0
	.byte   0,  73,   0
	.byte   0,  62,   0
	.byte   0,  62,   0
	.byte   0,  62,   0
	.byte   0,  28,   0


colorlines: .byte  2, 7, 2, 7, 2, 7, 2, 7, 2, 7, 2, 7, 2, 7

line1:  .byte  32, 32,32,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,32, 32, 32
line2:  .byte  32,32,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,32, 32
line3:  .byte 32,249,249,249,249, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,249,249,249,249,32

*=music.location "Music"
    .fill music.size, music.getData(i)

title_txt:
    .text "hello again - 2021 jaytaph"
    .byte $0

presskey_txt:
    .text "press <space> to begin   -   "  
    .byte $0

scrollpos: .byte $0
highlight: .byte $05

scrollx: .byte $07
