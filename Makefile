TARGET:= woody_woodpacker
WOODY:= woody

CC:= clang
AS:= nasm
ASFLAGS:= -felf64

SRCS:= virus.S \

OBJS= $(SRCS:.S=.o)

.PHONY: all
all: $(OBJS)
	$(CC) $< -o $(TARGET)

.PHONY: clean
clean:
	@/bin/rm -rf $(OBJS)

.PHONY: fclean
fclean: clean
	@/bin/rm -rf $(TARGET)
	@/bin/rm -rf $(WOODY)

.PHONY: re
re: fclean all

%.o: %.S
	$(AS) $(ASFLAGS) $< -o $@
