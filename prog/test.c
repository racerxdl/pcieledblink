/*
	Use with 
		modprobe uio_pci_generic

	And then:
		echo "1172 00a7" > /sys/bus/pci/drivers/uio_pci_generic/new_id

	Be sure to change the sysfs path below
*/
#include <stdio.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdint.h>
#include <unistd.h>

#define MMSIZE (32)
#define ENABLE ((uint64_t)1 << 63)

int main() {
	int f = open("/sys/bus/pci/devices/0000:03:00.0/resource0", O_RDWR);
	if (f == -1 || f == 0) {
		printf("Error opening uio0\n");
		return 1;
	}

	uint64_t *ptr = (uint64_t *)mmap(0, MMSIZE, PROT_READ | PROT_WRITE, MAP_SHARED, f, 0);
	if (ptr == MAP_FAILED || ptr == 0) {
		printf("Error mapping UIO\n");
		return 1;
	}
	printf("Zeroing\n");
	ptr[0] = 0x0;
	sleep(2);
	printf("Setting up\n");
	for (int i = 0; i < 256; i++) {
		printf("%d\n", i);
		ptr[0] = ENABLE | (uint64_t)i;
		usleep(50000);
	}

	munmap(ptr, MMSIZE);
	close(f);
	return 0;
}
