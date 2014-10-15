DD=dmd
DEBUG=-g -debug -unittest
DFLAGS=$(DEBUG) -property -de
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
	sudo LD_LIBRARY_PATH=. ./$<

sgio_example: $(SGIOLIB) sgio_example.d
	$(DD) $(DFLAGS) -c sgio_example.d
	$(DD) $(DLDFLAGS) -L-l:$(SGIOLIB) sgio_example.o

.PHONY: clean
clean:
	-rm -rf $(OBJDIR)
	-rm $(SGIOLIB) sgio_example sgio_example.o
