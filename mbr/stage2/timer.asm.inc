%ifndef TIMER_ASM_INC
%define TIMER_ASM_INC

common timer_cnt 4

%ifndef TIMER_ASM_INC_NO_EXTERN
extern timer_init ; void timer_init()
extern timer_delay ; void timer_delay(uint32_t msec)
%endif

%endif
