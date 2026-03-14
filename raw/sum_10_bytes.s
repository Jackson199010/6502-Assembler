; Table wiht data 0200 - 02ff
; The goal is to sum up the first 10 bytes and store it as a 16-bit result at the $02-$03 address. The address is stored in the $00-$01 bytes
; (Assuming that the table is zeroed out) 

; Table start address
lda #$00
sta $00
lda #$02
sta $01

; Clear the result acc
lda #$00
sta $02
sta $03

; Prepare some data in the table. The sum must be $268
lda #$55
sta $0200
sta $0201
sta $0202
lda #$3f
sta $0205
sta $0206
lda #$03
sta $0207
sta $0208
lda #$e5
sta $0209
; Some mock data that is out of the range of the addition
lda #$10
sta $0210
sta $0215
sta $0222
sta $02ff

ldy #9

LOOP:
  lda ($00), y
  clc
  adc $02
  sta $02
  bcc NO_CARRY
  inc $03
NO_CARRY:
  dey
  bpl LOOP