%ifndef PRINT_ASM_INC
%define PRINT_ASM_INC

color_black equ 0
color_white equ 15
color_gray equ 7
color_red equ 4
color_norm equ (color_black << 4) | color_white
color_err equ (color_red << 4) | color_white

common number_string 32

%ifndef STRING_ASM_INC_NO_EXTERN
extern print_col
extern print_line

extern print_str ; void print_str(char *str, uint8_t color)
extern itoa ; uint32_t itoa(char *str, uint32_t i)
extern clear_screen ; void clear_screen()
%endif

%endif
