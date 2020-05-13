#ifndef LSM_BASE_H
#define LSM_BASE_H

#include <stdlib.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

#define DRIVE_NUM 20
#define MAX_SHIFT_SIZE 5
#define OUTLIER_FACTOR 1.25
#define SHIFT 2

typedef uint64_t *(*pelemay_driver)(uint64_t vec_l);

double *pelemay_lsm(uint64_t *x, uint64_t *y, size_t n);

double *pelemay_lsm_drive(pelemay_driver driver);

#ifdef __cplusplus
}
#endif // __cplusplus
#endif // LSM_H
