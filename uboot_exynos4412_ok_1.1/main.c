#include "cpu.h"
#include "setup.h"


#define eFUSE_SIZE		(1 * 512)	// 512 Byte eFuse, 512 Byte reserved
#define MOVI_BLKSIZE		(1<<9) /* 512 bytes */

#define PART_SIZE_FWBL1		(8 * 1024)
#define PART_SIZE_BL1		(16 * 1024)

#define MOVI_FWBL1_BLKCNT	(PART_SIZE_FWBL1 / MOVI_BLKSIZE)
#define MOVI_BL1_BLKCNT		(PART_SIZE_BL1 / MOVI_BLKSIZE)

#define PART_SIZE_UBOOT		(328 * 1024)

#define MOVI_UBOOT_BLKCNT	(PART_SIZE_UBOOT / MOVI_BLKSIZE)	/* 328KB */

/* DRAM Base */
#define CONFIG_SYS_SDRAM_BASE		0x40000000

#define CONFIG_PHY_UBOOT_BASE		CONFIG_SYS_SDRAM_BASE

#define MOVI_UBOOT_POS		((eFUSE_SIZE / MOVI_BLKSIZE) + MOVI_FWBL1_BLKCNT + MOVI_BL1_BLKCNT)


#define ISRAM_ADDRESS	0x02020000
#define EXTERNAL_FUNC_ADDRESS	(ISRAM_ADDRESS + 0x0030)

#define SDMMC_ReadBlocks(uStartBlk, uNumOfBlks, uDstAddr)	\
	(((void(*)(u32, u32, u32*))(*((u32 *)EXTERNAL_FUNC_ADDRESS)))(uStartBlk, uNumOfBlks, uDstAddr))

#define PART_SIZE_KERNEL	(6 * 1024 * 1024)
#define MOVI_ZIMAGE_BLKCNT	(PART_SIZE_KERNEL / MOVI_BLKSIZE)	/* 6MB */
#define MOVI_KERNEL_POS		(1057)

#define CFG_PHY_ADDR_KERNEL                (0x40008000)

extern void uart_asm_putc(int c);
extern void uart_asm_putx(int x);

#define MT_START	0x40000000
#define MT_LEN		0x10000000

void uboot_mem_test(void)
{
	unsigned int *p;
	int i;

	/* show dram config */
	p = (unsigned int *) 0x10600000;
	for (i = 0; i < 0x100/4; i++, p++) {
		if (!(i & 0xf)) {
			uart_asm_putc('\r');
			uart_asm_putc('\n');
		}
		uart_asm_putx(*p);
		uart_asm_putc('.');
	}
	p = (unsigned int *) 0x10610000;
	for (i = 0; i < 0x100/4; i++, p++) {
		if (!(i & 0xf)) {
			uart_asm_putc('\r');
			uart_asm_putc('\n');
		}
		uart_asm_putx(*p);
		uart_asm_putc('.');
	}

	uart_asm_putc('\r');
	uart_asm_putc('\n');

	uart_asm_putc('L');
	uart_asm_putc('e');
	uart_asm_putc('n');
	uart_asm_putc(':');
	uart_asm_putc(' ');
	uart_asm_putx(MT_LEN);

	uart_asm_putc('\r');
	uart_asm_putc('\n');
	uart_asm_putc('W');

	/* writing */
	p = (unsigned int *) MT_START;
	for (i = 0; i < MT_LEN/4; i++, p++) {
		*p = i+0x5a000000;
		if (!(i & 0xfffff)) {
			uart_asm_putc('.');
		}
	}

	uart_asm_putc('\r');
	uart_asm_putc('\n');
	uart_asm_putc('R');

	/* read and verify */
	p = (unsigned int *) MT_START;
	for (i = 0; i < MT_LEN/4; i++, p++) {
		if (*p != (i+0x5a000000)) {
			uart_asm_putc('X');
			uart_asm_putx(i);
			uart_asm_putx(p);
			if (i > 4) {
				uart_asm_putx(*(p-4));
				uart_asm_putx(*(p-3));
				uart_asm_putx(*(p-2));
				uart_asm_putx(*(p-1));
			}
			uart_asm_putx(*p);
			uart_asm_putx(*(p+1));
			uart_asm_putx(*(p+2));
			uart_asm_putx(*(p+3));
			uart_asm_putx(*(p+4));
			break;
		}

		if (!(i & 0xfffff)) {
			uart_asm_putc('.');
		}
	}

	uart_asm_putc('\r');
	uart_asm_putc('\n');
	uart_asm_putc('>');
}
void movi_uboot_copy(void)
{
	uboot_mem_test();
	SDMMC_ReadBlocks(MOVI_UBOOT_POS, MOVI_UBOOT_BLKCNT, CONFIG_PHY_UBOOT_BASE);
	SDMMC_ReadBlocks(MOVI_KERNEL_POS, MOVI_ZIMAGE_BLKCNT, CFG_PHY_ADDR_KERNEL);
}

static struct tag *params;

void setup_start_tag(void)
{
	params = (struct tag *)0x40001000;

	params->hdr.tag = ATAG_CORE;
	params->hdr.size = tag_size (tag_core);

	params->u.core.flags = 0;
	params->u.core.pagesize = 0;
	params->u.core.rootdev = 0;

	params = tag_next (params);
}

void setup_memory_tags(void)
{
	params->hdr.tag = ATAG_MEM;
	params->hdr.size = tag_size (tag_mem32);

	params->u.mem.start = 0x40000000;
	params->u.mem.size  = 1024*1024*1024;

	params = tag_next (params);
}

int strlen(char *str)
{
	int i = 0;
	while (str[i])
	{
		i++;
	}
	return i;
}

void strcpy(char *dest, char *src)
{
	while ((*dest++ = *src++) != '\0');
}

void setup_commandline_tag(char *cmdline)
{
	int len = strlen(cmdline) + 1;

	params->hdr.tag  = ATAG_CMDLINE;
	params->hdr.size = (sizeof (struct tag_header) + len + 3) >> 2;

	strcpy (params->u.cmdline.cmdline, cmdline);

	params = tag_next (params);
}

void setup_end_tag(void)
{
	params->hdr.tag = ATAG_NONE;
	params->hdr.size = 0;
}

void puts(char *str)
{
	int i = 0;
	while (str[i])
	{
		uart_asm_putc(str[i]);
		i++;
	}
}

int main(void)
{
	void (*the_kernel)(int, int, int) = (void *)0x40008000;



	puts("Set boot params\n\r");
	setup_start_tag();
	setup_memory_tags();
	setup_commandline_tag("root=/dev/nfs nfsroot=192.168.0.111:/work/nfs_root/fs_busybox_1.20.0 ip=192.168.0.17 console=ttySAC0,115200 lcd=S702 ctp=2");
	setup_end_tag();

	puts("Boot kernel\n\r");
	the_kernel(0, 4608, 0x40001000);

	return -1;
}
