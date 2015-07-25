DD=dmd
DEBUG=-g -debug -unittest
DFLAGS=$(DEBUG) -de
DLDFLAGS=$(DEBUG) -defaultlib=libphobos2.so

SGIOLIB := libsgio.so
SRCDIR  := source/sgio
SRCS    := $(wildcard $(SRCDIR)/*.d)
OBJDIR  := objdir
OBJS    := $(addprefix $(OBJDIR)/, \
                       $(patsubst %.d,%.o, $(notdir $(SRCS)) ))

.PHONY: final
final: $(SGIOLIB)

$(SGIOLIB): $(OBJS)
	$(DD) $(DLDFLAGS) $(OBJS) -shared -of$@

$(OBJDIR)/%.o: $(SRCDIR)/%.d | $(OBJDIR)
	$(DD) $(DFLAGS) -fPIC -c -Isource $< -of$@

$(OBJDIR):
	mkdir $(OBJDIR)

# target to build .so then run program
.PHONY: run
run: sgio_example
	sudo LD_LIBRARY_PATH=. ./$< /dev/sda

sgio_example: $(SGIOLIB) sgio_example.d | $(OBJDIR)
	$(DD) $(DFLAGS) -c sgio_example.d -Isource -of$(OBJDIR)/sgio_example.o
	$(DD) $(DLDFLAGS) -L-l:$(SGIOLIB) $(OBJDIR)/sgio_example.o

.PHONY: test
test:
	echo "int main(string args[]) {return 0;}" > test.d
	$(DD) -unittest test.d $(SRCS)
	./test
	rm -f ./test.d ./test.o ./test

.PHONY: clean
clean:
	-rm -rf $(OBJDIR)
	-rm -f $(SGIOLIB) sgio_example sgio_example.o
