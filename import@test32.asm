; --------------------------------------------------------------------------------
; MIT License
;
; Copyright (c) 2020 Jens Kallup
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
; --------------------------------------------------------------------------------

BITS 32

%define ET_EXEC       2
%define EM_386        3    ; intel 386 32-bit: arch
%define EV_CURRENT    1

%define PT_LOAD       1
%define PT_DYNAMIC    2
%define PT_INTERP     3

%define PF_X          1
%define PF_W          2
%define PF_R          4

%define STT_FUNC      2

%define STB_GLOBAL    1

%define R_386_PC32    2

%define DT_NULL       0
%define DT_NEEDED     1
%define DT_HASH       4
%define DT_STRTAB     5
%define DT_SYMTAB     6
%define DT_STRSZ      10
%define DT_SYMENT     11
%define DT_REL        17
%define DT_RELSZ      18
%define DT_RELENT     19
  
%define ST_INFO(b, t) (((b) << 4) | (t))
%define R_INFO(s, t)  (((s) << 8) | (t))

shentsz       equ     0x28

    org     0x08048000
 
;; The ELF header

ehdr:                                                 ; Elf32_Ehdr
                db      0x7F, "ELF", 1, 1, 1            ;   e_ident
        times 9 db      0
                dw      ET_EXEC                         ;   e_type
                dw      EM_386                          ;   e_machine
                dd      EV_CURRENT                      ;   e_version
                dd      _start                          ;   e_entry
                dd      phdr - $$                       ;   e_phoff
                dd      0                               ;   e_shoff
                dd      0                               ;   e_flags
                dw      ehdrsz                          ;   e_ehsize
                dw      phentsz                         ;   e_phentsize
                dw      3                               ;   e_phnum
                dw      shentsz                         ;   e_shentsize
                dw      0                               ;   e_shnum
                dw      0                               ;   e_shstrndx
  ehdrsz        equ     $ - ehdr

;; The program segment header table
  
  phdr:                                                 ; Elf32_Phdr
                dd      PT_INTERP                       ;   p_type
                dd      interp - $$                     ;   p_offset
                dd      interp                          ;   p_vaddr
                dd      interp                          ;   p_paddr
                dd      interpsz                        ;   p_filesz
                dd      interpsz                        ;   p_memsz
                dd      PF_R                            ;   p_flags
                dd      0                               ;   p_align
  phentsz       equ     $ - phdr
                dd      PT_LOAD                         ;   p_type
                dd      0                               ;   p_offset
                dd      $$                              ;   p_vaddr
                dd      $$                              ;   p_paddr
                dd      filesz                          ;   p_filesz
                dd      memsz                           ;   p_memsz
                dd      PF_R | PF_W | PF_X              ;   p_flags
                dd      0x1000                          ;   p_align
  
                dd      PT_DYNAMIC                      ;   p_type
                dd      dyntab - $$                     ;   p_offset
                dd      dyntab                          ;   p_vaddr
                dd      dyntab                          ;   p_paddr
                dd      dyntabsz                        ;   p_filesz
                dd      dyntabsz                        ;   p_memsz
                dd      PF_R | PF_W                     ;   p_flags
                dd      4                               ;   p_align
  
  ;; The hash table
  
  hashtab:
                dd      1                               ; no. of buckets
                dd      3                               ; no. of symbols
                dd      1                               ; the bucket: symbol #1
                dd      0, 0, 0                         ; two links, both zero
  
  ;; The symbol table
  
  symtab:                                               ; Elf32_Sym
                dd      0                               ;   st_name
                dd      0                               ;   st_value
                dd      0                               ;   st_size
                db      0                               ;   st_info
                db      0                               ;   st_other
                dw      0                               ;   st_shndx
  symentsz      equ     $ - symtab  
  ;----------------------------------------------------------------------
                dd      test32_start_name               ;   st_name
		dd      0                               ;   st_value
                dd      0                               ;   st_size
                db      ST_INFO(STB_GLOBAL, STT_FUNC)   ;   st_info
                db      0                               ;   st_other
                dw      0                               ;   st_shndx
  symentsz_1    equ	$ - symtab
  ;----------------------------------------------------------------------
                dd      test32_B_start_name
                dd      0
                dd      0
                db      ST_INFO(STB_GLOBAL, STT_FUNC)
                db      0
                dw      0
  symentsz_2    equ     $ - symtab
  

  ;; The relocation table
  
  reltab:                                               ; Elf32_Rel
                dd      test32_call_test                ;   r_offset
                dd      R_INFO(1, R_386_PC32)           ;   r_info
  relentsz_1    equ     $ - reltab
  ;--------------------------------------------------------------------
  relentsz_2    dd      test32_B_call_test
                dd      R_INFO(1, R_386_PC32)
  reltabsz      equ     $ - reltab
  

  ;; The dynamic section
  
  dyntab:
                dd      DT_STRTAB, strtab
                dd      DT_STRSZ,  strtabsz
                dd      DT_SYMTAB, symtab
                dd      DT_SYMENT, symentsz
                dd      DT_REL,    reltab
                dd      DT_RELSZ,  reltabsz
                dd      DT_RELENT, relentsz_1
                dd      DT_HASH,   hashtab
                dd      DT_NEEDED, test32_lib_name
                dd      DT_NULL,   0
  dyntabsz      equ     $ - dyntab
  
  ;; The interpreter segment
  
  interp:
                db      '/lib/ld-linux.so.2', 0
  interpsz      equ     $ - interp
  
  ;; The string table

strtab:
                db      0

test32_lib_name         equ     $ - strtab
                        db      './libwrap32ae.so', 0

test32_start_name       equ     $ - strtab
                        db      '__Z11test32startv', 0

test32_B_start_name     equ     $ - strtab
                        db      'test32_B', 0


strtabsz      equ     $ - strtab

;; Our program

_start:
	call	_start_2
	ret
; ---------------------------------------------------------
_start_1:
        call	test32_call_test
	test32_call_test	equ     $ - 4
	ret
; ---------------------------------------------------------
_start_2:
	call	test32_B_call_test
	test32_B_call_test	equ	$ - 4
	ret


;; End of the file image.

filesz        equ     $ - $$
memsz         equ     filesz
