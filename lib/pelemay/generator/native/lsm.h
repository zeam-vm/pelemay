#ifndef LSM_H
#define LSM_H

#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

#include <erl_nif.h>

#define LSM_NUM 10
#define DRIVE_NUM 20
#define MAX_SHIFT_SIZE 5
#define MAX_SIZE (1L << 24)
#define OUTLIER_FACTOR 1.25
#define SHIFT 2

typedef ErlNifUInt64 *(*pelemay_driver)(ErlNifUInt64 vec_l);

double *pelemay_lsm(ErlNifUInt64 *x, ErlNifUInt64 *y, size_t n);

double *pelemay_lsm_drive(pelemay_driver driver);

#ifdef __cplusplus
}
#endif // __cplusplus
#endif // LSM_H
