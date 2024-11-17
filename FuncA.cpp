#include "FuncA.h"
#include <cmath>

double TrigFunction::FuncA(double x) {
    int n = 3;
    double result = 0.0;
    for (int i = 0; i < n; i++) {
        result += (pow(-1, i) * pow(x, 2 * i + 1)) / (2 * i + 1);
    }
    return result;
}
