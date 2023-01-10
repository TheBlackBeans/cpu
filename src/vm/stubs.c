#include "io_interface.h"

const char *default_format(const char *iformat) {
	if (iformat) return iformat;
	else return "%x"
	            "r0  = %r0\nr1  = %r1\nr2  = %r2\nr3  = %r3\nr4  = %r4\nr5  = %r5\nr6  = %r6\nr7  = %r7\n"
	            "r8  = %r8\nr9  = %r9\nr10 = %r10\nr11 = %r11\nr12 = %r12\nr13 = %r13\nr14 = %r14\nr15 = %r15\n"
	            "ip  = %ip\n%ram";
}

bool io_init(const char *format, const char *iformat) {
	(void)format, (void)iformat;
	return true;
}
void io_close() {}

bool io_recv(uint16_t port, uint16_t *data) {
	(void)port, (void)data;
	return false;
}
bool io_send(uint16_t port, uint16_t data) {
	(void)port, (void)data;
	return false;
}
