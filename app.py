"""
Simple calculator module — used as a dummy app for the backporting POC.
"""


def add(a: float, b: float) -> float:
    return a + b


def subtract(a: float, b: float) -> float:
    return a - b


def multiply(a: float, b: float) -> float:
    return a * b


def divide(a: float, b: float) -> float:
    if b == 0:
        raise ValueError("Cannot divide by zero")
    return a / b


if __name__ == "__main__":
    print("Calculator ready")
    print(f"  2 + 3 = {add(2, 3)}")
    print(f"  7 - 4 = {subtract(7, 4)}")
    print(f"  3 * 5 = {multiply(3, 5)}")
    print(f" 10 / 2 = {divide(10, 2)}")
