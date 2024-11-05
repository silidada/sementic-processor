#ifndef RANS_BYTE_FPGA_H
#define RANS_BYTE_FPGA_H

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <inttypes.h>
#include <math.h>
#include "hyper.h"

#ifdef assert
#define RansAssert assert
#else
#define RansAssert(x)
#endif

#define USE8SHIFT

static int rans_max = 0;

// L ('l' in the paper) is the lower bound of our normalization interval.
// Between this and our byte-aligned emission, we use 31 (not 32!) bits.
// This is done intentionally because exact reciprocals for 31-bit uints
// fit in 32-bit uints: this permits some optimizations during encoding.
#ifndef USE8SHIFT
#define RANS_BYTE_L (1u << 8)  // lower bound of our normalization interval
#else
#define RANS_BYTE_L (1u << 8)  // lower bound of our normalization interval
#endif // !USE8SHIFT

// State for a rANS encoder. Yep, that's all there is to it.
typedef uint32_t RansState;

// Initialize a rANS encoder.
static inline void RansEncInit(RansState* r)
{
	*r = RANS_BYTE_L;
}

// Flushes the rANS encoder.
static inline void RansEncFlush(RansState* r, uint8_t** pptr)
{
	uint32_t x = *r;
	uint8_t* ptr = *pptr;

	ptr[0] = (uint8_t)(x >> 0);
	ptr[1] = (uint8_t)(x >> 8);
	ptr[2] = (uint8_t)(x >> 16);
	ptr[3] = (uint8_t)(x >> 24);
	ptr += 4;

	*pptr = ptr;
}

// Initializes a rANS decoder.
// Unlike the encoder, the decoder works forwards as you'd expect.
static inline void RansDecInit(RansState* r, uint8_t** pptr)
{
	uint32_t x;
	uint8_t* ptr = *pptr;

	ptr -= 4;
	x = ptr[0] << 0;
	x |= ptr[1] << 8;
	x |= ptr[2] << 16;
	x |= ptr[3] << 24;

	*pptr = ptr;
	*r = x;
}

// Returns the current cumulative frequency (map it to a symbol yourself!)
static inline uint32_t RansDecGet(RansState* r, uint32_t scale_bits)
{
	return *r & ((1u << scale_bits) - 1);
}


// --------------------------------------------------------------------------

// That's all you need for a full encoder; below here are some utility
// functions with extra convenience or optimizations.

// Encoder symbol description
// This (admittedly odd) selection of parameters was chosen to make
// RansEncPutSymbol as cheap as possible.
typedef struct {
	uint32_t x_max;     // (Exclusive) upper bound of pre-normalization interval
	uint32_t rcp_freq;  // Fixed-point reciprocal frequency
	uint32_t bias;      // Bias
	uint16_t cmpl_freq; // Complement of frequency: (1 << scale_bits) - freq
	uint16_t rcp_shift; // Reciprocal shift
} RansEncSymbol;

// Decoder symbols are straightforward.
typedef struct {
	uint16_t start;     // Start of range.
	uint16_t freq;      // Symbol frequency.
} RansDecSymbol;

// Initializes an encoder symbol to start "start" and frequency "freq"
static inline void RansEncSymbolInit(RansEncSymbol* s, uint32_t start, uint32_t freq, uint32_t scale_bits)
{
	RansAssert(scale_bits <= 16);
	RansAssert(start <= (1u << scale_bits));
	RansAssert(freq <= (1u << scale_bits) - start);

	// Say M := 1 << scale_bits.
	//
	// The original encoder does:
	//   x_new = (x/freq)*M + start + (x%freq)
	//
	// The fast encoder does (schematically):
	//   q     = mul_hi(x, rcp_freq) >> rcp_shift   (division)
	//   r     = x - q*freq                         (remainder)
	//   x_new = q*M + bias + r                     (new x)
	// plugging in r into x_new yields:
	//   x_new = bias + x + q*(M - freq)
	//        =: bias + x + q*cmpl_freq             (*)
	//
	// and we can just precompute cmpl_freq. Now we just need to
	// set up our parameters such that the original encoder and
	// the fast encoder agree.

#ifdef USE8SHIFT
	s->x_max = ((RANS_BYTE_L >> scale_bits) << 8) * freq;
#else
	s->x_max = ((RANS_BYTE_L >> scale_bits) << 16) * freq;
#endif // USE8SHIFT

	s->cmpl_freq = (uint16_t)((1 << scale_bits) - freq);
	if (freq < 2) {
		// freq=0 symbols are never valid to encode, so it doesn't matter what
		// we set our values to.
		//
		// freq=1 is tricky, since the reciprocal of 1 is 1; unfortunately,
		// our fixed-point reciprocal approximation can only multiply by values
		// smaller than 1.
		//
		// So we use the "next best thing": rcp_freq=0xffffffff, rcp_shift=0.
		// This gives:
		//   q = mul_hi(x, rcp_freq) >> rcp_shift
		//     = mul_hi(x, (1<<32) - 1)) >> 0
		//     = floor(x - x/(2^32))
		//     = x - 1 if 1 <= x < 2^32
		// and we know that x>0 (x=0 is never in a valid normalization interval).
		//
		// So we now need to choose the other parameters such that
		//   x_new = x*M + start
		// plug it in:
		//     x*M + start                   (desired result)
		//   = bias + x + q*cmpl_freq        (*)
		//   = bias + x + (x - 1)*(M - 1)    (plug in q=x-1, cmpl_freq)
		//   = bias + 1 + (x - 1)*M
		//   = x*M + (bias + 1 - M)
		//
		// so we have start = bias + 1 - M, or equivalently
		//   bias = start + M - 1.
		s->rcp_freq = ~0u;
		s->rcp_shift = 0;
		s->bias = start + (1 << scale_bits) - 1;
		s->rcp_shift += 32; // Avoid the extra >>32 in RansEncPutSymbol
	}	
	else {
		// Alverson, "Integer Division using reciprocals"
		// shift=ceil(log2(freq))
		uint32_t shift = 0;
#ifdef FPGA
		// to avoid freq=1<<shift
		if		(freq & 0x00000080)
			shift = 7;
		else if (freq & 0x00000040)
			shift = 6;
		else if (freq & 0x00000020)
			shift = 5;
		else if (freq & 0x00000010)
			shift = 4;
		else if (freq & 0x00000008)
			shift = 3;
		else if (freq & 0x00000004)
			shift = 2;
		else if (freq & 0x00000002)
			shift = 1;
		else if (freq & 0x00000001)
			shift = 0;
		else
			shift = 0;
		if (freq > (1u << shift))
			shift++;

		s->rcp_freq = (uint32_t)(((1ull << (shift + 31)) + freq - 1) / freq);
		uint64_t a = (uint64_t)(1ull << (shift + 31)) + freq - 1;
#else
		while (freq > (1u << shift)) {
			shift++;
		}
		s->rcp_freq = (uint32_t)(((1ull << (shift + 31)) + freq - 1) / freq);
#endif // FPGA
		//s->rcp_shift = shift - 1; // original
		s->rcp_shift = shift + 31; // Avoid the extra >>32 in RansEncPutSymbol

		// With these values, 'q' is the correct quotient, so we
		// have bias=start.
		s->bias = start;
	}
}

