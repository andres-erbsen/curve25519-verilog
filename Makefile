test: tests.out
	@cat tests.out && ! grep -q FAIL tests.out

TESTS := feadd_test.out feexp_test.out femul_test.out fesub_test.out curve25519_test.out dh_test.out
feexp_test.vvp: feexp.v femul.v feexp_test.v
curve25519_test.vvp: feadd.v femul.v curve25519.v curve25519_test.v
dh_test.vvp: feadd.v femul.v curve25519.v dh_test.v
	iverilog -y. -o $@ $^

.PRECIOUS: $(TESTS:%.out=%.vvp)

tests.out: $(TESTS)
	@for file in $(TESTS); do\
		echo "$$(echo "$$file:" | sed 's/_test.out:/:/')"\
			"$$(grep -C9999999 -P "(FAIL|ERROR|SORRY)" "$$file" || echo PASS)";\
	done > tests.out

%_test.out: %_test.vvp
	echo finish | vvp $< > $@
%_test.vvp: %.v %_test.v
	iverilog -y. -o $@ $^

clean:
	rm *.vvp *.vcd *.out || true
