; ============================================================================
; CursorOS Bootloader - Multiboot compliant entry point
; ============================================================================
; This is the first code that runs when GRUB hands off control to our kernel.
; It sets up the stack, enters protected mode properly, and jumps to C code.
; ============================================================================

; Multiboot constants
MBALIGN     equ 1 << 0              ; Align loaded modules on page boundaries
MEMINFO     equ 1 << 1              ; Provide memory map
FLAGS       equ MBALIGN | MEMINFO   ; Multiboot flag field
MAGIC       equ 0x1BADB002          ; Magic number for bootloader to find header
CHECKSUM    equ -(MAGIC + FLAGS)    ; Checksum to prove we are multiboot

; ============================================================================
; Multiboot Header
; ============================================================================
section .multiboot
align 4
    dd MAGIC
    dd FLAGS
    dd CHECKSUM

; ============================================================================
; Stack - 16 KB kernel stack
; ============================================================================
section .bss
align 16
stack_bottom:
    resb 16384              ; 16 KB stack
stack_top:

; ============================================================================
; Entry Point
; ============================================================================
section .text
global _start
extern kernel_main

_start:
    ; Set up the stack pointer
    mov esp, stack_top

    ; Push multiboot info for the kernel
    push ebx                ; Multiboot info structure pointer
    push eax                ; Multiboot magic number

    ; Call the C kernel main function
    call kernel_main

    ; If kernel_main ever returns, halt the CPU
    cli                     ; Disable interrupts
.hang:
    hlt                     ; Halt the processor
    jmp .hang               ; Loop forever (in case of NMI)
