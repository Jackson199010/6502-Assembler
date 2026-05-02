;----------------------------------------------------------------
; A program do a sum of n entries in a table of 16bit numbers
; The starting address of the table located at the $00-$01 address
; The first element of the table is a number of bytes table contains
; The sum will be located at $02-$04 address range
;----------------------------------------------------------------

; Setting up the table $0200
lda #$0a
sta $0200

lda #$76
sta $0201
lda #$fe
sta $0202

lda #$17
sta $0203
lda #$fe
sta $0204

lda #$33
sta $0205
lda #$fb
sta $0206

lda #$dc
sta $0207
lda #$fa
sta $0208

lda #$af
sta $0209
lda #$fb
sta $020a

; 0xFE76 + 0xFE17 + 0xFB33 + 0xFADC + 0xFBAF = 0x04EE4B

; Setting up a pointer to the table and zero-out the result accumulators
lda #$02
sta $01
lda #$00
sta $00
sta $02
sta $03
sta $04

; Setting up counters
tay
lda ($00), y
tax ; X reg stores num of bytes to process
iny

LOOP:
  clc

  ; calc LO
  lda ($00), y
  adc $02
  sta $02

  iny

  ; calc HI
  lda ($00), y
  adc $03
  sta $03

  bcc SKIP_CARRY

  ; propagate the carry
  inc $04
  
SKIP_CARRY:
  iny
  ; Decrement twice after processing 2 bytes
  dex
  dex

  bne LOOP