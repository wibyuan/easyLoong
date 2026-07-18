    .global _start
    .section text
_start:
.text  
	lu12i.w	$r12,-2143289344>>12			# 0xffffffff80400000
	or	$r14,$r0,$r0
	lu12i.w	$r15,-2140143616>>12			# 0xffffffff80700000
	.align	4,54525952,4
.L3:
	ld.w	$r13,$r12,0
	addi.w	$r12,$r12,4
	bgeu	$r14,$r13,.L2
	or	$r14,$r13,$r0
.L2:
	bne	$r12,$r15,.L3
	st.w	$r14,$r12,0
	or	$r4,$r0,$r0
	jr	$r1