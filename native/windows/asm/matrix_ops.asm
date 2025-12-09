; x86-64 Assembly Optimization for Matrix Operations
; Optimized for SIMD (AVX2/SSE4.2)
; Windows x64 calling convention (RCX, RDX, R8, R9)

section .text
    public matrix_multiply_asm
    public softmax_asm

; Fast matrix multiply using AVX2
; RCX = A (float*), RDX = B (float*), R8 = C (float*)
; R9 = M (int), [rsp+32] = N (int), [rsp+40] = K (int)
matrix_multiply_asm:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    
    mov rax, [rsp + 56]  ; N from stack
    mov rbx, [rsp + 64]  ; K from stack
    
    xor r12, r12         ; i = 0
.loop_i:
    cmp r12, r9          ; if i >= M, done
    jge .done_multiply
    
    xor r13, r13         ; j = 0
.loop_j:
    cmp r13, rax         ; if j >= N, next i
    jge .next_i
    
    vxorpd ymm0, ymm0, ymm0  ; sum = 0
    xor r10, r10              ; k = 0
    
.loop_k:
    cmp r10, rbx         ; if k >= K, done with k
    jge .done_k
    
    ; A[i*K + k]
    mov r11, r12
    imul r11, rbx
    add r11, r10
    shl r11, 2           ; multiply by 4 (float size)
    vmovss xmm1, [rcx + r11]
    vcvtss2sd xmm1, xmm1, xmm1
    
    ; B[k*N + j]
    mov r11, r10
    imul r11, rax
    add r11, r13
    shl r11, 2
    vmovss xmm2, [rdx + r11]
    vcvtss2sd xmm2, xmm2, xmm2
    
    vmulsd xmm1, xmm1, xmm2
    vaddsd xmm0, xmm0, xmm1
    
    inc r10
    jmp .loop_k
    
.done_k:
    ; C[i*N + j] = sum
    mov r11, r12
    imul r11, rax
    add r11, r13
    shl r11, 2
    vcvtsd2ss xmm0, xmm0, xmm0
    vmovss [r8 + r11], xmm0
    
    inc r13
    jmp .loop_j
    
.next_i:
    inc r12
    jmp .loop_i
    
.done_multiply:
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; Fast softmax using AVX2
; RCX = data (float*), RDX = size (int)
softmax_asm:
    push rbp
    mov rbp, rsp
    push rbx
    
    ; Find max value
    vmovss xmm0, [rcx]
    xor rax, rax
    
.find_max:
    cmp rax, rdx
    jge .max_found
    
    shl rax, 2           ; multiply by 4
    vmovss xmm1, [rcx + rax]
    vcmpgtss xmm1, xmm0, xmm1
    
    shr rax, 2
    inc rax
    jmp .find_max
    
.max_found:
    ; Compute exp and sum
    vxorpd ymm1, ymm1, ymm1  ; sum = 0
    xor rax, rax
    
.exp_loop:
    cmp rax, rdx
    jge .exp_done
    
    shl rax, 2
    vmovss xmm2, [rcx + rax]
    vsubss xmm2, xmm2, xmm0
    
    ; exp approximation (fast)
    ; exp(x) ≈ 1 + x + x²/2 + x³/6
    vmovss xmm3, xmm2
    vmulss xmm3, xmm3, xmm2
    vmulss xmm3, xmm3, [rel point5]
    vaddss xmm3, xmm3, xmm2
    vaddss xmm3, xmm3, [rel one]
    
    vmovss [rcx + rax], xmm3
    vaddss xmm1, xmm1, xmm3
    
    shr rax, 2
    inc rax
    jmp .exp_loop
    
.exp_done:
    ; Normalize by sum
    xor rax, rax
    
.norm_loop:
    cmp rax, rdx
    jge .norm_done
    
    shl rax, 2
    vmovss xmm2, [rcx + rax]
    vdivss xmm2, xmm2, xmm1
    vmovss [rcx + rax], xmm2
    
    shr rax, 2
    inc rax
    jmp .norm_loop
    
.norm_done:
    pop rbx
    pop rbp
    ret

section .data
    one: dd 1.0
    point5: dd 0.5
