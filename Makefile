DD=dmd
DEBUG=-g -debug -unittest
DFLAGS=$(DEBUG) -de
DLDFLAGS=$(DEBUG) -defaultlib=libphobos2.so

SGIOLIB := libsgio.so
SRCDIR  := sgio
SRCS    := $(wildcard $(SRCDIR)/*.d)
OBJDIR  := objdir
OBJS    := $(addprefix $(OBJDIR)/, \
                       $(patsubst %.d,%.o, $(notdir $(SRCS)) ))

.PHONY: final
final: $(SGIOLIB)

$(SGIOLIB): $(OBJS)
	$(DD) $(DLDFLAGS) $(OBJS) -shared -of$@

$(OBJDIR)/%.o: $(SRCDIR)/%.d | $(OBJDIR)
	$(DD) $(DFLAGS) -fPIC -c $< -of$@

$(OBJDIR):
	mkdir $(OBJDIR)

# target to build .so then run program
.PHONY: run
run: sgio_example
	sudo LD_LIBRARY_PATH=. ./$< /dev/sda /dev/sdb

sgio_example: $(SGIOLIB) sgio_example.d | $(OBJDIR)
	$(DD) $(DFLAGS) -c sgio_example.d -of$(OBJDIR)/sgio_example.o
	$(DD) $(DLDFLAGS) -L-l:$(SGIOLIB) $(OBJDIR)/sgio_example.o

.PHONY: clean
clean:
	-rm -rf $(OBJDIR)
	-rm -f $(SGIOLIB) sgio_example sgio_example.o
