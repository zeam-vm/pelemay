#ifndef CLOCKCYCLE_BASE_H
#define CLOCKCYCLE_BASE_H

#include <stdint.h>
#include <time.h>

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

#ifdef __clang__
static inline uint64_t now_cycle() {
	return __builtin_readcyclecounter();
}
#elif defined(__GNUC__)
#if defined(__i386__) || defined(__x86_64__) || defined(__amd64__)
#include <x86intrin.h>
static inline uint64_t now_cycle() {
	return __rdtsc();
}
#elif defined(__linux__)
static inline uint64_t now_cycle() {
	struct timespec ts = {0, 0};
	timespec_get(&ts, TIME_UTC);
	return (uint64_t)(ts.tv_sec) * 1000000000 + ts.tv_nsec;
}
#else
#error unsupported architecture
#endif
#endif

static inline uint64_t now_ns() {
	struct timespec ts = {0, 0};
	timespec_get(&ts, TIME_UTC);
	return (uint64_t)(ts.tv_sec) * 1000000000 + ts.tv_nsec;
}

#ifdef __cplusplus
}
#endif // __cplusplus

#endif // CLOCKCYCLE_BASE_H
