; Store some sample data between the 0200 - 0305 memory locations
lda #$01
sta $0200
sta $0251
sta $0300
sta $0305

; Pointers to the copy addresses
; Start address to copy
lda #$00
sta $00
lda #$02
sta $01
; Start address to paste
lda #$00
sta $02
lda #$04
sta $03

ldx #$01 ; Blocks amount (0 means the rest)
ldy #0   ; Pointer to a specific element of the table

COPY_LOOP:
  lda ($00), y
  sta ($02), y
  dey ; iterate from 0, than back from 255 down till 0 
  bne COPY_LOOP
NEXT_BLOCK:
  ; Increase hi bits of the "from" and "to pointers
  inc $01
  inc $03
  dex ; Decrease processed blocks 
  bmi DONE 
  bne COPY_LOOP ; Continy copy whole tables while we have blocks
REST:           ; If the whole blocks are done - copyin the rest (provided the rest exists)
  ; cover the corner case when y == 0
  ldy #0
  lda ($00), y
  sta ($02), y

  ldy #$05 ; Set up the rest
  bne COPY_LOOP
DONE:  