// Initialize a decoder symbol to start "start" and frequency "freq"
static inline void RansDecSymbolInit(RansDecSymbol* s, uint32_t start, uint32_t freq)
{
	RansAssert(start <= (1 << 16));
	RansAssert(freq <= (1 << 16) - start);
	s->start = (uint16_t)start;
	s->freq = (uint16_t)freq;
}

// Encodes a given symbol. This is faster than straight RansEnc since we can do
// multiplications instead of a divide.
//
// See RansEncSymbolInit for a description of how this works.
static inline void RansEncPutSymbol(RansState* r, uint8_t** pptr, RansEncSymbol const* sym, uint32_t id)
{
	RansAssert(sym->x_max != 0); // can't encode symbol with freq=0

	// renormalize
	uint32_t x = *r;
	uint32_t x_max = sym->x_max;

	if (id == 7) {
		cnt_debug++;
	}

#ifdef USE8SHIFT
	if (x >= x_max) {
		uint8_t tmp = (x & 0xff);
		uint8_t* ptr = *pptr;
		*ptr++ = (uint8_t)(x & 0xff);
		x >>= 8;
		*pptr = ptr;

		cnt_bytes_enc++;
	}
#else
	if (x > x_max) {
		uint8_t* ptr = *pptr;
		ptr[0] = x & 0xff;
		ptr[1] = (x >> 8) & 0xff;
		ptr += 2;
		x >>= 16;
		*pptr = ptr;
	}
#endif // USE8SHIFT

	// x = C(s,x)
	// NOTE: written this way so we get a 32-bit "multiply high" when
	// available. If you're on a 64-bit platform with cheap multiplies
	// (e.g. x64), just bake the +32 into rcp_shift.
	//uint32_t q = (uint32_t)(((uint64_t)x * sym->rcp_freq) >> 32) >> sym->rcp_shift;
#ifdef FPGA
	uint16_t high16 = sym->rcp_freq >> 16;
	uint16_t low16 = (uint16_t)(sym->rcp_freq & 0xffff);
	uint64_t out1 = uint64_t(high16 * x) << 16;
	uint64_t out2 = low16 * x;
	uint64_t out = out1 + out2;;
	uint32_t q = (uint32_t)(out >> sym->rcp_shift);
#else
	uint32_t q = (uint32_t)(((uint64_t)x * sym->rcp_freq) >> sym->rcp_shift);
#endif // FPGA
	*r = x + sym->bias + q * sym->cmpl_freq;
}

// Advances in the bit stream by "popping" a single symbol with range start
// "start" and frequency "freq". All frequencies are assumed to sum to "1 << scale_bits".
// No renormalization or output happens.
static inline void RansDecAdvanceStep(RansState* r, uint32_t start, uint32_t freq, uint32_t scale_bits)
{
	uint32_t mask = (1u << scale_bits) - 1;

	// s, x = D(x)
	uint32_t x = *r;
	*r = freq * (x >> scale_bits) + (x & mask) - start;
}

// Equivalent to RansDecAdvanceStep that takes a symbol.
static inline void RansDecAdvanceSymbolStep(RansState* r, RansDecSymbol const* sym, uint32_t scale_bits)
{
	RansDecAdvanceStep(r, sym->start, sym->freq, scale_bits);
}

// Renormalize.
static inline void RansDecRenorm(RansState* r, uint8_t** pptr)
{
	// True branchless renormalization
	uint32_t x = *r;
#ifdef USE8SHIFT
	if (x < RANS_BYTE_L) {
		uint8_t* ptr = *pptr;
		ptr--;
		x = (x << 8) | *ptr;
		*pptr = ptr;
	}
#else
	int32_t s = x < RANS_BYTE_L;
	uint32_t tx = x;
	tx = (tx << 16) | *((uint16_t*)*pptr);
	*pptr -= s << 1;
	x = (-s & (tx - x)) + x;
#endif // USE8SHIFT
	*r = x;
}

#endif // RANS_BYTE_FPGA_H