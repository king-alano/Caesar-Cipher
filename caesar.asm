;; auth: AJ Boyd (aboyd3)
;; date: 4/24/23
;; desc: program implements a caesar cipher using Intel x86-64 Assembly and the NASM Assembler

        section .data
        ;; holds initilized variables (prompts)
shiftPrompt:    db      "Please enter a number (-25-25)", 10            ;prompt to get the shift value
len1:           equ     $-shiftPrompt
msgPrompt:      db      "Enter a string greater than 8 characters", 10  ;prompt to get the message
len2:           equ     $-msgPrompt
currMsg:        db      "Current message: ", 0                          ;display to show the current message
len5:           equ     $-currMsg
encMsg:         db      "Edited message: ", 0                           ;display to show the encrypted message
len8:           equ     $-encMsg
newline:        db      10

        section .bss
        ;; holds uninitialized variables
shift:          resb    16      ;the shift to be entered (ascii)
msg:            resb    256     ;the plaintext message to be entered
msgLen:         resb    4       ;holds the length of the message
c:              resb    256     ;the individual character of the message (used for the encryption process)
shiftNum:       resb    2       ;the shift (integer)

        section .text
        global main

main:

_promptShift:                   ;prompts user for shift value and reads in input

        ;; prompt for shift value
        mov     rax, 1
        mov     rdi, 1
        mov     rsi, shiftPrompt
        mov     rdx, len1
        syscall

        ;; read in data
        mov     rax, 0
        mov     rdi, 0
        mov     rsi, shift
        mov     rdx, 15
        syscall

        ;; checks if number is negative
        mov     r10, 10
        mov     rsi, shift
        cmp     byte[rsi], 45
        je      _parseNegative  ;if so, go to special negative parse case
        jmp     _parse          ;else, parse regularaly


_parse:                         ;parses positive numbers from ascii to integer

        xor     rax, rax        ;clear rax, rdx, r8, and r9 for potential multiplication
        xor     rdx, rdx
        xor     r8, r8
        xor     r9, r9

        mov     r8b, byte[rsi]  ;put the first digit into r8 and convert from ascii to integer
        sub     r8, 48
        add     rax, r8

        inc     rsi             ;check if there is a second digit
        cmp     byte[rsi], 10
        je      _cmpShift       ;if not, then we've parsed everything, and we can do error checking

        mov     r9b, byte[rsi]  ;if so, put the next byte into r9 and convert from ascii to integer
        sub     r9, 48

        mul     r10
        add     rax, r9
        inc     rsi             ;if there are extra digits, re-prompt for shift
        cmp     byte[rsi], 10
        jne     _promptShift
        jmp     _cmpShift       ;else, error check the shift

_parseNegative:
        ;;parses negative numbers from ascii to integer

        inc     rsi             ;move to next byte of rsi which holds shift

        xor     rax, rax        ;clear rax, rdx, r8 and r9 for potential multiplication
        xor     rdx, rdx
        xor     r8, r8
        xor     r9, r9

        mov     r8b, byte[rsi]  ;move first digit into r8 and convert from ascii to integer
        sub     r8, 48
        sub     rax, r8

        inc     rsi             ;check if there is a second digit
        cmp     byte[rsi], 10
        je      _cmpShift       ;if not, then we've parsed everything, and we can do error checking

        mov     r9b, byte[rsi]  ;if so, put that digit into r9
        sub     r9, 48          ;convert form ascii to integer

        mul     r10             ;multiply first digit by ten
        sub     rax, r9         ;subtract second digit

        inc     rsi             ;if there are extra digits, re-prompt for shift
        cmp     byte[rsi], 10
        jne     _promptShift
        jmp     _cmpShift       ;else, error check the shift

_cmpShift:
        ;; right now, shift value is stored in rax, move to shiftNum buffer
        mov     byte[shiftNum], al

        cmp     byte[shiftNum], -25 ;if shiftNum < -25, re-prompt for shift
        jl      _promptShift
        cmp     byte[shiftNum], 25 ;or if shiftNum > 25, re-prompt for shift
        jg      _promptShift

        jmp     _promptMsg       ;if valid, prompt for message

