# Caesar-Cipher
This program was built in 64-bit Intel Assembly using the NASM assembler. It's functionality includes encrypting a message using a Caesar cipher.
To run this file in a terminal using the gcc compiler, run these instructions:

nasm -f elf64 -l caesar.lst caesar.asm
<br>
gcc -m64 -o caesar  caesar.o
./caesar
