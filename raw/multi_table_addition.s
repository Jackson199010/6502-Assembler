; Adding together the corresponding elements of three tables of definde length
; Result will be stored in a separate table
; Table lengh be stored in the $00 address
; Result will be stored in $0209 - 020b

; Prepare some data in the table.
; 0200 - 0202 - First table 
; 0203 - 0205 - Second table 
; 0206 - 0208 - Third table 
ldx #$01
stx $0200
inx
stx $0201
inx
stx $0202
inx
stx $0203
inx
stx $0204
inx
stx $0205
inx
stx $0206
inx
stx $0207
inx
stx $0208

lda #$03; Table lengh 
sta $00

ldy $00
dey

LOOP:
  clc
  lda $0200, y
  adc $0203, y
  adc $0206, y
  sta $0209, y
  dey
  bpl LOOP