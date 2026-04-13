; Quick sort algorithm implementation
; A table of 6 elemetns to sort - $0200 - 0205
; Table address is at the $00-$01
; $02 - $09 is reserved for variables

; Fill in elements in the table 
lda #$0a
sta $0200
lda #$07
sta $0201
lda #$08
sta $0202
lda #$09
sta $0203
lda #$01
sta $0204
lda #$05
sta $0205

; Zero page artifacts fill
lda #$00
sta $00
lda #$02
sta $01

; LO_IND = $02 - Lo index
; HI_IND = $03 - Hi index
; PIVOT = $04 - The pivot value
; SWAP_IND = $05 - The swap index
; TMP5 = $06 - Tmp var1
; TMP6 = $07 - Tmp var2
; 

lda #$00 ; Lo index of array to sort
sta $02  ; Store low index at LO_IND 
lda #$05 ; Hi index
sta $03  ; Store hi index at HI_IND 

jsr QUICK_SORT
jmp END

QUICK_SORT:
  lda $03
  cmp $02 ; Compare HI_IND with the LO_IND
  beq QSORT_END
  bcc QSORT_END
  
  ; Ater the Lomuto partition is done the SWAP_IND will be available at the $05
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

  pla ; Restore SWAP_IND from the stack and set it to the LO_IND
  sta $02
  inc $02

  ; Restore HI_IND from the stack
  pla
  sta $03

  jsr QUICK_SORT

  QSORT_END:
rts

; Swap the values that stored by the index in Y registry and the SWAP_IND - $05
SWAP:
  sty $06 ; Save Y registry in the TMP1 var
 
  lda ($00), y
  sta $07 ; Store index1 value in the TMP2 var
  
  ldy $05 ; Load the index2 into the Y
  lda ($00), y ; Load the index2 value into A
  ldy $06 ; Restore the index1 into Y
  sta ($00), y  ; Save the value by index2 into the location by index1 

  ldy $05 ; Load the index2 into the Y
  lda $07 ; Load the value by index1
  sta ($00), y ; Save the value by index1 into the location by index2

  ldy $06 ; Restore the original value of the Y registry
  
rts

; Params: $02 - LO_IND, $03 - HI_IND
; Result will be partitioned table and pivot index in the $05 mem location
LOMUTO_PARTITION:
  lda $02 ; Get LO_IND
  cmp $03 ; Compare it with HI_IND
  beq END_LOMUTO_PARTITION ; exit the partition as the range contains a single element
  
  ldy $03
  lda ($00), y ; Get the pivot stored at the HI_IND
  sta $04 ; Store the pivot value at the PIVOT address 

  ; Set the swap LO_IND -1 and store in at the SWAP_IND
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

  END_LOMUTO_PARTITION:
    inc $05 ; Incrementing swap index befer the swap itself 
    jsr SWAP
rts

END:
  rts