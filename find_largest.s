; Table wiht data 0200 - 02ff
; The goal is to search the table for its largest element and then store it at the address $00
; (Assuming that the table is zeroed out) 


; Prepare some data in the table.
lda #$ff
sta $0200
lda #$3f
sta $0205
lda #$03
sta $0233
sta $02ab
lda #$fa
sta $02ef

lda #$00
sta $00

ldy #0

LOOP:
  lda $0200, y
  cmp $00
  bcc SKIP_SAVE_NEW_BIG
  sta $00
SKIP_SAVE_NEW_BIG:
  iny
  bne LOOP