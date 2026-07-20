#ifndef DVI_H
#define DVI_H
#include "common_func.h"

#define DVI_BASEADDR 0xbf100000

#define DVI_RECT_DIR (DVI_BASEADDR + 0x0)

#define DVI_RECT_L_W (DVI_BASEADDR + 0x4)

#define DVI_SQU_DIR (DVI_BASEADDR + 0x8)

#define DVI_SQU_R (DVI_BASEADDR + 0xC)

// draw rect on DVI to x y 
void DVI_Draw_Rect(uint32_t x, uint32_t y, uint32_t l, uint32_t w);

// draw squ on DVI to x y r
void DVI_Draw_SQU(uint32_t x, uint32_t y, uint32_t r);

#endif // DVI
