; Table wiht data 0200 - 02ff
; The goal is to reverse order of the first 10 bytes and store them starting at $0300
; (Assuming that the table is zeroed out) 

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

ldy #9
ldx #0

LOOP:
  lda $0200, y
  sta $0300, x
  inx
  dey
  bpl LOOP