#ifndef common_func_H
#define common_func_H

#include <larchintrin.h>

typedef signed int S32;
typedef unsigned int U32;
typedef unsigned int uint32_t;
typedef signed short S16;
typedef unsigned short U16;
typedef signed char S8;
typedef unsigned char U8;
typedef long long S64;
typedef unsigned long long U64;

void RegWrite(unsigned int addr,unsigned int var);
unsigned int RegRead(unsigned int addr);
void SaveMemory(unsigned int  *DestAddr, unsigned int  *SrcAddr, unsigned int Size);

static inline U32 csr_readl(U32 reg)
{
	return __csrrd_w(reg);
}

static inline U64 csr_readq(U32 reg)
{
	return __csrrd_w(reg);
}

static inline void csr_writel(U32 val, U32 reg)
{
	__csrwr_w(val, reg);
}

static inline void csr_writeq(U64 val, U32 reg)
{
	__csrwr_w(val, reg);
}

static inline U32 csr_xchgl(U32 val, U32 mask, U32 reg)
{
	return __csrxchg_w(val, mask, reg);
}

static inline U64 csr_xchgq(U64 val, U64 mask, U32 reg)
{
	return __csrxchg_w(val, mask, reg);
}

#define CacheOp_Cache			0x03
#define CacheOp_Op			0x1c

#define Cache_I				0x00
#define Cache_D				0x01
#define Cache_V				0x02
#define Cache_S				0x03

#define Index_Invalidate		0x08
#define Index_Writeback_Inv		0x08
#define Hit_Invalidate			0x10
#define Hit_Writeback_Inv		0x10

#define Index_Invalidate_I		(Cache_I | Index_Invalidate)
#define Index_Writeback_Inv_D		(Cache_D | Index_Writeback_Inv)
#define Hit_Invalidate_I		(Cache_I | Hit_Invalidate)
#define Hit_Writeback_Inv_D		(Cache_D | Hit_Writeback_Inv)

#define cache_op(op, addr)						\
	__asm__ __volatile__(						\
	"	cacop	%0, %1					\n"	\
	:								\
	: "i" (op), "R" (*(unsigned char *)(addr)))

static inline void flush_icache_line_indexed(unsigned long addr)
{
	cache_op(Index_Invalidate_I, addr);
}

static inline void flush_dcache_line_indexed(unsigned long addr)
{
	cache_op(Index_Writeback_Inv_D, addr);
}

static inline void flush_icache_line(unsigned long addr)
{
	cache_op(Hit_Invalidate_I, addr);
}

static inline void flush_dcache_line(unsigned long addr)
{
	cache_op(Hit_Writeback_Inv_D, addr);
}

static inline void init_dcache_line(unsigned long addr)
{
	cache_op(0x01, addr);
}

#endif
