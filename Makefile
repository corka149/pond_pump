.PHONY: test


test:
	CIRCUITS_MIX_ENV=test mix deps.compile --force
	CIRCUITS_MIX_ENV=test mix test
