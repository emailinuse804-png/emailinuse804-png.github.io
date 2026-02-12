; ============================================================================
; Interrupt Service Routines (ISR) and IRQ handlers
; ============================================================================
; These are the low-level assembly stubs that save CPU state, call the C
; handler, then restore state and return from the interrupt.
; ============================================================================

; External C handlers
extern isr_handler
extern irq_handler

; ============================================================================
; Common ISR stub - saves state and calls C handler
; ============================================================================
isr_common_stub:
    pusha               ; Push all general purpose registers
    mov ax, ds
    push eax            ; Save data segment

    mov ax, 0x10        ; Load kernel data segment
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    call isr_handler    ; Call C handler

    pop eax             ; Restore data segment
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    popa                ; Restore registers
    add esp, 8          ; Clean up error code and ISR number
    sti
    iret                ; Return from interrupt

; ============================================================================
; Common IRQ stub - saves state and calls C handler
; ============================================================================
irq_common_stub:
    pusha
    mov ax, ds
    push eax

    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    call irq_handler

    pop ebx
    mov ds, bx
    mov es, bx
    mov fs, bx
    mov gs, bx
    popa
    add esp, 8
    sti
    iret

; ============================================================================
; ISR Definitions (CPU Exceptions 0-31)
; ============================================================================
; Some exceptions push an error code, others don't.
; For consistency, we push a dummy 0 for those that don't.

%macro ISR_NOERRCODE 1
global isr%1
isr%1:
    cli
    push byte 0         ; Dummy error code
    push byte %1        ; Interrupt number
    jmp isr_common_stub
%endmacro

%macro ISR_ERRCODE 1
global isr%1
isr%1:
    cli
    push byte %1        ; Interrupt number (error code already pushed by CPU)
    jmp isr_common_stub
%endmacro

; CPU Exceptions
ISR_NOERRCODE 0     ; Division by zero
ISR_NOERRCODE 1     ; Debug
ISR_NOERRCODE 2     ; NMI
ISR_NOERRCODE 3     ; Breakpoint
ISR_NOERRCODE 4     ; Overflow
ISR_NOERRCODE 5     ; Bound range exceeded
ISR_NOERRCODE 6     ; Invalid opcode
ISR_NOERRCODE 7     ; Device not available
ISR_ERRCODE   8     ; Double fault
ISR_NOERRCODE 9     ; Coprocessor segment overrun
ISR_ERRCODE   10    ; Invalid TSS
ISR_ERRCODE   11    ; Segment not present
ISR_ERRCODE   12    ; Stack-segment fault
ISR_ERRCODE   13    ; General protection fault
ISR_ERRCODE   14    ; Page fault
ISR_NOERRCODE 15    ; Reserved
ISR_NOERRCODE 16    ; x87 FPU error
ISR_ERRCODE   17    ; Alignment check
ISR_NOERRCODE 18    ; Machine check
ISR_NOERRCODE 19    ; SIMD floating point
ISR_NOERRCODE 20    ; Virtualization
ISR_NOERRCODE 21
ISR_NOERRCODE 22
ISR_NOERRCODE 23
ISR_NOERRCODE 24
ISR_NOERRCODE 25
ISR_NOERRCODE 26
ISR_NOERRCODE 27
ISR_NOERRCODE 28
ISR_NOERRCODE 29
ISR_NOERRCODE 30
ISR_NOERRCODE 31

; ============================================================================
; IRQ Definitions (Hardware Interrupts 0-15)
; ============================================================================
; IRQs are remapped to ISR 32-47

%macro IRQ 2
global irq%1
irq%1:
    cli
    push byte 0         ; Dummy error code
    push byte %2        ; Interrupt number
    jmp irq_common_stub
%endmacro

IRQ 0,  32      ; Timer
IRQ 1,  33      ; Keyboard
IRQ 2,  34      ; Cascade
IRQ 3,  35      ; COM2
IRQ 4,  36      ; COM1
IRQ 5,  37      ; LPT2
IRQ 6,  38      ; Floppy
IRQ 7,  39      ; LPT1 / Spurious
IRQ 8,  40      ; CMOS RTC
IRQ 9,  41      ; Free
IRQ 10, 42      ; Free
IRQ 11, 43      ; Free
IRQ 12, 44      ; PS/2 Mouse
IRQ 13, 45      ; FPU
IRQ 14, 46      ; Primary ATA
IRQ 15, 47      ; Secondary ATA
