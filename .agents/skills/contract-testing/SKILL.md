---
name: contract-testing
title: Contract Testing & Integration Patterns
description: Consumer-driven contracts, Pact, E2E testing, mutation testing, and integration test orchestration
compatibility: ["agent:contract-testing"]
metadata:
  domain: testing
  maturity: production
  audience: [qa-engineer, developer, architect]
allowed-tools: [python, docker, bash, java, javascript]
---

# Contract Testing Skill

Comprehensive patterns for consumer-driven contract testing, API verification, and integration testing.

## Pact Contract Definition

```python
from pact import Consumer, Provider

pact = Consumer("Payment Service").has_pact_with(Provider("Order Service"))

(pact
 .upon_receiving("a request for order details")
 .with_request("GET", "/orders/12345")
 .will_respond_with(200, body={
     "id": "12345",
     "total_amount": 99.99,
     "status": "pending_capture",
     "items": [
         {"product_id": "abc", "quantity": 1, "price": 99.99}
     ]
 }))

pact.verify()
pact.write_to_file()
```

## Provider Contract Verification

```python
from pact_provider import Verifier

verifier = Verifier(
    provider="Order Service",
    provider_base_url="http://localhost:8080"
)

result = verifier.verify_pacts(
    pact_urls=["pacts/Payment Service-Order Service.json"],
    provider_states_setup_url="http://localhost:8080/provider-states"
)

if not result:
    raise Exception("Contract verification failed!")
```

## Provider States Setup

```python
from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route("/provider-states", methods=["POST"])
def set_provider_state():
    state = request.json.get("state")
    
    if state == "order 12345 exists":
        db.execute("INSERT INTO orders VALUES (12345, 99.99, 'pending_capture')")
        return jsonify({"ok": True}), 200
    
    elif state == "order 12345 captured":
        db.execute("UPDATE orders SET status='captured' WHERE id=12345")
        return jsonify({"ok": True}), 200
    
    return jsonify({"error": "Unknown state"}), 400
```

## E2E Test with Selenium

```python
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait

def test_complete_checkout():
    driver = webdriver.Chrome()
    try:
        # 1. Navigate to shop
        driver.get("https://shop.example.com")
        driver.find_element(By.ID, "search").send_keys("laptop")
        driver.find_element(By.ID, "search-btn").click()
        
        # 2. Add to cart
        product = WebDriverWait(driver, 10).until(
            lambda d: d.find_element(By.CLASS_NAME, "product-card")
        )
        product.find_element(By.CLASS_NAME, "add-to-cart").click()
        
        # 3. Checkout
        driver.find_element(By.ID, "checkout-btn").click()
        
        # 4. Shipping
        driver.find_element(By.NAME, "address").send_keys("123 Main St")
        driver.find_element(By.NAME, "city").send_keys("Portland")
        driver.find_element(By.NAME, "zip").send_keys("97201")
        
        # 5. Payment
        driver.switch_to.frame("payment-iframe")
        driver.find_element(By.NAME, "cardnumber").send_keys("4111111111111111")
        driver.switch_to.default_content()
        
        # 6. Submit
        driver.find_element(By.ID, "submit-order").click()
        
        # 7. Verify
        confirmation = WebDriverWait(driver, 10).until(
            lambda d: d.find_element(By.CLASS_NAME, "confirmation-message")
        )
        assert "Order confirmed" in confirmation.text
        
    finally:
        driver.quit()
```

## Mutation Testing

```python
# Example code to test
def calculate_discount(total, is_member):
    if is_member and total > 100:
        return total * 0.9
    return total

# Tests
def test_member_discount():
    assert calculate_discount(150, is_member=True) == 135

def test_non_member_no_discount():
    assert calculate_discount(150, is_member=False) == 150

# Mutation score calculation
# Mutations that should fail tests:
# 1. Change '>' to '>='
# 2. Change 'and' to 'or'
# 3. Change 0.9 to 0.8
# Target: > 85% mutation score
```

## Integration Test Orchestration

```yaml
# docker-compose.yml
version: "3.9"
services:
  order-service:
    image: order-service:test
    environment:
      PAYMENT_URL: http://payment-service:8080

  payment-service:
    image: payment-service:test
    environment:
      ORDER_URL: http://order-service:8080

  inventory-service:
    image: inventory-service:test

  test-runner:
    image: test-runner:latest
    depends_on:
      - order-service
      - payment-service
      - inventory-service
    command: pytest /tests/ -v --junit-xml=/results/report.xml
```

## Contract Test Report

```yaml
Contract Verification Report:
  Generated: 2024-05-01T22:15:00Z
  
  Summary:
    Total Contracts: 12
    Verified: 11 ✅
    Failed: 1 ⚠️

  Failures:
    - Contract: "Payment-Order Integration"
      Reason: "Missing 'transaction_id' field in response"
      Impact: "CRITICAL: Payment capture will fail"
      Priority: P1

  Mutation Test Results:
    Order Service: 92% ✅
    Payment Service: 78% ❌ (threshold: 85%)

  E2E Test Results:
    Scenarios: 24
    Passed: 23 ✅
    Failed: 1 ⚠️

  Deployment Gate: 🔴 BLOCKED
```

---

## References

- [Pact Specification](https://pact.foundation/)
- [Consumer-Driven Contract Testing](https://martinfowler.com/articles/consumerDrivenContracts.html)
- [Mutation Testing Guidelines](https://en.wikipedia.org/wiki/Mutation_testing)
