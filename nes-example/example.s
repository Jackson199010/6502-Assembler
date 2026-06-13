; Define PPU Registers
PPU_CONTROL = $2000
PPU_MASK = $2001
PPU_STATUS = $2002
PPU_SPRAM_ADDRESS = $2003
PPU_SPRAM_IO = $2004
PPU_VRAM_ADDRESS1 = $2005
PPU_VRAM_ADDRESS2 = $2006
PPU_VRAM_IO = $2007
SPRITE_DMA = $4014

; Define APU Registers
APU_DM_CONTROL = $4010
APU_CLOCK = $4015

; Joystick values
JOYPAD1 = $4016
JOYPAD2 = $4017

; Gamepad bit values
PAD_A = $01
PAD_B = $02
PAD_SELECT = $04
PAD_START = $08
PAD_U = $10
PAD_D = $20
PAD_L = $40
PAD_R = $80

; --------------------------------- Segments --------------------------------- 
.segment "HEADER"
INES_MAPPER = 0 ; 0 = NROM
INES_MIRROR = 0 ; 0 - Hor. mirroring, 1 - Vert. mirroring
INES_SRAM   = 0 ; 1 - Battery backed SRAM at $6000-7fff

.byte 'N', 'E', 'S', $1a ; ID
.byte $02 ; 16k PRG bank count
.byte $01 ; 8k CHR bank count
.byte INES_MIRROR | (INES_SRAM << 1) | ((INES_MAPPER & $f) << 4)
.byte (INES_MAPPER & %11110000)
.byte $0, $0, $0, $0, $0, $0, $0, $0 ; Padding

.segment "VECTORS"
.word nmi
.word reset
.word irq

;*******************************************************
; 6502 Zero Page Memory (256 bytes)
;*******************************************************
.segment "ZEROPAGE"
nmi_ready: .res 1 ; Set to 1 to push a PPU frame update and 2 to turn rendering off next NMI.
gamepad: .res 1 ; Stores the current gamepad values
d_x: .res 1 ; X velocity of the ball
d_y: .res 1; Y velocity of the ball

;*******************************************************
; Sprite OAM Data area - copied to VRAM in NMI routine
;*******************************************************
.segment "OAM"
oam: .res 256

;*******************************************************
; Our default palette has 16 entries for tiles 
; and 16 entries for sprites
;*******************************************************
.segment "RODATA"
default_palette: 
  .byte $0f, $15, $26, $37 ; background 0 - purple/pink
  .byte $0f, $09, $19, $29 ; background 1 - green
  .byte $0f, $01, $11, $21 ; background 2 - blue
  .byte $0f, $00, $10, $30 ; background 3 - greyscale
  .byte $0f, $18, $28, $38 ; sprite 0 - yellow
  .byte $0f, $14, $24, $34 ; sprite 1 - purple
  .byte $0f, $1b, $2b, $3b ; sprite 2 - teal
  .byte $0f, $12, $22, $32 ; sprite 3 - marine

welcome_text: 
  .byte 'W', 'E', 'L', 'C', 'O', 'M', 'E', 0

;*******************************************************
; Import both the background and sprite character sets
;*******************************************************
.segment "TILES"
.incbin "example.chr"

;*******************************************************
; Remainder of the normal RAM area
;*******************************************************
.segment "BSS"
palette: .res 32 ; The current palette buffer

;*******************************************************
; IRQ Clock Interrupt Routine
;*******************************************************
.segment "CODE"
irq:
  rti

