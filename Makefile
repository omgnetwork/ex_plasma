logs:
	docker-compose logs -f
up:
	docker-compose up -d
up-mocks:
	docker-compose -f docker-compose.yml -f docker-compose.conformance.yml up -d ganache mock-contracts
down:
	docker-compose down
