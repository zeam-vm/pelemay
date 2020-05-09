#ifndef CLOCKCYCLE_H
#define CLOCKCYCLE_H

#include <erl_nif.h>

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

#ifdef __clang__
static inline ErlNifUInt64 now() {
	return __builtin_readcyclecounter();
}
#elif defined(__GNUC__)
#if defined(__i386__) || defined(__x86_64__) || defined(__amd64__)
#include <x86intrin.h>
static inline ErlNifUInt64 now() {
	return __rdtsc();
}
#elif defined(__linux__)
#include <time.h>
static inline ErlNifUInt64 now() {
	struct timespec ts = {0, 0};
	timespec_get(&ts, TIME_UTC);
	return (ErlNifUInt64)(ts.tv_sec) * 1000000000 + ts.tv_nsec;
}
#else
#error unsupported architecture
#endif
#endif

#ifdef __cplusplus
}
#endif // __cplusplus

#endif // CLOCKCYCLE_H
