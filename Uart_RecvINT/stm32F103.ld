ENTRY(Reset_Handler)

MEMORY {
	/*Adust LENGTH to RAMsize of target MCU:*/
	/*STM32F103RBT --> 20K*/
	/*RAM (RWX) : ORIGIN = 0x20000000 , LENGTH = 20K*/
	/*STM32F103RET --> 64K*/
	/*STM32F103ZET --> 64K*/
	RAM (RWX) : ORIGIN = 0x20000000 , LENGTH = 64K
	EXTSRAM (RWX) : ORIGIN = 0x68000000 , LENGTH = 0
	/*Adust LENGTH to (FLASHsize - FeePROMsize) of target MCU:*/
	/*STM32F103RBT --> 126K*/
	/*FLASH (RX) : ORIGIN = 0x08000000 , LENGTH = 126K*/
	/*STM32F103RET --> 508K*/
	/*FLASH (RX) : ORIGIN = 0x08000000 , LENGTH = 508K*/
	/*STM32F103ZET --> 508K*/
	FLASH (RX) : ORIGIN = 0x08000000 , LENGTH = 508K
	/*Adust ORIGIN to (0x08000000 + (FLASHsize-FeePROMsize)) of target MCU*/
	/*and adust LENGTH to FeePROMsize allocated:*/
	/*STM32F103RBT --> 0x08000000+126K, 2K*/
	/*EEMUL (RWX) : ORIGIN = 0x08000000+126K, LENGTH = 2K*/
	/*STM32F103RET --> 0x08000000+508K, 4K*/
	EEMUL (RWX) : ORIGIN = 0x08000000+508K, LENGTH = 4K
}
_estack	= ORIGIN(RAM)+LENGTH(RAM);	/* end of the stack */
_seemul = ORIGIN(EEMUL);	/* start of the eeprom emulation area */
_min_stack	= 0x100;	/* minimum stack space to reserve for the user app */
/* check valid alignment for the vector table */
ASSERT(ORIGIN(FLASH) == ALIGN(ORIGIN(FLASH), 0x80), "Start of memory region flash not aligned for startup vector table");
SECTIONS {
	/* vector table and program code goes into FLASH */
	.text : {
		. = ALIGN(0x80);
		_isr_vectors_offs = . - 0x08000000;
		KEEP(*(.isr_vectors))
		. = ALIGN(4);
		CREATE_OBJECT_SYMBOLS
		*(.text .text.*)
	} >FLASH
	.rodata : ALIGN (4) {
		*(.rodata .rodata.*)
		
		. = ALIGN(4);
		KEEP(*(.init))

		. = ALIGN(4);
		__preinit_array_start = .;
		KEEP (*(.preinit_array))
		__preinit_array_end = .;

		. = ALIGN(4);
		__init_array_start = .;
		KEEP (*(SORT(.init_array.*)))
		KEEP (*(.init_array))
		__init_array_end = .;

		. = ALIGN(4);
		KEEP(*(.fini))

		. = ALIGN(4);
		__fini_array_start = .;
		KEEP (*(.fini_array))
		KEEP (*(SORT(.fini_array.*)))
		__fini_array_end = .;

		*(.init .init.*)
		*(.fini .fini.*)

		PROVIDE_HIDDEN (__preinit_array_start = .);
		KEEP (*(.preinit_array))
		PROVIDE_HIDDEN (__preinit_array_end = .);
		PROVIDE_HIDDEN (__init_array_start = .);
		KEEP (*(SORT(.init_array.*)))
		KEEP (*(.init_array))
		PROVIDE_HIDDEN (__init_array_end = .);
		PROVIDE_HIDDEN (__fini_array_start = .);
		KEEP (*(.fini_array))
		KEEP (*(SORT(.fini_array.*)))
		PROVIDE_HIDDEN (__fini_array_end = .);

		. = ALIGN (8);
		*(.rom)
		*(.rom.b)
		_etext = .;
		_sidata = _etext; /* exported for the startup function */
	} >FLASH
	/*
		this data is expected by the program to be in ram
		but we have to store it in the FLASH otherwise it
		will get lost between resets, so the startup code
		has to copy it into RAM before the program starts
	*/
	.data : ALIGN (8) {
		_sdata = . ; /* exported for the startup function */
		. = ALIGN(4);
		KEEP(*(.jcr))
		*(.got.plt) *(.got)
		*(.shdata)
		*(.data .data.*)
		. = ALIGN (8);
		*(.ram)
		*(.ramfunc*)
		. = ALIGN(4);
		_edata = . ; /* exported for the startup function */
	} >RAM AT>FLASH
	/* This is the uninitialized data section */
	.bss (NOLOAD): {
		. = ALIGN(4);
		_sbss = . ; /* exported for the startup function */
		*(.shbss)
		*(.bss .bss.*)
		*(COMMON)
		. = ALIGN (8);
		*(.ram.b)
		. = ALIGN(4);
		_ebss = . ; /* exported for the startup function */
		_end = .;
		end = .; /*must equal in the C library*/
	} >RAM AT>FLASH
	/* ensure there is enough room for the user stack */
	._usrstack (NOLOAD): {
		. = ALIGN(4);
		_susrstack = . ;
		. = . + _min_stack ;
		. = ALIGN(4);
		_eusrstack = . ;
	} >RAM
}