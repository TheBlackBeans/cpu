#pragma once
#ifndef IO_INTERFACE_H
#define IO_INTERFACE_H

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Returns true on success
const char *default_format(const char *iformat);

bool io_init(const char *format, const char *iformat);
void io_close();

bool io_recv(uint16_t port, uint16_t *data);
bool io_send(uint16_t port, uint16_t data);

// I/O interface to main loop
void request_stop(void);

#ifdef __cplusplus
}
#endif

#endif // IO_INTERFACE_H