;*******************************************************
; Main application entry point for startup/reset: 
; 
; power on
;    ↓
; disable interrupts, PPU, APU
;    ↓
; set up stack
;    ↓
; wait vblank #1  →  clear RAM + OAM  →  wait vblank #2
;    ↓
; enable NMI
;    ↓
; jmp main  ←─────────────────── game loop starts
;*******************************************************
.segment "CODE"
.proc reset
sei ; mask interrupts
lda #$0
sta PPU_CONTROL  ; disable NMI
sta PPU_MASK ; disable rendering
sta APU_DM_CONTROL ; disable dmc audio channel 
lda #$40
sta JOYPAD2 ; Disable APU frame interrupt requests (it's writing to the JOYPAD2 has this effect)

cld ; disable decimal mode

ldx #$ff
txs ; set the stack pointer

bit PPU_STATUS ; clear 7th bit of ppu status (reading the PPU_STATUS will automatically clear the bit 7) 
wait_vblank: ; waiting for the vblank to happen (bit 7 will be set to 1)
  bit PPU_STATUS
  bpl wait_vblank

; Clearing RAM
lda #$0
tax
clear_ram:
  sta $0000, x
  sta $0100, x
  sta $0200, x
  sta $0300, x
  sta $0400, x
  sta $0500, x
  sta $0600, x
  sta $0700, x
  inx
  bne clear_ram

; Place all sprites offscreen at y = 255
lda #$ff
ldx #$0
clear_oam:
  sta oam, x
  ; The y position of the sprrite controlled by the 1st byte of 4 bytes,
  ; so, we inc x 4 times to get to the y position of the next sprite
  inx
  inx
  inx
  inx
  bne clear_oam

 wait_vblank2: ; waiting for the vblank to happen (bit 7 will be set to 1)
  bit PPU_STATUS
  bpl wait_vblank2 

; Set bit 7 to enable NMI, so the PPU will trigger NMI on every vblank
; Set bit 3 for the sprites
lda #%10001000
sta PPU_CONTROL
jmp main
.endproc

;*******************************************************
; NMI routine
;*******************************************************
.segment "CODE"
.proc nmi
; save registers to the stack, to make sure we won't break anything that was before the interrupt happened
pha
txa
pha
tya
pha

; Decide when we should skip rendering. Using the nmi_ready variable 
lda nmi_ready
bne :+ ; nmi_ready == 0 - not ready to update PPU, exit

  jmp ppu_update_end

:
  cmp #$02 ; nmi_ready == 2 turns rendering off and exit
  bne cont_render
  lda #$0
  sta PPU_MASK
  tax
  stx nmi_ready
  jmp ppu_update_end

; Transfering the sprite table to the video memory
cont_render: ; nmi_ready == 1 continue rendering
; Tells the PPU to start writing sprites from the begining of the OAM
ldx #$0
stx PPU_SPRAM_ADDRESS
; Triggers PPU to transfer 256 bytes from the oam page ($0200)
lda #>oam ; loads hi addres of the oam address ($02)
sta SPRITE_DMA

; Transferring the palette memory into the PPU

; Reapplying PPU settings (NMI enable)
lda #%10001000
sta PPU_CONTROL
; Aim the PPU at palette memory
; We need to write the 16byte address to the PPU_VRAM_ADDRESS2
; Reading the PPU_STATUS first resets its internal latch so the first write treated as
; the hi byte, and the second write - as lo
lda PPU_STATUS ; reset the address latch
lda #$3f
sta PPU_VRAM_ADDRESS2 ; set hi byte ($3f)
stx PPU_VRAM_ADDRESS2 ; set lo ($00)
; Upload the palette
; Copy 32 bytes of the palette memory into the PPU via PPU_VRAM_IO. Writing to it
; automatically increment the carette in the PPU
ldx #$0
loop:
  lda palette, x
  sta PPU_VRAM_IO
  inx
  cpx #$20 ; (32 in decimal)
  bcc loop

; Signal the PPU to render the screen 

; Show sprites and background
lda #%00011110
sta PPU_MASK
; Flags the PPU that update is complete
ldx #$0
stx nmi_ready

; Restore the registers and return from the interrupt
pla
tay
pla
tax
pla
rti
.endproc


;*******************************************************
; Some useful functions
;*******************************************************
.segment "CODE"
; ppu_update: waits untill next NMI and turns rendering on (if not already)
.proc ppu_update
  lda #$01 ; nmi_ready == 1 rendering enabled
  sta nmi_ready 

  loop:
    lda nmi_ready
    bne loop
  
  rts
.endproc

; ppu_off: waits until next NMI and turns rendering off
; (now safe to write PPU directly via PPU_VRAM_IO)
.proc ppu_off
  lda #$02 ; ; nmi_ready == 2 turns rendering off
  sta nmi_ready
  loop:
    lda nmi_ready
    bne loop
  
  rts    
.endproc

; Clear tge first screen name table - $2000 address
.proc clear_nametable
  lda PPU_STATUS ; reset the address latch
  lda #$20 ; store the PPU address $2000
  sta PPU_VRAM_ADDRESS2
  lda #$0
  sta PPU_VRAM_ADDRESS2

  lda #$0
  ldy #30 ; clear 30 rows
  rowloop:
    ldx #32 ; 32 columns
    columnloop:
      sta PPU_VRAM_IO
      dex
      bne columnloop
    dey
    bne rowloop

    ldx #64 ; empty atrribute table
    loop:
      sta PPU_VRAM_IO
      dex
      bne loop
  
  rts
.endproc

; gamepad_poll: this reads the gamepad state into the variable labelled "gamepad"
; This only reads the first gamepad, and also if DPCM samples are played they can
; conflict with gamepad reading, which may give incorrect results.
.proc gamepad_poll
  ; Strobe the gamapad to latch the current button state
  lda #$01
  sta JOYPAD1
  lda #$00
  sta JOYPAD1
  
  ; Read 8 bytes from the interface at $4016
  ldx #$08 
loop:
  pha
  lda JOYPAD1

  and #%00000011
  cmp #%00000001
  pla

  ; rotate carry into gamepad variable
  ror
  dex
  bne loop

  sta gamepad

  rts  
.endproc


;*******************************************************
; Main application logic section (includes game looop)
;*******************************************************
.segment "CODE"
; Main application (rendering is currently off)
.proc main

; initialize the palette table
ldx #$0
paletteloop:
  lda default_palette, x
  sta palette, x
  inx
  cpx #32
  bcc paletteloop

; Clear the first nametable
jsr clear_nametable

; Draw some text on the screen

; Set the PPU address to $208a (row = 4, column = 10. address = base address + 32 * row + column)
; This is the location in the first name table 
lda PPU_STATUS ; reset the address latch
lda #$20
sta PPU_VRAM_ADDRESS2
lda #$8a
sta PPU_VRAM_ADDRESS2

; Copy each byte of the message untill we find 0
ldx #$0
textloop:
  lda welcome_text, x
  sta PPU_VRAM_IO
  inx
  cmp #$0
  beq :+
  jmp textloop
  :
  ; Place out bat sprite on the screen
  lda #180
  sta oam ; set sprite 0 Y position
  lda #120
  sta oam + 3 ; set sprite 0 X position
  lda #1
  sta oam + 1 ; set sprite 0 pattern
  lda #0
  sta oam + 2 ; set sprite 0 attributes

  ; Place ball sprite on the screen
  lda #124
  sta oam + (1 * 4) ; set sprite 1 Y position
  sta oam + (1 * 4) + 3 ; set sprite 1 X position
  lda #2
  sta oam + (1 * 4) + 1 ; set sprite 1 pattern
  lda #0
  sta oam + (1 * 4) + 2 ; set sprite 1 attributes

  ; setting ball initial velocity
  lda #1
  sta d_x
  sta d_y

  jsr ppu_update

mainloop:
  ; Skip reading of the controls if the screen has not been drawn yet
  lda nmi_ready
  cmp #$0
  bne mainloop
  
  ; Reading the gamepad and moving the bat
  jsr gamepad_poll

  lda gamepad

  ; Move tha bat if left or right pressed
  and #PAD_L
  beq NOT_GAMEPAD_LEFT
  ; The Left btn is pressed
  lda oam + 3 ; get X position
  cmp #$0
  beq NOT_GAMEPAD_LEFT
  sec
  sbc #1
  sta oam + 3 ; change the X value to the updated left position
NOT_GAMEPAD_LEFT:
  lda gamepad
  and #PAD_R
  beq NOT_GAMEPAD_RIGHT
  ; The Right btn is pressed
  lda oam + 3 ; get X position
  cmp #248
  beq NOT_GAMEPAD_RIGHT
  clc
  adc #1
  sta oam + 3 ; change the X value to the updated right position
NOT_GAMEPAD_RIGHT:
  ; moves our ball
  lda oam + (1 * 4) + 0
  clc
  adc d_y
  sta oam + (1 * 4) + 0 ; updated the Y coordinate with velocity
  cmp #0
  bne NOT_HITTOP
  ; The ball hit the border - reverse direction
  lda #1
  sta d_y
NOT_HITTOP:
  lda oam + (1 * 4) + 0
  cmp #210 ; check if we hit the bottom
  bne NOT_HITBOTTOM
  lda #$ff ; reverse direction (-1)
  sta d_y
NOT_HITBOTTOM:  
  lda oam + (1 * 4) + 3 ; get the current X
  clc
  adc d_x ; add the X velocity
  sta oam + (1 * 4) + 3
  cmp #0
  bne NOT_HITLEFT
  ; Reverse direction
  lda #1
  sta d_x
NOT_HITLEFT:
  lda oam + (1 * 4) + 3
  cmp #248 ; check if we hit the right border
  bne NOT_HITRIGHT
  lda #$ff ; reverse direction (-1)
  sta d_x
NOT_HITRIGHT:
  lda #1
  sta nmi_ready
  jmp mainloop   
.endproc
