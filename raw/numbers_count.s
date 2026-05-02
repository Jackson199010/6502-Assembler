;----------------------------------------------------------------
; A program to count the numbers between 0 and 9 in the table of n elements
; The table starts at the defined address. The first entry is a length of the table
; The address is defined at the $00-$01 location. The result will be sored at the $02
;----------------------------------------------------------------

; Setting up the table $0200
lda #$0a
sta $0200

lda #$02
sta $0201
lda #$ab
sta $0202

lda #$0c
sta $0203
lda #$05
sta $0204

lda #$04
sta $0205
lda #$fb
sta $0206

lda #$dc
sta $0207
lda #$09 
sta $0208

lda #$08
sta $0209
lda #$fb
sta $020a

; The result should be 5

; Setting up a pointer to the table and zero-out the result accumulators
lda #$02
sta $01
lda #$00
sta $00
sta $02

tay
lda ($00), y
tay

LOOP:
  lda ($00), y
  cmp #$0a
  bcs NOT_IN_RANGE
  inc $02
  
NOT_IN_RANGE:
  dey
  bne LOOP