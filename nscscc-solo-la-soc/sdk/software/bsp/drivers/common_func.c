#include "common_func.h"

void RegWrite(unsigned int addr,unsigned int var)
{
	*((volatile unsigned int *)(addr)) = var;
}

unsigned int RegRead(unsigned int addr)
{
	return (*((volatile unsigned int *)(addr)));
}

//memcpy 32bit
void SaveMemory(unsigned int  *DestAddr, unsigned int  *SrcAddr, unsigned int Size)
{
	unsigned int i;
	for (i = 0; i < Size; i += 1)
		*(U32*)(DestAddr + i) = SrcAddr[i];
}