_promptMsg:
        ;; once we get here, the shift number should be stored in shiftNum
        ;; prompt for plaintext message
        mov     rax, 1
        mov     rdi, 1
        mov     rsi, msgPrompt
        mov     rdx, len2
        syscall

        mov     rax, 0
        mov     rdi, 0
        mov     rsi, msg        ;store the message into msg buffer
        mov     rdx, 256
        syscall

        ;; get the length of the message
        mov     rdi, msg        ;put the memory address to the message into rdi
        call    _getMsgLen      ;get the length of the message
        mov     [msgLen], eax   ;move that length into the msgLen buffer

_cmpMsg:
        ;; validate message
        cmp     rax, 8          ;if message is less than 8 characters long, re-prompt
        jl      _promptMsg

_printMsg:
        ;; print the message if it's valid
        mov     rax, 1
        mov     rdi, 1
        mov     rsi, currMsg
        mov     rdx, len5
        syscall

        mov     rax, 1
        mov     rdi, 1
        mov     rsi, msg
        mov     rdx, 256
        syscall

        ;; jump to label that handles shift
        jmp     _encrypt

_getMsgLen:
        xor     rax, rax        ;clear register for counting

.msgLenLoop:
        cmp     byte[rdi], 10   ;if at the end of the message, stop looping
        je      .endMsgLenLoop
        inc     rax             ;increment rax and rdi
        inc     rdi
        jmp     .msgLenLoop

.endMsgLenLoop:
        ret

_encrypt:
        ;; prints "Encrypted message: "
        mov     rax, 1
        mov     rdi, 1
        mov     rsi, encMsg
        mov     rdx, len8
        syscall

        xor     r14, r14        ;clear register for msg
        xor     r15, r15        ;clear register for c

        ;;move buffer into register
        mov     r14, msg

_encryptLoop:
        mov     r15b, byte[r14]
        cmp     r15b, 10        ;see if at end of message; if so, exit
        je      exit

        mov     byte[c], r15b   ;move current character into the c buffer

                                ;; we know the ascii value is not 10
        cmp     r15b, 65        ;if a non-alphabet character, just print it
        jl      _printC
        cmp     r15b, 122
        jg      _printC

                                ;; we know the ascii value is 65-122 (inclusive)
        cmp     r15b, 90
        jle     _uppercase      ;if less than or equal to 90, we're looking at an uppercase letter
        cmp     r15b, 97
        jge     _lowercase      ;else if greater than or equal to 97, we're looking at a lowercase letter
        jmp     _printC         ;else, it's a non-alphabet character and we should just print it


_lowercase:
        add     r15b, [shiftNum] ;applies shift to current letter

        cmp     r15b, 122        ;if this shift is outside of the bounds, wrap around
        jg      _lowerOverflow
        cmp     r15b, 97
        jl      _lowerUnderflow

        mov     byte[c], r15b    ;if shift is in bounds, move it to the c buffer and print it
        jmp     _printC

_lowerOverflow:
        ;; case for an overflow for lowercase letters
        sub     r15b, 122       ;adjust the ascii value then print
        add     r15b, 96

        mov     byte[c], r15b
        jmp     _printC

_lowerUnderflow:
        ;; case for an underflow for lowercase letters
        sub     r15b, 97        ;adjust the ascii value then print
        add     r15b, 123

        mov     byte[c], r15b
        jmp     _printC

_uppercase:
        add     r15b, [shiftNum] ;applies shift to current letter

        cmp     r15b, 90         ;if this shift is outside of the bounds, wrap around
        jg      _upperOverflow
        cmp     r15b, 65
        jl      _upperUnderflow

        mov     byte[c], r15b    ;if shift is in bounds, move it to the c buffer and print it
        jmp     _printC

_upperOverflow:
        ;; case for an overflow for uppercase letters
        sub     r15b, 90        ;adjust the ascii value then print
        add     r15b, 64

        mov     byte[c], r15b
        jmp     _printC

_upperUnderflow:
        ;; case for an underflow for uppercase letters
        sub     r15b, 65       ;adjust the ascii value then print
        add     r15b, 91

        mov     byte[c], r15b
        jmp     _printC

_iterate:
        ;; moves the character along the string
        inc     r14
        jmp     _encryptLoop

_printC:
        ;; prints the current character in the c buffer and iterates the loop
        mov     rax, 1
        mov     rdi, 1
        mov     rsi, c
        mov     rdx, 256
        syscall

        jmp     _iterate

exit:
        ;; prints a newline then exits program
        mov rax, 1
        mov rdi, 1
        mov rsi, newline
        mov rdx, 1
        syscall

        mov rax, 60
        xor rdi, rdi
        syscall
