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

    cmp #9
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
DisplayIntro:
    ldx #0
CopyLoop1:
    lda line1, x
    sta 1024 + TITLE_OFFSET, x
    lda line2, x
    sta 1064 + TITLE_OFFSET, x
    lda line3, x
    sta 1104 + TITLE_OFFSET, x
    lda line3, x
    sta 1144 + TITLE_OFFSET, x
    lda line3, x
    sta 1184 + TITLE_OFFSET, x
    lda line3, x
    sta 1224 + TITLE_OFFSET, x
    lda line3, x
    sta 1264 + TITLE_OFFSET, x
    lda line2, x
    sta 1304 + TITLE_OFFSET, x
    lda line1, x
    sta 1344 + TITLE_OFFSET, x
    inx
    cpx #$28
    bne CopyLoop1


.var highlight = 5

    ldx #0
WaitForSpace:
    // Only rotate every 255th loop    
    inx
    bne norotate
    jsr RotateColor
    jsr DisplayText
norotate:

    jsr $FFE4           // get key
    beq WaitForSpace 
    cmp #$20
    bne WaitForSpace    

    rts

// ----------------------------------------------------------------
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
DisplayText:    
    ldx #0
 TextLoop1:
    lda title_txt, x
    beq TextLoop1Done   
    sta TITLE_OFFSET + 1184 + 7, x

    lda #06

    cpx highlight
    bne nohighlight
    lda #01 
nohighlight:
    sta TITLE_OFFSET + (40 * 4) + $d800 + 7, x
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

    lda #$1b       
    sta $d011

    lda #$7e        // 
    sta $d012

    lda $dc0d
    lda $dd0d
    asl $d019
    
    cli
    
    rts

// ----------------------------------------------------------------
irq1:
    asl $d019           // ack
    jsr music.play      
    sjmp $ea81           // jump to old ISR

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


line1:  .byte  32, 32,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249, 32, 32
line2:  .byte  32,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249,249, 32
line3:  .byte 249,249,249,249,249, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32,249,249,249,249,249

*=music.location "Music"
    .fill music.size, music.getData(i)

title_txt:
    .text "hello again - 2021 jaytaph"
    .byte $0

presskey_txt:
    .text "press <space> to begin"
    .byte $0
