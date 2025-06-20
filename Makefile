setup:
	cp .env.example .env

install:
	poetry install

test:
	poetry run pytest