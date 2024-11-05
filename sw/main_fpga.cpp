#include "platform.h"
#include "rans_byte_fpga.h"
#include "utils.h"
#include <time.h>

#define RANDOM
//#define TXT

#ifdef RANDOM
const char path1[256] = "../src/random.bin";
const char path2[256] = "../src/random_encode.o";
const char path3[256] = "../src/random_decode.bin";
#else 
#ifdef TXT
const char pathtxt[256] = "../src/layer4_data_out_sim_dequant_inv.txt";
const char path1[256] = "../src/layer4_data_out_sim_dequant_inv.bin";
const char path2[256] = "../src/layer4_data_out_sim_dequant_inv_encode.o";
const char path3[256] = "../src/layer4_data_out_sim_dequant_inv_decode.bin";
#else 
const char path1[256] = "../src/layer4_data_out.bin";
const char path2[256] = "../src/layer4_data_out_encode.o";
const char path3[256] = "../src/layer4_data_out_decode.bin";
#endif // TXT
#endif // RANDOM



const int header_size = 2 * sizeof(int);   // 32bit:original file size  32bit:prob_bits
const int freq_size = 256 * sizeof(int);
const int cum_size = 257 * sizeof(int);

void gen_random_data(char const* filename, const int size) {
	srand(time(NULL));
	FILE* f = fopen(filename, "wb");
	if (!f) {
		panic("file not found: %s\n", filename);
		exit(1);
	}

	uint8_t* buf = new uint8_t[size];
	for (int i = 0; i < size; i++){
		int randomNum = rand();
		buf[i] = (uint8_t)(randomNum && 0xff);
	}
	fwrite(buf, 1, size, f);
	fclose(f);
}

void read_txt(char const* path_txt, char const* path_bin) {
	FILE* f_bin = fopen(path_bin, "wb");
	if (!f_bin) {
		panic("file not found: %s\n", path_bin);
		exit(1);
	}

	FILE* f_txt = fopen(path_txt, "r");
	if (!f_txt) {
		panic("file not found: %s\n", path_txt);
		exit(1);
	}

	char line[10];
	size_t size = 0;
	while (fgets(line, sizeof(line), f_txt)) {
		int num = atoi(line); 
		fwrite(&num, sizeof(char), 1, f_bin);
		size++;
	}

	fclose(f_txt);
	fclose(f_bin);
	printf("in_size:%d\n", size);
}


