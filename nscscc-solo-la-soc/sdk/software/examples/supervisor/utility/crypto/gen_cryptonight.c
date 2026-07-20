#include <stdint.h>
#include <stdio.h>

#define PAD_WORDS 0x80000u
#define OUTPUT_CHUNK_WORDS 4096u

static uint32_t pad[PAD_WORDS];

static void crn(uint32_t pad[], uint32_t a, uint32_t b, uint32_t n) {
  uint32_t k;
  for (k = 0; k != PAD_WORDS; k++)
    pad[k] = k;
  for (k = 0; k != n; k++) {
    uint32_t t, addr1, addr2;
    addr1 = a & 0x7FFFF;
    t = (a >> 1) ^ (pad[addr1] << 1); // Replace the AES step
    pad[addr1] = t ^ b;
    addr2 = t & 0x7FFFF;
    b = t;
    t = pad[addr2];
    a += b * t;
    pad[addr2] = a;
    a ^= t;
    // printf("%#x %#x\n", a, b);
  }
}

static int write_little_endian(FILE *fp, const uint32_t words[], size_t count) {
  unsigned char output[OUTPUT_CHUNK_WORDS * 4];

  while (count != 0) {
    size_t i;
    size_t chunk = count < OUTPUT_CHUNK_WORDS ? count : OUTPUT_CHUNK_WORDS;

    for (i = 0; i < chunk; i++) {
      uint32_t word = words[i];
      output[i * 4 + 0] = (unsigned char)(word >> 0);
      output[i * 4 + 1] = (unsigned char)(word >> 8);
      output[i * 4 + 2] = (unsigned char)(word >> 16);
      output[i * 4 + 3] = (unsigned char)(word >> 24);
    }
    if (fwrite(output, 4, chunk, fp) != chunk)
      return -1;
    words += chunk;
    count -= chunk;
  }
  return 0;
}

int main(int argc, char **argv) {
  const char *output_path;
  FILE *fp;

  if (argc > 2) {
    fprintf(stderr, "Usage: %s [output.bin]\n", argv[0]);
    return 1;
  }
  output_path = argc == 2 ? argv[1] : "crypto.bin";
  fp = fopen(output_path, "wb");
  if (fp == NULL) {
    perror(output_path);
    return 1;
  }

  crn(pad, 0xdeadbeef, 0xfaceb00c, 0x100000);
  if (write_little_endian(fp, pad, PAD_WORDS) != 0) {
    perror("write crypto.bin");
    fclose(fp);
    return 1;
  }
  if (fclose(fp) != 0) {
    perror("close crypto.bin");
    return 1;
  }
  return 0;
}
