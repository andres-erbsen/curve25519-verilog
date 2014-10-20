test: tests.out
	@cat tests.out && ! grep -q FAIL tests.out

TESTS := feadd_test.out feexp_test.out femul_test.out fesub_test.out
feexp.vvp: feexp.v femul.v

.PRECIOUS: $(TESTS:%.out=%.vvp)

tests.out: $(TESTS)
	@for file in $(TESTS); do\
		echo "$$(echo "$$file:" | sed 's/_test.out:/:/')"\
			"$$(grep -C9999999 FAIL "$$file" || echo PASS)";\
	done > tests.out

%_test.out: %_test.vvp
	echo finish | vvp $< > $@

%_test.vvp: %.v %_test.v
	iverilog -y. -o $@ $^

clean:
	rm *.vvp *.vcd *.out || true
