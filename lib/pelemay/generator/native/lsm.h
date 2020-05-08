#ifndef LSM_H
#define LSM_H

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

#include <stdlib.h>
#include <erl_nif.h>

double *pelemay_lsm(ErlNifUInt64 *x, ErlNifUInt64 *y, size_t n);

#ifdef __cplusplus
}
#endif // __cplusplus
#endif // LSM_H
