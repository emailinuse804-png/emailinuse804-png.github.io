; ============================================================================
; Global Descriptor Table (GDT) Setup
; ============================================================================
; The GDT defines memory segments for protected mode operation.
; We set up a flat memory model with code and data segments spanning all 4GB.
; ============================================================================

global gdt_flush
global idt_flush

; ============================================================================
; GDT Flush - Load the new GDT and update segment registers
; ============================================================================
gdt_flush:
    mov eax, [esp + 4]     ; Get pointer to GDT descriptor
    lgdt [eax]             ; Load the GDT

    mov ax, 0x10           ; 0x10 = offset to data segment in GDT
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    jmp 0x08:.flush        ; Far jump to code segment (0x08)
.flush:
    ret

; ============================================================================
; IDT Flush - Load the Interrupt Descriptor Table
; ============================================================================
idt_flush:
    mov eax, [esp + 4]     ; Get pointer to IDT descriptor
    lidt [eax]             ; Load the IDT
    ret
