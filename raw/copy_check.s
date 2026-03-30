; Write a memory test program which will zero a 256-word block and verify each location is 0.
; Then, it will write all 1's and verify the contents of the block.
; Next, it will wtiye 01010101 and verify the contents.
; Finally, it will write 10101010 and verify the contents

; Block range $0200 - $02ff
; If everything is correct $00 address will be set with a 1. Otherwise 0 will be set

; There're 4 values to set and check. They will be stored in the $01, $02, $03 and $04 addresses
lda #0
sta $01
lda #%11111111
sta $02
lda #%01010101
sta $03
lda #%10101010
sta $04


ldx #0 ; Index to track number of actions that has to be done

PerformAction:
  ldy #0      ; loop index
  lda $01, x  ; value
  WriteLoop: 
    sta $0200, y
    iny
    bne WriteLoop
  

  ldy #0   ; loop index
  CheckLoop:
    lda $0200, y
    cmp $01, x
    bne Error
    iny
    bne CheckLoop  

  inx
  cpx #$04 ; Number of actions
  bne PerformAction 

Success: 
  lda #$01
  sta $00
  jmp End 

Error:
  lda #0
  sta $00

End: