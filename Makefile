.PHONY: all test clean compile deps

REBAR=./rebar

all: deps compile
deps:
	@$(REBAR) get-deps
compile:
	@$(REBAR) compile
test_st:
	@$(REBAR) compile skip_deps=true
	@$(REBAR) eunit skip_deps=true suite=site_stater_tests

test_db:
	@$(REBAR) compile skip_deps=true
	@$(REBAR) eunit skip_deps=true suite=st_db_tests
test_web:
	@$(REBAR) compile skip_deps=true
	@$(REBAR) eunit skip_deps=true suite=st_web_control_tests
clean:
	@$(REBAR) clean
dev_start:  all
	erl -pa ./ebin -pa ./deps/*/ebin -sname site_stater -boot start_sasl -eval "application:start(site_stater)."
start:  all
	erl -pa ./ebin -pa ./deps/*/ebin -sname site_stater -boot start_sasl -eval "application:start(site_stater)." -detached