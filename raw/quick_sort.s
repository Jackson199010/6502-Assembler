;--------------------------------------
; Quick sort algorithm implementation
; A table of 8 elements to sort - $0200 - 0207
; Table address is at the $00-$01
; $02 - $07 is reserved for variables
; LO_IND = $02 - Lo index
; HI_IND = $03 - Hi index
; PIVOT = $04 - The pivot value
; SWAP_IND = $05 - The swap index
; SWAP_TMP_Y = $06 - Tmp var for holding Y reg value during the swap
; SWAP_TMP_VAL = $07 - Tmp var for holding swap value
;--------------------------------------

; Fill in elements in the table 
lda #$0f
sta $0200
lda #$01
sta $0201
lda #$04
sta $0202
lda #$be
sta $0203
lda #$12
sta $0204
lda #$bb
sta $0205
lda #$1f
sta $0206
lda #$22
sta $0207

; Zero page artifacts fill
lda #$00
sta $00
lda #$02
sta $01


lda #$00 ; Lo index of array to sort
sta $02  ; Store low index at LO_IND 
lda #$07 ; Hi index
sta $03  ; Store hi index at HI_IND 

jsr QUICK_SORT
jmp END


QUICK_SORT:
  lda $03
  cmp $02 ; Compare HI_IND with the LO_IND
  beq QSORT_END
  bcc QSORT_END

  ; After the Lomuto partition is done, the SWAP_IND will be available at the $05
  jsr LOMUTO_PARTITION

  ; Push the HI_IND in the stack to pop it on the right partition sorting
  lda $03 
  pha

  ; Push SWAP_IND into the stack to use it as a LO_IND on the right partition sorting
  lda $05
  pha

  sta $03
  dec $03
  jsr QUICK_SORT

  ; Restore SWAP_IND from the stack and set it to the LO_IND
  pla 
  sta $02
  inc $02

  ; Restore HI_IND from the stack
  pla
  sta $03

  jsr QUICK_SORT

QSORT_END:
  rts

;---------------------------------------
; Swap the values that are stored by the index in the Y registry and the SWAP_IND - $05
;---------------------------------------
SWAP:
  sty $06 ;  Save Y registry in the SWAP_TMP_Y var

  ; Store the value by the Y index in the SWAP_TMP_VAL var
  lda ($00), y
  sta $07

  ; Load the value by the SWAP_IND
  ldy $05 
  lda ($00), y

  ; Store the value by the SWAP_IND in the location stored in the SWAP_TMP_Y
  ldy $06
  sta ($00), y

  ; Store the SWAP_TMP_VAL in the location by the SWAP_IND
  ldy $05
  lda $07 
  sta ($00), y

  ldy $06 ; Restore the original value of the Y registry
rts

;---------------------------------------
; LOMUTO_PARTITION
; Params: $02 - LO_IND, $03 - HI_IND
; Result: partitioned table, pivot index in $05
;---------------------------------------
LOMUTO_PARTITION:
  lda $02 ; Get LO_IND
  cmp $03 ; Compare it with HI_IND
  ; Defensive guard — caller already filters LO == HI
  beq END_LOMUTO_PARTITION

  ldy $03
  lda ($00), y ; Get the pivot stored at the HI_IND
  sta $04 ; Store the pivot value at the PIVOT address 

  ; Set the swap LO_IND -1 and store it at the SWAP_IND
  lda $02 
  sta $05
  dec $05

  ldy $02 ; Load LO_IND into the Y
  LOOP:
    lda ($00), y ; Load the value stored at the LO_IND
    cmp $04 ; Compare the value with the pivot value
    bcs SKIP_SWAP

    ; Pivot is higher. Do the swap
    inc $05 ; Incrementing swap index before the swap itself 
    jsr SWAP
  SKIP_SWAP:
    iny
    cpy $03 ; Compare with HI_IND
    bcc LOOP

    inc $05 ; Incrementing swap index before the final swap 
    jsr SWAP  
END_LOMUTO_PARTITION:
  rts

END:
  brk