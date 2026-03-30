; Find the largest element of a table
;
; The beginning address of the table is contained at memoty adderess $00-$01
; The first entry of the table is the number of bytes it contains
; The program will search for the largest element of the table. 
; Its value will be left in A, and its position will be stored at $03 mem. loc.

FIND_LARGEST:

; Setting up some preconditions
lda #$0a ; Table of 10 elemetns length
sta $0200
lda #$01
sta $0202
sta $0205
sta $020a
lda #$10
sta $0201
sta $0203
lda #$ca ; The largest eleement
sta $0207

lda #$00
sta $00
lda #$02
sta $01

ldy #0  ; Pointer to the first element of the table
lda ($00), y
tay     ; Number of bytes
beq END

dey     ; Decrement length to get the last index
beq END ; The first element is the length of table so we stop if we reach it

lda ($00), y  ; Max value at the begining of the checkig loop
sty $03

LOOP:
  cmp ($00), y
  bcs EL_LOWER
  lda ($00), y
  sty $03 
EL_LOWER:
  dey
  bne LOOP ; The first element is the length of table so we stop if we reach it
END:
  rts


