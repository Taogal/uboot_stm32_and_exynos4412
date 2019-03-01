
CROSS_COMPILE = arm-none-eabi-
AS		= $(CROSS_COMPILE)as
LD		= $(CROSS_COMPILE)ld
CC		= $(CROSS_COMPILE)gcc
CPP		= $(CC) -E
AR		= $(CROSS_COMPILE)ar
NM		= $(CROSS_COMPILE)nm

STRIP		= $(CROSS_COMPILE)strip
OBJCOPY		= $(CROSS_COMPILE)objcopy
OBJDUMP		= $(CROSS_COMPILE)objdump

export AS LD CC CPP AR NM
export STRIP OBJCOPY OBJDUMP

INATLL_PATH = /mnt/hgfs/share/stm32/

CFLAGS := -Wall -O2 -g  -mcpu=cortex-m3  -mthumb  -nostartfiles
CFLAGS += -D STM32F10X_HD
CFLAGS += -D USE_STDPERIPH_DRIVER
CFLAGS += -I $(shell pwd)/fwlib/inc
CFLAGS += -I $(shell pwd)/hardware/inc
CFLAGS += -I $(shell pwd)/core/

LDFILE := stm32F103.ld
LDFLAGS  := -T$(LDFILE) --specs=nano.specs --specs=nosys.specs -lnosys 

export CFLAGS LDFLAGS

TOPDIR := $(shell pwd)
export TOPDIR

TARGET := Uart_RecvINT

obj-y += startup.o
obj-y += user/
obj-y += fwlib/
obj-y += hardware/
obj-y += core/


all : 
	make -C ./ -f $(TOPDIR)/Makefile.build 
	$(CC) $(LDFLAGS) $(CFLAGS) -o $(TARGET) built-in.o
	
	$(CC) $(LDFLAGS) $(CFLAGS) -o $(TARGET).elf built-in.o
	$(OBJCOPY) -O ihex $(TARGET).elf $(TARGET).hex
	$(OBJCOPY) -O binary $(TARGET).elf $(TARGET).bin
	arm-none-eabi-readelf -a $(TARGET).elf > $(TARGET).info_elf
	arm-none-eabi-size -d -B -t $(TARGET).elf > $(TARGET).info_size
	arm-none-eabi-objdump -S $(TARGET).elf > $(TARGET).info_code
	arm-none-eabi-nm -t d -S --size-sort -s $(TARGET).elf > $(TARGET).info_symbol


clean:
	rm -f $(shell find -name "*.o")
	
	rm -f $(TARGET).* $(TARGET)

	
distclean:
	rm -f $(shell find -name "*.o")
	rm -f $(shell find -name "*.d")
	rm -f $(TARGET)
	
install:
	cp $(TARGET).bin $(INATLL_PATH)
	cp $(TARGET).hex $(INATLL_PATH)
	