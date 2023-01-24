#include "io_interface.h"

#include <errno.h>
#include <error.h>
#include <fcntl.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <termios.h>
#include <unistd.h>

#define STDIN_FILEDESCNO 0 // This should be findable in some include under a different name

const char *default_format(const char *iformat) {
	if (iformat) return iformat;
	else return /* "%dTime: %r4/%r5/%r6  %r3:%r2:%r1\n%x"
	            "r0  = %r0\nr1  = %r1\nr2  = %r2\nr3  = %r3\nr4  = %r4\nr5  = %r5\nr6  = %r6\nr7  = %r7\n"
	            "r8  = %r8\nr9  = %r9\nr10 = %r10\nr11 = %r11\nr12 = %r12\nr13 = %r13\nr14 = %r14\nr15 = %r15\n"
	            "ip  = %ip\n%ram" */"";
}

struct termios init_tios;
pthread_t pt;
pthread_mutex_t iomut;
pthread_cond_t cond;
bool done;
bool port_received[6];
uint16_t received_data[6];
bool button_selected[3];

void print_val(int size, bool display, uint16_t data) {
	if (display) {
		printf("%0*d", size, data);
	} else {
		printf("%*s", size, "");
	}
}
void update_output() {
	pthread_mutex_lock(&iomut);
	printf("\e[G%c  %c  %c   ", button_selected[0] ? '#' : ' ', button_selected[1] ? '#' : ' ', button_selected[2] ? '#' : ' ');
	print_val(2, port_received[3], received_data[3]); printf("/");
	print_val(2, port_received[4], received_data[4]); printf("/");
	print_val(4, port_received[5], received_data[5]); printf("  ");
	print_val(2, port_received[2], received_data[2]); printf(":");
	print_val(2, port_received[1], received_data[1]); printf(":");
	print_val(2, port_received[0], received_data[0]);
	pthread_mutex_unlock(&iomut);
	fflush(stdout);
}

void restore_tcattr(void) {
	tcsetattr(STDIN_FILEDESCNO, TCSANOW, &init_tios);
}

void *input_thread(void *unused) {
	(void)unused;
	
	fcntl(STDIN_FILEDESCNO, F_SETFL, O_NONBLOCK);
	if (isatty(STDIN_FILEDESCNO)) {
		struct termios tios;
		if (tcgetattr(STDIN_FILEDESCNO, &tios)) {
			printf("Failed to get tc attributes\n%d: %s\n", errno, strerror(errno));
			pthread_cond_signal(&cond);
			request_stop();
			return NULL;
		}
		init_tios = tios;
		// Modified raw mode
		tios.c_iflag &= ~(IGNBRK | BRKINT | PARMRK | ISTRIP | IGNCR | IXON);
		tios.c_oflag |= OPOST; // We want post-processing
		tios.c_lflag &= ~(ECHO | ECHONL | ICANON | IEXTEN);
		tios.c_cflag &= ~(CSIZE | PARENB);
		tios.c_cflag |= CS8;
		tcsetattr(STDIN_FILEDESCNO, TCSANOW, &tios);
		atexit(&restore_tcattr);
	}
	
	// Wait for the other thread to wait on the conditional, then awaken it
	pthread_mutex_lock(&iomut);
	pthread_mutex_unlock(&iomut);
	pthread_cond_signal(&cond);
	
	//
	printf("a  z  e   Press q to quit\n");
	
	char c;
	update_output();
	pthread_mutex_lock(&iomut);
	struct timespec rq;
	rq.tv_sec = 0;
	rq.tv_nsec = 10000;
	while (!done) {
		pthread_mutex_unlock(&iomut);
		if (read(STDIN_FILEDESCNO, &c, 1) > 0) {
			// Read a character
			if (c == 'a') {
				pthread_mutex_lock(&iomut);
				button_selected[0] = !button_selected[0];
				pthread_mutex_unlock(&iomut);
				update_output();
			} else if (c == 'z') {
				pthread_mutex_lock(&iomut);
				button_selected[1] = !button_selected[1];
				pthread_mutex_unlock(&iomut);
				update_output();
			} else if (c == 'e') {
				pthread_mutex_lock(&iomut);
				button_selected[2] = !button_selected[2];
				pthread_mutex_unlock(&iomut);
				update_output();
			} else if (c == 'q') {
				request_stop();
			} else {
				// TODO?
			}
			c = 0;
		}
		nanosleep(&rq, NULL);
		pthread_mutex_lock(&iomut);
	}
	pthread_mutex_unlock(&iomut);
	
	return NULL;
}

bool io_init(const char *format, const char *iformat) {
	if (iformat && *iformat) { return false; }
	(void)format;
	
	pthread_mutex_init(&iomut, NULL);
	pthread_cond_init(&cond, NULL);
	
	// Reset I/O data
	done = false;
	memset(received_data, 0, sizeof(received_data));
	memset(button_selected, 0, sizeof(button_selected));
	
	pthread_mutex_lock(&iomut);
	pthread_create(&pt, NULL, &input_thread, NULL);
	pthread_cond_wait(&cond, &iomut);
	pthread_mutex_unlock(&iomut);
	
	pthread_cond_destroy(&cond);
	return true;
}
void io_close() {
	pthread_mutex_lock(&iomut);
	done = true;
	pthread_mutex_unlock(&iomut);
	pthread_join(pt, NULL);
	pthread_mutex_destroy(&iomut);
	printf("\n");
}

bool io_recv(uint16_t port, uint16_t *data) {
	if (port >= sizeof(button_selected) / sizeof(*button_selected)) return false;
	pthread_mutex_lock(&iomut);
	*data = button_selected[port];
	pthread_mutex_unlock(&iomut);
	return true;
}
bool io_send(uint16_t port, uint16_t data) {
	if (port >= sizeof(received_data) / sizeof(*received_data)) return false;
	pthread_mutex_lock(&iomut);
	received_data[port] = data;
	port_received[port] = true;
	pthread_mutex_unlock(&iomut);
	
	update_output();
	return true;
}
