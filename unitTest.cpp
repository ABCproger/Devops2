#include <cassert>
#include <cmath>
#include "FuncA.h"

void testFuncA() {
    TrigFunction trigFunc;

    // Тест 1: x = 0, n = 1
    assert(trigFunc.FuncA(0, 1) == 0.0);

    // Тест 2: x = 1, n = 1
    assert(std::abs(trigFunc.FuncA(1, 1) - 1.0) < 1e-9);

    // Тест 3: x = 1, n = 2
    assert(std::abs(trigFunc.FuncA(1, 2) - (1.0 - 1.0/3.0)) < 1e-9);

    // Тест 4: x = M_PI/4, n = 3
    assert(std::abs(trigFunc.FuncA(M_PI/4, 3) - (M_PI/4 - pow(M_PI/4, 3)/3 + pow(M_PI/4, 5)/5)) < 1e-9);

    // Тест 5: x = M_PI/2, n = 5
    assert(std::abs(trigFunc.FuncA(M_PI/2, 5) - (M_PI/2 - pow(M_PI/2, 3)/3 + pow(M_PI/2, 5)/5 - pow(M_PI/2, 7)/7 + pow(M_PI/2, 9)/9)) < 1e-9);
}

int main() {
    testFuncA();
    return 0;
}