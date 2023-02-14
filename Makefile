TARGET:= woody_woodpacker

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

.PHONY: re
re: fclean all

%.o: %.S
	$(AS) $(ASFLAGS) $< -o $@