void Encode()
{
	printf("/*---------- encode ----------*/\n");
	const uint32_t prob_bits = 8;
	const uint32_t prob_scale = 1 << prob_bits;

#ifdef RANDOM
	gen_random_data(path1, 1044480);
#endif // RANDOM

#ifdef TXT
	read_txt(pathtxt, path1);
	//exit(0);
#endif // TXT

	
	// load input bin file
	size_t in_size;
	uint8_t* in_buf = read_file(path1, &in_size);

	if (!in_buf)
		exit(1);

	uint32_t out_max_size = in_size;
	uint8_t* out_buf = new uint8_t[header_size + freq_size + cum_size + out_max_size];

	SymbolStats en_stats;
	en_stats.count_freqs(in_buf, in_size);
	en_stats.normalize_freqs(prob_scale);

	RansEncSymbol esyms[256];
	for (int i = 0; i < 256; i++) {
		RansEncSymbolInit(&esyms[i], en_stats.cum_freqs[i], en_stats.freqs[i], prob_bits);
	}

	// try rANS encode
	//=========================================== encode start =========================================== 
	uint8_t *rans_end;
	uint8_t* ptr = out_buf + header_size + freq_size + cum_size;

	RansState en_rans0, en_rans1, en_rans2, en_rans3, en_rans4, en_rans5, en_rans6, en_rans7;
	RansEncInit(&en_rans0);
	RansEncInit(&en_rans1);
	RansEncInit(&en_rans2);
	RansEncInit(&en_rans3);
	RansEncInit(&en_rans4);
	RansEncInit(&en_rans5);
	RansEncInit(&en_rans6);
	RansEncInit(&en_rans7);

	clock_t startTime = clock();
	for (size_t i = (in_size & ~7); i > 0; i -= 8) // NB: working in reverse!
	{
		int s7 = in_buf[i - 1];
		int s6 = in_buf[i - 2];
		int s5 = in_buf[i - 3];
		int s4 = in_buf[i - 4];
		int s3 = in_buf[i - 5];
		int s2 = in_buf[i - 6];
		int s1 = in_buf[i - 7];
		int s0 = in_buf[i - 8];

		RansEncPutSymbol(&en_rans7, &ptr, &esyms[s7], 7);
		RansEncPutSymbol(&en_rans6, &ptr, &esyms[s6], 6);
		RansEncPutSymbol(&en_rans5, &ptr, &esyms[s5], 5);
		RansEncPutSymbol(&en_rans4, &ptr, &esyms[s4], 4);
		RansEncPutSymbol(&en_rans3, &ptr, &esyms[s3], 3);
		RansEncPutSymbol(&en_rans2, &ptr, &esyms[s2], 2);
		RansEncPutSymbol(&en_rans1, &ptr, &esyms[s1], 1);
		RansEncPutSymbol(&en_rans0, &ptr, &esyms[s0], 0);
	}
	printf("After 8-way interleaved rANS: %d bytes\n", (int)cnt_bytes_enc);

	RansEncFlush(&en_rans7, &ptr);
	RansEncFlush(&en_rans6, &ptr);
	RansEncFlush(&en_rans5, &ptr);
	RansEncFlush(&en_rans4, &ptr);
	RansEncFlush(&en_rans3, &ptr);
	RansEncFlush(&en_rans2, &ptr);
	RansEncFlush(&en_rans1, &ptr);
	RansEncFlush(&en_rans0, &ptr);

	printf("rans max:%d\n", rans_max);

	clock_t endTime = clock();

	rans_end = ptr;

	uint32_t out_size_8way = rans_end - out_buf - (header_size + freq_size + cum_size);
	printf("Original length:%ld\n", in_size);
	printf("After 8-way interleaved rANS: %d bytes\n", (int)out_size_8way);
	printf("encode ratio:%f\n", (float)((float)out_size_8way / (float)in_size));
	printf("Encode time:%.5f ms\n", (double)(endTime - startTime) * 1000 / CLOCKS_PER_SEC);

	// wrire frequency table and cum2sym into out_buf
	uint32_t *ptr_size = (uint32_t *)out_buf;
	uint32_t *ptr_probs = ptr_size + 1;
	uint32_t *ptr_freq = (uint32_t *)(out_buf + header_size);
	uint32_t *ptr_cum = ptr_freq + freq_size / sizeof(int);
	*ptr_size = in_size;
	*ptr_probs = prob_bits;

	fprintf(f_txt, "%d\n", *ptr_size);
	fprintf(f_txt, "%d\n", out_size_8way);

	for (int i = 0; i < 256; i++) {
		ptr_freq[i] = en_stats.freqs[i];
		fprintf(f_txt, "%d\n", ptr_freq[i]);
	}
	for (int i = 0; i < 257; i++) {
		ptr_cum[i] = en_stats.cum_freqs[i];
		if(i > 0) fprintf(f_txt, "%d\n", ptr_cum[i]);
	}
	printf("\n");
	
	FILE* outfp = stdout;
	if (!(outfp = fopen(path2, "wb"))) {
		perror(path2);
		exit(1);
	}
	uint32_t totalsize = rans_end - out_buf;
	fwrite(out_buf, 1, totalsize, outfp);  // write data into file

	delete[] in_buf;
	delete[] out_buf;
	fclose(outfp);

	fclose(f_txt);// debug
}

