;----------------------------------------------------------------
; A program to find a last occured sequence of bytes in a table
; The table address is located at the $00-$01
; The length of the table is located at the first byte of the table
; The address of the search template is located in the table at the $02-$03 address
; The length of the search template is located at the first byte of the table
; The X register will store an index where the search tpl is found
; It will store #$ff otherwise
;----------------------------------------------------------------

; Setting up the main table $0200
lda #$0a
sta $0200
lda #$4f
sta $0201
lda #$bd
sta $0202
lda #$c0
sta $0203
lda #$bd
sta $0204
lda #$c0
sta $0205
lda #$11
sta $0206
lda #$22
sta $0207
lda #$09
sta $0208
lda #$08
sta $0209
lda #$fb
sta $020a

; A pointer to the main table
lda #$00
sta $00
lda #$02
sta $01
 
; Setting up the template label $020b
lda #$03
sta $020b
lda #$4f
sta $020c
lda #$bd
sta $020d
lda #$c0
sta $020e

; A pointer to the template table
lda #$0b
sta $02
lda #$02
sta $03

; Setting up some TMP vars
lda #$00
sta $04 ; main table cursor
sta $05 ; tpl table cursor 
sta $06 ; tpl table length 
sta $07 ; temp value for comparison

; Get the first element of the template table (length) and store it as the tpl table cursor
ldy #$00
lda ($02), y
sta $05  
sta $06

; Get the first element of the main table (length) and start iterating from it
; (means from the last element of the table)
ldy #$00
lda ($00), y
tay
sty $04 ; store cursor of the main table index

LOOP:
  lda ($00), y ; load next main table element
  sta $07 ; store main table value it tmp var to compare it later 

  ; Load next tpl table element
  ldy $05 
  lda ($02), y

  ; Compare main table and tpl table elements
  cmp $07
  bne ITEM_NOT_MATCH

  dec $05 ; Decrement the tpl cursor to check the next element in the next iteration
  beq FOUND ; Nothing to check we traversed all over the tpl. Sequence is found
  bpl PREPARE_FOR_NEXT_ITERATION
 
ITEM_NOT_MATCH:
  ; Reset main table cursor to the position it was before testing sequence
  ; The position calc formula is: tpl_table_length - tpl_table_cursor + main_table_cursor
  sec
  lda $06
  sbc $05
  clc
  adc $04
  sta $04

  ; Reset tpl cursor to the last element position
  lda $06
  sta $05
  
PREPARE_FOR_NEXT_ITERATION:
  dec $04 ; decrease main table cursor
  ldy $04
  bne LOOP
  beq NOT_FOUND
 
FOUND:
  ldx $04
  jmp END 

NOT_FOUND:
  ldx #$ff

END: