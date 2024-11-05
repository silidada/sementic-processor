#ifndef UTILS_H
#define UTILS_H

#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <assert.h>
#include "hyper.h"

static void panic(const char *fmt, ...) {
	va_list arg;

	va_start(arg, fmt);
	fputs("Error: ", stderr);
	vfprintf(stderr, fmt, arg);
	va_end(arg);
	fputs("\n", stderr);

	exit(1);
}

static uint8_t* read_file(char const* filename, size_t* out_size) {
	FILE* f = fopen(filename, "rb");
	if (!f)
		panic("file not found: %s\n", filename);

	fseek(f, 0, SEEK_END);
	size_t size = ftell(f);
	fseek(f, 0, SEEK_SET);

	uint8_t* buf = new uint8_t[size];
	if (fread(buf, size, 1, f) != 1)
		panic("read failed\n");

	fclose(f);
	if (out_size)
		*out_size = size;

	return buf;
}

struct SymbolStats
{
	uint32_t freqs[256];
	uint32_t cum_freqs[257];

	void count_freqs(uint8_t const* in, size_t nbytes);
	void calc_cum_freqs();
	void normalize_freqs(uint32_t target_total);
};

void SymbolStats::count_freqs(uint8_t const* in, size_t nbytes)
{
	for (int i = 0; i < 256; i++)
		freqs[i] = 0;

	for (size_t i = 0; i < nbytes; i++)
		freqs[in[i]]++;
}

void SymbolStats::calc_cum_freqs()
{
	cum_freqs[0] = 0;
	for (int i = 0; i < 256; i++) {
		cum_freqs[i + 1] = cum_freqs[i] + freqs[i];
	}
}

void SymbolStats::normalize_freqs(uint32_t target_total)
{
	assert(target_total >= 256);

	calc_cum_freqs();
	uint32_t cur_total = cum_freqs[256];
	// resample distribution based on cumulative freqs
	for (int i = 1; i <= 256; i++){
#ifdef FPGA
		/*
		*	target_total = 1 << 8 = 256;
		*	cur_total = 1044480
		*	target_total * x / cur_total = x / 4080 ¡Ö (x >> 12) + 1;
		*/
		cum_freqs[i] = (cum_freqs[i] >> 12) + 1;
#else
		cum_freqs[i] = ((uint64_t)target_total * cum_freqs[i]) / cur_total;
#endif // FPGA
	}
	// if we nuked any non-0 frequency symbol to 0, we need to steal
	// the range to make the frequency nonzero from elsewhere.
	//
	// this is not at all optimal, i'm just doing the first thing that comes to mind.
	for (int i = 0; i < 256; i++) {		// cmp_loop1
		if (freqs[i] && cum_freqs[i + 1] == cum_freqs[i]) {  // i=0 is impossible
			// symbol i was set to zero freq

			// find best symbol to steal frequency from (try to steal from low-freq ones)
			uint32_t best_freq = ~0u;
			int best_steal = -1;
			for (int j = 0; j < 256; j++) {		// cmp_loop2
				uint32_t freq = cum_freqs[j + 1] - cum_freqs[j];
				if (freq > 1 && freq < best_freq) {
					best_freq = freq;
					best_steal = j;
				}
			}
			assert(best_steal != -1);

			// loop3
			// and steal from it!
			int addr_begin, addr_end;
			if (best_steal < i) {
				addr_begin = best_steal + 1;
				addr_end = i;
			}
			else {
				addr_begin = i + 1;
				addr_end = best_steal;
			}
			if (best_steal < i) {
				for (int j = addr_begin; j <= addr_end; j++){
					cum_freqs[j]--;
				}
			}
			else {
				assert(best_steal > i);
				for (int j = addr_begin; j <= addr_end; j++){
					cum_freqs[j]++;
				}
			}
		}
	}
	// calculate updated freqs and make sure we didn't screw anything up
	assert(cum_freqs[0] == 0 && cum_freqs[256] == target_total);
	for (int i = 0; i < 256; i++) {
		if (freqs[i] == 0)
			assert(cum_freqs[i + 1] == cum_freqs[i]);
		else
			assert(cum_freqs[i + 1] > cum_freqs[i]);

		// calc updated freq
		freqs[i] = cum_freqs[i + 1] - cum_freqs[i];
	}
}

#endif // !UTILS_H
