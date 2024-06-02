sendBufferAsm:

    push {r4,r5,r6,r7,lr}
    
    mov r4, r0 ; save buff
    mov r6, r1 ; save pin (pin is ignored for now as we are using GPIO 12 fixed)

    ; Assume buffer length is in r5 and buffer start address is in r4
    ; Example: r5 = length, r4 = buffer start address
    
    ; Set GPIO 12 as output
    ldr r0, =0x40014000  ; Load SIO base address
    ldr r1, =0x1000      ; GPIO 12 set (1 << 12)
    str r1, [r0, #0x04]  ; Set GPIO 12 direction to output

    ; Load addresses of the set and clear registers
    ldr r2, =0x4001401C  ; GPIO_OUT_CLR
    ldr r3, =0x40014018  ; GPIO_OUT_SET
    ldr r1, =0x1000      ; Mask for GPIO 12 (1 << 12)

    cpsid i              ; disable irq
    
    b .start
    
.nextbit:               ;            C0
    str r1, [r3, #0]    ; pin := hi  C2
    tst r7, r0          ;            C3
    bne .islate         ;            C4
    str r1, [r2, #0]    ; pin := lo  C6
.islate:
    lsrs r7, r7, #1     ; r7 >>= 1   C7
    bne .justbit        ;            C8
    
    ; not just a bit - need new byte
    adds r4, #1         ; r4++       C9
    subs r5, #1         ; r5--       C10
    bcc .stop           ; if (r5<0) goto .stop  C11
.start:
    movs r7, #0x80      ; reset mask C12
    nop                 ;            C13

.common:               ;             C13
    str r1, [r2, #0]   ; pin := lo   C15
    ; always re-load byte - it just fits with the cycles better this way
    ldrb r0, [r4, #0]  ; r0 := *r4   C17
    b .nextbit         ;             C20

.justbit: ; C10
    ; no nops, branch taken is already 3 cycles
    b .common ; C13

.stop:    
    str r1, [r2, #0]   ; pin := lo
    cpsie i            ; enable irq

    pop {r4,r5,r6,r7,pc}
    
    ; Constants loaded using literal pool
  ;  .ltorg