#define COMPARE
void Decode()
{
	printf("/*---------- decode ----------*/\n");
	size_t in_size, out_size;
	uint8_t* in_buf = read_file(path2, &in_size);
	if (!in_buf)
		exit(1);

	// load header
	const uint32_t filesize = *(uint32_t*)in_buf;
	const uint32_t prob_bits = *((uint32_t*)in_buf + 1);
	const uint32_t prob_scale = 1 << prob_bits;
	printf("filesize:%d   prob_bits:%d\n", filesize, prob_bits);

	// load frequency and cum table
	SymbolStats de_stats;
	uint32_t* ptr_freq = (uint32_t*)(in_buf + header_size);
	uint32_t* ptr_cum = (uint32_t*)(in_buf + header_size + freq_size);
	for (int i = 0; i < 256; i++) {
		de_stats.freqs[i] = ptr_freq[i];
	}
	for (int i = 0; i < 257; i++) {
		de_stats.cum_freqs[i] = ptr_cum[i];
	}
	// cum2sym table
	uint8_t *cum2sym_de = new uint8_t[prob_scale];
	for (int s = 0; s < 256; s++) {
		if (s == 0) {
			for (int i = 0; i < de_stats.cum_freqs[s + 1]; i++) {
				cum2sym_de[i] = s;
			}
		}
		else {
			for (int i = de_stats.cum_freqs[s]; i < de_stats.cum_freqs[s + 1]; i++) {
				cum2sym_de[i] = s;
			}
		}
	}

	RansDecSymbol dsyms[256];
	for (int i = 0; i < 256; i++) {
		RansDecSymbolInit(&dsyms[i], de_stats.cum_freqs[i], de_stats.freqs[i]);
	}

	// try rANS decode
	//=========================================== decode start =========================================== 
	uint8_t* de_ptr = in_buf + in_size;
	uint8_t* dec_bytes = new uint8_t[filesize];

	RansState de_rans0, de_rans1, de_rans2, de_rans3, de_rans4, de_rans5, de_rans6, de_rans7;
	RansDecInit(&de_rans0, &de_ptr);	// okay
	RansDecInit(&de_rans1, &de_ptr);
	RansDecInit(&de_rans2, &de_ptr);
	RansDecInit(&de_rans3, &de_ptr);
	RansDecInit(&de_rans4, &de_ptr);
	RansDecInit(&de_rans5, &de_ptr);
	RansDecInit(&de_rans6, &de_ptr);
	RansDecInit(&de_rans7, &de_ptr);

#ifndef USE8SHIFT
	de_ptr -= 2;  // note!!!
#endif // USE8SHIFT
	clock_t startTime = clock();

	int dec_idx = 0;
	uint32_t out_end = filesize;
	for (int i = out_end; i > 0; i -= 8, dec_idx += 8)
	{
		uint32_t s0 = cum2sym_de[RansDecGet(&de_rans0, prob_bits)];
		uint32_t s1 = cum2sym_de[RansDecGet(&de_rans1, prob_bits)];
		uint32_t s2 = cum2sym_de[RansDecGet(&de_rans2, prob_bits)];
		uint32_t s3 = cum2sym_de[RansDecGet(&de_rans3, prob_bits)];
		uint32_t s4 = cum2sym_de[RansDecGet(&de_rans4, prob_bits)];
		uint32_t s5 = cum2sym_de[RansDecGet(&de_rans5, prob_bits)];
		uint32_t s6 = cum2sym_de[RansDecGet(&de_rans6, prob_bits)];
		uint32_t s7 = cum2sym_de[RansDecGet(&de_rans7, prob_bits)];

		dec_bytes[dec_idx + 7] = (uint8_t)s7;
		dec_bytes[dec_idx + 6] = (uint8_t)s6;
		dec_bytes[dec_idx + 5] = (uint8_t)s5;
		dec_bytes[dec_idx + 4] = (uint8_t)s4;
		dec_bytes[dec_idx + 3] = (uint8_t)s3;
		dec_bytes[dec_idx + 2] = (uint8_t)s2;
		dec_bytes[dec_idx + 1] = (uint8_t)s1;
		dec_bytes[dec_idx + 0] = (uint8_t)s0;

		RansDecAdvanceSymbolStep(&de_rans0, &dsyms[s0], prob_bits);
		RansDecAdvanceSymbolStep(&de_rans1, &dsyms[s1], prob_bits);
		RansDecAdvanceSymbolStep(&de_rans2, &dsyms[s2], prob_bits);
		RansDecAdvanceSymbolStep(&de_rans3, &dsyms[s3], prob_bits);
		RansDecAdvanceSymbolStep(&de_rans4, &dsyms[s4], prob_bits);
		RansDecAdvanceSymbolStep(&de_rans5, &dsyms[s5], prob_bits);
		RansDecAdvanceSymbolStep(&de_rans6, &dsyms[s6], prob_bits);
		RansDecAdvanceSymbolStep(&de_rans7, &dsyms[s7], prob_bits);

		RansDecRenorm(&de_rans0, &de_ptr);
		RansDecRenorm(&de_rans1, &de_ptr);
		RansDecRenorm(&de_rans2, &de_ptr);
		RansDecRenorm(&de_rans3, &de_ptr);
		RansDecRenorm(&de_rans4, &de_ptr);
		RansDecRenorm(&de_rans5, &de_ptr);
		RansDecRenorm(&de_rans6, &de_ptr);
		RansDecRenorm(&de_rans7, &de_ptr);
	}
	clock_t endTime = clock();
	printf("Decode time:%.2f ms\n", (double)(endTime - startTime) * 1000 / CLOCKS_PER_SEC);

	// write file
	FILE* outfp = stdout;
	if (!(outfp = fopen(path3, "wb"))) {
		perror(path3);
		exit(1);
	}
	fwrite(dec_bytes, 1, filesize, outfp);

	delete[] in_buf;
	delete[] dec_bytes;
	delete[] cum2sym_de;
	fclose(outfp);

	/*---------- compare ----------*/
#ifdef COMPARE
	printf("/*---------- compare ----------*/\n");
	FILE* file1, *file2;
	char* buffer1 = new char[filesize];
	char* buffer2 = new char[filesize];

	file1 = fopen(path1, "rb");
	if (file1 == NULL) {
		printf("open file error\n");
		exit(1);
	}
	file2 = fopen(path3, "rb");
	if (file2 == NULL) {
		printf("open file error\n");
		exit(1);
	}
	fgets(buffer1, filesize, file1);
	fgets(buffer2, filesize, file2);

	if (memcmp(buffer1, buffer2, filesize) == 0)
		printf("Compare successfully!\n");
	else
		printf("ERROR: bad decoder!\n");

	delete [] buffer1;
	delete [] buffer2;
	fclose(file1);
	fclose(file2);
#endif // COMPARE
}


int main(int argc, char **argv)
{
	Encode();
	Decode();
	return 0;
}
