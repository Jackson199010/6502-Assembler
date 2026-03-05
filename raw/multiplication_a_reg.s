; Multiplication of two 8 bit numbers using the shift and add method

; Init values
lda #$fe
sta $00 ; Multiplied value

lda #$88
sta $01 ; Multiplier

lda #0  ; Hi res
sta $02 ; Lo result
ldx #8  ; Counter for iterations

; Testing the right most bit and do the addition
; if it's 1, otherwise jump to NOADD
MULT:
  lsr $01 ; $01 = MPR
  bcc NOADD
  ; Store a temp data in the Hi result
  ; gradually it will be shifted right, to the Lo
  ; Register A contains 
  clc 
  adc $00 ; $00 = MPD

; Shift 1 bit to the right from hi to lo on each iteration
NOADD: 
  ; Shift the right most bit from Hi to the left most bit of Lo
  ror A ; Hi result
  ror $02 ; $02 = Lo result

  dex
  bne MULT