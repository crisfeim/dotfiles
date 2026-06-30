test:
	@for f in tests/*.tcl; do \
		echo "== $$f =="; \
		tclsh $$f || exit 1; \
	done
